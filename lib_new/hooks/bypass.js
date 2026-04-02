/* 
   Identity Laundering Bypass (V3 Refactored)
   - Goal: Internal Memory/Cache Spoofing for Tracking IDs (ADID, NI, IDFV, NLogID).
   - Executed: ONLY in NORMAL mode (Excluded in --no-filter mode).
*/

console.log("[*] Identity Laundering System Loaded");

(function() {
    function uuidv4() { return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) { var r = Math.random() * 16 | 0, v = c == 'x' ? r : (r & 0x3 | 0x8); return v.toString(16); }); }
    function hex(len) { var res = ""; var c = "0123456789abcdef"; for (var i = 0; i < len; i++) res += c.charAt(Math.floor(Math.random() * c.length)); return res; }
    function mixed(len) { var res = ""; var c = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"; for (var i = 0; i < len; i++) res += c.charAt(Math.floor(Math.random() * c.length)); return res; }

    var MASTER_ID = {
        ADID: uuidv4(),
        IDFV: uuidv4(),
        NI: hex(32),
        TOKEN: mixed(16),
        SERIAL: "SN" + Math.floor(Math.random() * 100000000)
    };

    console.log("[*] Identity Synced for Session:");
    console.log("    > New Token: " + MASTER_ID.TOKEN);

    // ========== A. Native Layer: Cleaning Traces ==========
    /* [NORMAL MODE CRASH FIX] MTE 패치(patch_heap_tagging)가 꺼진 상태에서 
       libc.so 네이티브 후킹을 시도하면 안드로이드 14 시스템이 즉사시킴. 일단 주석 처리.
    function hookNative(name, onEnter, onLeave) {
        try {
            var ptr = Module.findExportByName(null, name) || Module.findExportByName("libc.so", name);
            if (ptr) Interceptor.attach(ptr, { onEnter: onEnter, onLeave: onLeave });
        } catch(e) {}
    }

    hookNative("__system_property_get", function(args) { this.k = args[0].readCString(); }, function(retval) {
        if (this.k && (this.k.indexOf("serial") !== -1 || this.k.indexOf("build.id") !== -1)) {
            args[1].writeUtf8String(MASTER_ID.SERIAL);
            retval.replace(MASTER_ID.SERIAL.length);
        }
    });
    */

    // ========== B. Java Layer: Internal Identity Laundering ==========
    setTimeout(function() {
        if (Java.available) {
            Java.perform(function() {
                var entering = false;

                // 1. Map Scrubber (LSPosed가 못바꾸는 내부 캐시 ID 타격)
                /* [NORMAL MODE CRASH FIX] 후보 4번 방어
                   HashMap, ArrayMap 등의 안드로이드 핵심 근간 클래스의 put 메서드를 JS 엔진으로 
                   넘겨벌면, 부팅 시 발생하는 수만 번의 할당 때문에 성능 오버헤드가 폭발하여
                   안드로이드 Zygote / Watchdog 이 즉사(Process terminated)시킵니다.
                   => V2에선 안 썼고 V3에서 추가된 로직이므로 과감하게 비활성화합니다.
                   (사실 파이썬 레이어인 mitm_addon.py 에서 최종 치환하므로 전혀 문제가 안됨!)
                   
                var mapTypes = ["java.util.HashMap", "android.util.ArrayMap", "java.util.LinkedHashMap"];
                mapTypes.forEach(function(cls) {
                    try {
                        Java.use(cls).put.implementation = function(k, v) {
                            if (entering || k === null) return this.put(k, v);
                            entering = true;
                            try {
                                var ks = k.toString();
                                if (ks === "adid" || ks === "da-dd") v = MASTER_ID.ADID;
                                else if (ks === "idfv" || ks === "da-dv") v = MASTER_ID.IDFV;
                                else if (ks === "ni") v = MASTER_ID.NI;
                                else if (ks === "nlog_id" && v !== null && v.toString().indexOf(".") !== -1) {
                                    var p = v.toString().split('.');
                                    if (p.length === 3) v = p[0] + "." + p[1] + "." + MASTER_ID.TOKEN;
                                }
                            } catch(e) {}
                            var res = this.put(k, v);
                            entering = false;
                            return res;
                        };
                    } catch(e) {}
                });
                */

                // 2. Safe Java Framework Hooks (기기 식별자 안전 덮어쓰기)
                try {
                    // start_new.sh 에서 설정한 랜덤 ssaid 프로퍼티를 읽어옴
                    var SystemProperties = Java.use("android.os.SystemProperties");
                    var spoofed_ssaid = SystemProperties.get("debug.nmap.ssaid", "");

                    var Secure = Java.use("android.provider.Settings$Secure");
                    Secure.getString.overload('android.content.ContentResolver', 'java.lang.String').implementation = function(cr, name) {
                        if (name === "android_id" && spoofed_ssaid !== "" && spoofed_ssaid !== "none") {
                            return spoofed_ssaid;
                        }
                        return this.getString(cr, name);
                    };
                    console.log("[✓] Safe Java Hooks Applied: android_id -> " + spoofed_ssaid);
                } catch(e) {
                    console.log("[-] Safe Java Hooks Error: " + e);
                }

                console.log("[✓] Internal Identity Scrubber active. System IDs left to LSPosed.");
            });
        }
    }, 100);
})();
