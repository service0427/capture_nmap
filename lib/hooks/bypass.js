/* 
   Advanced Bypass & Profile Spoofing v13.3 (Stable Recovery)
   - Goal: Fix 'TypeError' and Ensure App Launch.
*/

console.log("[*] High-Fidelity Bypass v13.3 Active");

Java.perform(function() {
    var SystemProperties = Java.use("android.os.SystemProperties");
    var Build = Java.use("android.os.Build");
    
    let m = SystemProperties.get("debug.nmap.model");
    let b = SystemProperties.get("debug.nmap.brand");
    let s = SystemProperties.get("debug.nmap.ssaid");
    let i = SystemProperties.get("debug.nmap.idfv");

    if (m && m !== "none") {
        console.log("[Frida] Identity Spoofing: " + b + " " + m);
        try {
            Build.MODEL.value = m;
            Build.BRAND.value = b;
            Build.MANUFACTURER.value = b;
            Build.PRODUCT.value = m;
            Build.DEVICE.value = m;
        } catch(e) {}

        // OkHttp3 Header Sanitizer
        try {
            var Builder = Java.use("okhttp3.Request$Builder");
            var sanitizeHeader = function(name, value) {
                if (name.toLowerCase() === "user-agent") {
                    return value.replace(/SM-A165N/g, m).replace(/samsung/gi, b);
                }
                return value;
            };
            Builder.header.implementation = function(n, v) { return this.header(n, sanitizeHeader(n, v)); };
            Builder.addHeader.implementation = function(n, v) { return this.addHeader(n, sanitizeHeader(n, v)); };
        } catch(e) {}
    }

    // Identifiers
    if (s) {
        Java.use("android.provider.Settings$Secure").getString.overload('android.content.ContentResolver', 'java.lang.String').implementation = function(c, n) {
            if (n === "android_id") return s;
            return this.getString(c, n);
        };
    }
});

// Native Hook - 가장 안전한 방식으로 재구축
function hook_native_safe() {
    // findExportByName이 실패할 경우를 대비해 try-catch 및 존재 여부 확인 필수
    try {
        var addr = Module.findExportByName(null, "__system_property_get");
        if (addr) {
            Interceptor.attach(addr, {
                onEnter: function(args) { this.key = args[0].readCString(); },
                onLeave: function(retval) {
                    // Java 레이어에서 이미 변조되므로 네이티브는 최소한으로만 개입
                    if (this.key.indexOf("model") !== -1 && !this.key.startsWith("debug.")) {
                        // 필요한 경우에만 여기서 추가 변조
                    }
                }
            });
        }
    } catch(e) {
        console.log("[-] Native hook skipped for stability.");
    }
}

// 구동 타이밍 조절 (앱이 완전히 뜬 후 실행)
setTimeout(hook_native_safe, 2000);
