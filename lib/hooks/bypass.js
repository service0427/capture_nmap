/* 
   Advanced Bypass & Profile Spoofing v15.0 (Full Identity + NELO)
   - SSAID, IDFV(AppSetId), ADID(AdvertisingId) 후킹
   - NELO DeviceID (AppInfoUtils.f) + NeloInstallID (StorageAdapter.A) 직접 후킹
   - NTracker 헤더 Map 직접 치환 (da-dd/da-dv)
   - --random 모드 시 모든 식별자 변조 + 체크리스트 모니터링
*/

console.log("[*] High-Fidelity Bypass v15.0 Active");

Java.perform(function() {
    var SystemProperties = Java.use("android.os.SystemProperties");
    var Build = Java.use("android.os.Build");
    
    // Props 읽기 → "none" 또는 빈 문자열은 null로 정규화
    var normalize = function(v) { return (v && v !== "none" && v !== "") ? v : null; };
    let m = SystemProperties.get("debug.nmap.model");
    let b = SystemProperties.get("debug.nmap.brand");
    let s = normalize(SystemProperties.get("debug.nmap.ssaid"));
    let idfv = normalize(SystemProperties.get("debug.nmap.idfv"));
    let adid = normalize(SystemProperties.get("debug.nmap.adid"));
    let osver = normalize(SystemProperties.get("debug.nmap.osver"));
    let build_id = normalize(SystemProperties.get("debug.nmap.build_id"));
    let display_id = normalize(SystemProperties.get("debug.nmap.display_id"));
    let scr_width = normalize(SystemProperties.get("debug.nmap.width"));
    let scr_height = normalize(SystemProperties.get("debug.nmap.height"));
    let scr_density = normalize(SystemProperties.get("debug.nmap.density"));
    
    // 후킹 결과 추적
    var results = {};

    // ========== 1. Device Spoofing ==========
    var origModel = Build.MODEL.value;
    var origBrand = Build.BRAND.value;
    var origOsVer = Java.use("android.os.Build$VERSION").RELEASE.value;
    var origBuildId = Build.ID.value;
    var origDisplay = Build.DISPLAY.value;
    if (m && m !== "none") {
        try {
            Build.MODEL.value = m;
            Build.BRAND.value = b;
            Build.MANUFACTURER.value = b;
            Build.PRODUCT.value = m;
            Build.DEVICE.value = m;
            // OS 버전 & 빌드 정보 변조
            // ※ SDK_INT는 변조하지 않음 — 실제 OS 동작에 영향(크래시 유발)
            if (osver) {
                var BuildVer = Java.use("android.os.Build$VERSION");
                BuildVer.RELEASE.value = osver;
            }
            if (build_id) Build.ID.value = build_id;
            if (display_id) Build.DISPLAY.value = display_id;
            // 해상도: Display/DisplayMetrics 후킹 제거 (UI 렌더링 매 프레임 호출로 성능 저하)
            // → GFP URL의 dh=/dw= 파라미터 치환으로 커버 (5-4 섹션)
            if (scr_width && scr_height && scr_density) {
                results.DISPLAY = { to: scr_width + "x" + scr_height + "@" + scr_density, ok: true };
            } else {
                results.DISPLAY = { ok: null };
            }

            results.MODEL = { from: origModel, to: m, ok: true };
            results.BRAND = { from: origBrand, to: b, ok: true };
        } catch(e) {
            results.MODEL = { from: "?", to: m, ok: false, err: e.toString() };
        }

        // UA 공통 치환 함수 (모델, OS 버전, 빌드 ID 모두 교체)
        var patchUA = function(ua) {
            if (!ua) return ua;
            ua = ua.replace(new RegExp(origModel, "g"), m);
            if (osver) ua = ua.replace(new RegExp("Android " + origOsVer, "g"), "Android " + osver);
            if (build_id) ua = ua.replace(new RegExp(origBuildId.replace(/\./g, '\\.'), "g"), build_id);
            if (display_id) ua = ua.replace(new RegExp(origDisplay.replace(/\./g, '\\.'), "g"), display_id);
            return ua;
        };

        // 1-2. Dalvik User-Agent 변조 (HttpURLConnection, NELO _store 등)
        try {
            var System = Java.use("java.lang.System");
            var origAgent = System.getProperty("http.agent");
            var newAgent = patchUA(origAgent);
            if (newAgent !== origAgent) {
                System.setProperty("http.agent", newAgent);
                console.log("[UA] http.agent: " + origModel + " → " + m + (osver ? ", Android " + origOsVer + " → " + osver : ""));
            }
            // URLConnection.setRequestProperty 후킹 → User-Agent 헤더 치환
            var URLConnection = Java.use("java.net.URLConnection");
            var origSetRP = URLConnection.setRequestProperty.overload('java.lang.String', 'java.lang.String');
            origSetRP.implementation = function(key, value) {
                if (key === "User-Agent") value = patchUA(value);
                return origSetRP.call(this, key, value);
            };
            results.DALVIK_UA = { ok: true };
        } catch(e) {
            results.DALVIK_UA = { ok: false, err: e.toString() };
        }

        // 1-3. WebView User-Agent 변조 (loadUrl 시점 + getDefaultUserAgent)
        try {
            var WebView = Java.use("android.webkit.WebView");
            var uaPatched = {};

            // WebView UA 패치 함수
            var patchWebViewUA = function(wv) {
                var wvId = wv.hashCode();
                if (!uaPatched[wvId]) {
                    try {
                        var settings = wv.getSettings();
                        var curUA = settings.getUserAgentString();
                        var newUA = patchUA(curUA);
                        if (newUA !== curUA) {
                            settings.setUserAgentString(newUA);
                            console.log("[WebView] UA 강제 세팅: " + origModel + " → " + m);
                        }
                    } catch(e2) {}
                    uaPatched[wvId] = true;
                }
            };

            // loadUrl(String) 후킹
            var origLoadUrl = WebView.loadUrl.overload('java.lang.String');
            origLoadUrl.implementation = function(url) {
                patchWebViewUA(this);
                return origLoadUrl.call(this, url);
            };
            // loadUrl(String, Map) 후킹
            try {
                var origLoadUrl2 = WebView.loadUrl.overload('java.lang.String', 'java.util.Map');
                origLoadUrl2.implementation = function(url, headers) {
                    patchWebViewUA(this);
                    return origLoadUrl2.call(this, url, headers);
                };
            } catch(e3) {}
            // loadData / loadDataWithBaseURL 후킹
            try {
                var origLoadData = WebView.loadDataWithBaseURL.overload('java.lang.String', 'java.lang.String', 'java.lang.String', 'java.lang.String', 'java.lang.String');
                origLoadData.implementation = function(baseUrl, data, mimeType, encoding, historyUrl) {
                    patchWebViewUA(this);
                    return origLoadData.call(this, baseUrl, data, mimeType, encoding, historyUrl);
                };
            } catch(e3) {}

            // WebSettings.getDefaultUserAgent() → GFP 등에서 사용하는 기본 UA 변조
            try {
                var WebSettings = Java.use("android.webkit.WebSettings");
                WebSettings.getDefaultUserAgent.overload('android.content.Context').implementation = function(ctx) {
                    var ua = this.getDefaultUserAgent(ctx);
                    return patchUA(ua);
                };
            } catch(e4) {}

            results.WEBVIEW_UA = { ok: true };
        } catch(e) {
            results.WEBVIEW_UA = { ok: false, err: e.toString() };
        }
    } else {
        results.MODEL = { from: origModel, to: null, ok: null };
        results.BRAND = { from: origBrand, to: null, ok: null };
        results.DALVIK_UA = { ok: null };
        results.WEBVIEW_UA = { ok: null };
    }

    // ========== 2. OkHttp3 Header Sanitizer ==========
    try {
        var Builder = Java.use("okhttp3.Request$Builder");
        var sanitizeHeader = function(name, value) {
            var lname = name.toLowerCase();
            if (lname === "user-agent" && m && m !== "none") {
                return patchUA(value);
            }
            if (lname === "da-dd" && adid) return adid;
            if (lname === "da-dv" && idfv) return idfv;
            return value;
        };
        // R8 난독화로 메서드명이 변경될 수 있음 - 안전하게 체크
        if (Builder.header && Builder.addHeader) {
            Builder.header.implementation = function(n, v) { return this.header(n, sanitizeHeader(n, v)); };
            Builder.addHeader.implementation = function(n, v) { return this.addHeader(n, sanitizeHeader(n, v)); };
            results.OKHTTP = { ok: true };
        } else {
            results.OKHTTP = { ok: null, note: "R8 난독화 - NTracker Map으로 대체" };
        }
    } catch(e) {
        // OkHttp 클래스 자체가 없거나 R8 난독화 - NTracker 헤더 Map 후킹으로 대체
        results.OKHTTP = { ok: null, note: "NTracker Map으로 대체" };
    }

    // ========== 2-2. NTracker 헤더 Map 직접 치환 ==========
    try {
        var NTrackerRequest = Java.use("com.navercorp.ntracker.ntrackersdk.network.NTrackerNetworkRequest");
        NTrackerRequest.d.implementation = function() {
            var headerMap = this.d();
            if (adid && headerMap.containsKey("da-dd")) {
                headerMap.put("da-dd", adid);
            }
            if (idfv && headerMap.containsKey("da-dv")) {
                headerMap.put("da-dv", idfv);
            }
            return headerMap;
        };
        results.NTRACKER_HDR = { ok: true };
    } catch(e) {
        results.NTRACKER_HDR = { ok: false, err: e.toString() };
    }

    // ========== 3. SSAID Spoofing ==========
    if (s) {
        try {
            Java.use("android.provider.Settings$Secure").getString.overload('android.content.ContentResolver', 'java.lang.String').implementation = function(c, n) {
                if (n === "android_id") return s;
                return this.getString(c, n);
            };
            results.SSAID = { to: s, ok: true };
        } catch(e) {
            results.SSAID = { to: s, ok: false, err: e.toString() };
        }
    } else {
        results.SSAID = { to: null, ok: null };
    }

    // ========== 3-2. NELO NeloInstallID 변조 ==========
    // StorageAdapter.A()가 ContentProvider에서 NeloInstallID를 읽는 유일한 소스
    if (s) {
        try {
            var neloInstallIdOverride = Java.use("java.util.UUID").randomUUID().toString();
            var StorageAdapter = Java.use("com.naver.nelo.sdk.android.buffer.StorageAdapter");
            StorageAdapter.A.implementation = function() {
                console.log("[NELO-IID] NeloInstallID 변조: " + neloInstallIdOverride);
                return neloInstallIdOverride;
            };
            results.NELO_IID = { ok: true, to: neloInstallIdOverride };
        } catch(e) {
            results.NELO_IID = { ok: false, err: e.toString() };
        }
    } else {
        results.NELO_IID = { ok: null };
    }

    // ========== 3-3. NELO DeviceID 변조 ==========
    // AppInfoUtils.f(context)가 SSAID → MD5 해시로 DeviceID를 생성
    if (s) {
        try {
            var AppInfoUtils = Java.use("com.naver.nelo.sdk.android.utils.AppInfoUtils");
            AppInfoUtils.f.overload('android.content.Context').implementation = function(ctx) {
                // 변조된 SSAID로 MD5 계산
                var md = Java.use("java.security.MessageDigest").getInstance("MD5");
                var bytes = Java.use("java.lang.String").$new(s).getBytes();
                md.update(bytes);
                var digest = md.digest();
                var sb = Java.use("java.lang.StringBuilder").$new();
                for (var i = 0; i < digest.length; i++) {
                    var hex = Java.use("java.lang.Integer").toHexString(digest[i] & 0xFF);
                    if (hex.length === 1) sb.append("0");
                    sb.append(hex);
                }
                var newDeviceId = sb.toString();
                console.log("[NELO-DID] DeviceID 변조: " + newDeviceId);
                return newDeviceId;
            };
            results.NELO_DID = { ok: true };
        } catch(e) {
            results.NELO_DID = { ok: false, err: e.toString() };
        }
    } else {
        results.NELO_DID = { ok: null };
    }

    // ========== 4. IDFV (App Set ID) Spoofing ==========
    if (idfv) {
        try {
            var AppSetIdInfo = Java.use("com.google.android.gms.appset.AppSetIdInfo");
            AppSetIdInfo.a.implementation = function() {
                return idfv;
            };
            results.IDFV_API = { to: idfv, ok: true };
        } catch(e) {
            results.IDFV_API = { to: idfv, ok: false, err: e.toString() };
        }
    } else {
        results.IDFV_API = { to: null, ok: null };
    }

    // ========== 5. ADID (Advertising ID) Spoofing ==========
    if (adid) {
        // 5-1. AdvertisingIdClient$Info.a() + getId() + 생성자
        try {
            var AdvIdInfo = Java.use("com.google.android.gms.ads.identifier.AdvertisingIdClient$Info");
            // getter 후킹 (난독화된 이름 a, 비난독화 이름 getId)
            AdvIdInfo.a.implementation = function() { return adid; };
            try { AdvIdInfo.getId.implementation = function() { return adid; }; } catch(e9) {}
            // 생성자 후킹 → Info 객체 생성 시점에 ADID 강제 교체
            try {
                AdvIdInfo.$init.overload('java.lang.String', 'boolean').implementation = function(id, limitTracking) {
                    this.$init(adid, limitTracking);
                };
            } catch(e9) {}
            results.ADID_INFO = { to: adid, ok: true };
        } catch(e) {
            results.ADID_INFO = { to: adid, ok: false, err: e.toString() };
        }

        // 5-2. AdvertisingIdClient.a(Context)
        try {
            var AdvIdClient = Java.use("com.google.android.gms.ads.identifier.AdvertisingIdClient");
            AdvIdClient.a.overload('android.content.Context').implementation = function(ctx) {
                try {
                    var infoClass = Java.use("com.google.android.gms.ads.identifier.AdvertisingIdClient$Info");
                    return infoClass.$new(adid, false);
                } catch(e2) {
                    return this.a(ctx);
                }
            };
            results.ADID_CLIENT = { ok: true };
        } catch(e) {
            results.ADID_CLIENT = { ok: false, err: e.toString() };
        }

        // 5-3. JSONObject.put('adid') + toString() 최종 안전망
        try {
            var JSONObject = Java.use("org.json.JSONObject");
            var origPut = JSONObject.put.overload('java.lang.String', 'java.lang.Object');
            origPut.implementation = function(key, value) {
                if (key === "adid" && adid && value !== null && value.toString() !== adid) {
                    return origPut.call(this, key, adid);
                }
                return origPut.call(this, key, value);
            };
            // toString() 시점에 캐싱된 adid도 강제 교체 (성능 최적화)
            var origToString = JSONObject.toString.overload();
            origToString.implementation = function() {
                try {
                    var len = this.length();
                    // 빠른 체크: 최상위 adid
                    if (this.has("adid") && this.getString("adid") !== adid) {
                        this.put("adid", adid);
                    }
                    // 중첩 체크는 키가 2개 이상일 때만 (usr 등 하위 객체 포함 가능)
                    if (len >= 2 && len <= 20) {
                        var keys = this.keys();
                        while (keys.hasNext()) {
                            var k = keys.next();
                            try {
                                var child = this.optJSONObject(k);
                                if (child !== null && child.has("adid") && child.getString("adid") !== adid) {
                                    child.put("adid", adid);
                                }
                            } catch(e6) {}
                        }
                    }
                } catch(e5) {}
                return origToString.call(this);
            };
            results.ADID_JSON = { ok: true };
        } catch(e) {
            results.ADID_JSON = { ok: false, err: e.toString() };
        }
    } else {
        results.ADID_INFO = { to: null, ok: null };
        results.ADID_CLIENT = { ok: null };
        results.ADID_JSON = { ok: null };
    }

    // ========== 5-4. GFP URL ai=/dh=/dw= 파라미터 강제 치환 ==========
    if (adid || (scr_width && scr_height)) {
        try {
            var URL = Java.use("java.net.URL");
            var origURL = URL.$init.overload('java.lang.String');
            origURL.implementation = function(spec) {
                if (spec && spec.indexOf("gfp/v1") !== -1) {
                    // ai= ADID 치환
                    if (adid && spec.indexOf("ai=") !== -1) {
                        spec = spec.replace(/ai=([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})/g, "ai=" + adid);
                    }
                    // dh=/dw= 해상도 치환
                    if (scr_height && spec.indexOf("dh=") !== -1) {
                        spec = spec.replace(/dh=\d+/, "dh=" + scr_height);
                    }
                    if (scr_width && spec.indexOf("dw=") !== -1) {
                        spec = spec.replace(/dw=\d+/, "dw=" + scr_width);
                    }
                }
                return origURL.call(this, spec);
            };
            results.ADID_URL = { ok: true };
        } catch(e) {
            results.ADID_URL = { ok: false, err: e.toString() };
        }
    }

    // ========== 체크리스트 출력 ==========
    var icon = function(r) {
        if (r === null) return "⬜";  // 미설정 (--random 아님)
        return r ? "✅" : "❌";
    };

    console.log("\n╔══════════════════════════════════════════════════╗");
    console.log("║        IDENTITY SPOOFING CHECKLIST               ║");
    console.log("╠══════════════════════════════════════════════════╣");
    
    // Device
    console.log("║ " + icon(results.MODEL.ok) + " MODEL    : " + results.MODEL.from + (results.MODEL.to ? " → " + results.MODEL.to : " (원본)"));
    console.log("║ " + icon(results.BRAND.ok) + " BRAND    : " + results.BRAND.from + (results.BRAND.to ? " → " + results.BRAND.to : " (원본)"));
    console.log("║ " + icon(results.DISPLAY ? results.DISPLAY.ok : null) + " DISPLAY  : " + (results.DISPLAY && results.DISPLAY.to ? results.DISPLAY.to : "(원본)"));
    
    // Identifiers
    console.log("║ " + icon(results.SSAID.ok) + " SSAID    : " + (results.SSAID.to || "(원본)"));
    console.log("║ " + icon(results.IDFV_API ? results.IDFV_API.ok : null) + " IDFV(API): " + (idfv || "(원본)"));
    console.log("║ " + icon(results.ADID_INFO ? results.ADID_INFO.ok : null) + " ADID(API): " + (adid || "(원본)"));
    console.log("║ " + icon(results.ADID_CLIENT ? results.ADID_CLIENT.ok : null) + " ADID(GMS): " + (adid ? "후킹" : "(원본)"));
    console.log("║ " + icon(results.ADID_JSON ? results.ADID_JSON.ok : null) + " ADID(JSON): " + (adid ? "후킹" : "(원본)"));
    
    // NELO
    console.log("║ " + icon(results.NELO_DID ? results.NELO_DID.ok : null) + " NELO(DID): DeviceID (SSAID→MD5)");
    console.log("║ " + icon(results.NELO_IID ? results.NELO_IID.ok : null) + " NELO(IID): NeloInstallID (StorageAdapter)");
    
    // User-Agent
    console.log("║ " + icon(results.DALVIK_UA ? results.DALVIK_UA.ok : null) + " DalvikUA : HttpURLConnection UA");
    console.log("║ " + icon(results.WEBVIEW_UA ? results.WEBVIEW_UA.ok : null) + " WebVwUA  : WebView UA");
    
    // Headers
    console.log("║ " + icon(results.OKHTTP.ok) + " OkHttp   : UA/da-dd/da-dv 헤더 치환");
    console.log("║ " + icon(results.NTRACKER_HDR.ok) + " NTracker : da-dd/da-dv 헤더 Map 치환");
    
    // 실패 항목 상세
    var failures = [];
    for (var key in results) {
        if (results[key].ok === false) {
            failures.push("  ⛔ " + key + ": " + (results[key].err || "unknown"));
        }
    }
    if (failures.length > 0) {
        console.log("╠══════════════════════════════════════════════════╣");
        console.log("║ ❌ FAILURES:");
        failures.forEach(function(f) { console.log("║ " + f); });
    }
    
    console.log("╚══════════════════════════════════════════════════╝\n");
});

// Native Hook
function hook_native_safe() {
    try {
        var addr = Module.findExportByName(null, "__system_property_get");
        if (addr) {
            Interceptor.attach(addr, {
                onEnter: function(args) { this.key = args[0].readCString(); },
                onLeave: function(retval) {
                    if (this.key.indexOf("model") !== -1 && !this.key.startsWith("debug.")) {
                        // 필요한 경우에만 추가 변조
                    }
                }
            });
        }
    } catch(e) {
        console.log("[-] Native hook skipped for stability.");
    }
}

setTimeout(hook_native_safe, 2000);
