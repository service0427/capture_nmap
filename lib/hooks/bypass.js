/* 
   Advanced Bypass & Profile Spoofing v13.0 (Energy & Thermal Dynamics)
   - Environment: Natural Uptime (0-600s)
   - Energy: Dynamic Battery Level (65-95%) & Charging Status (AC/USB)
   - Thermal: Realistic Temperature drift (28C -> 42C) during navigation
*/

console.log("[*] High-Fidelity Energy & Thermal Engine v13.0 Active");

function hook_battery_and_uptime() {
    Java.perform(function() {
        const SystemClock = Java.use("android.os.SystemClock");
        const Intent = Java.use("android.content.Intent");
        const BatteryManager = Java.use("android.os.BatteryManager");

        // 1. Natural Uptime (0~600s)
        const bootOffsetMs = Math.floor(Math.random() * 600000); 
        SystemClock.elapsedRealtime.implementation = function() { return this.elapsedRealtime() + bootOffsetMs; };
        SystemClock.uptimeMillis.implementation = function() { return this.uptimeMillis() + bootOffsetMs; };

        // 2. Battery Dynamics Initialization
        const startBatteryLevel = Math.floor(Math.random() * 31) + 65; // 65% ~ 95%
        const isCharging = Math.random() < 0.7; // 70% 확률로 충전 중
        const startTime = Date.now();

        console.log("[Frida] Initial Power: " + startBatteryLevel + "% (Charging: " + isCharging + ")");

        // 3. Battery Intent Hook (The main source for Naver SDK)
        // Intent.getIntExtra를 가로채서 배터리 정보를 속임
        Intent.getIntExtra.implementation = function(name, defaultValue) {
            const now = Date.now();
            const elapsedMins = (now - startTime) / 60000;

            if (name === "level") {
                // 충전 중이면 5분당 1% 상승, 아니면 1% 하락
                var currentLevel = isCharging ? 
                    startBatteryLevel + Math.floor(elapsedMins / 5) : 
                    startBatteryLevel - Math.floor(elapsedMins / 5);
                return Math.min(100, Math.max(1, currentLevel));
            }
            if (name === "status") {
                // 2: Charging, 1: Unknown, 3: Discharging
                return isCharging ? 2 : 3;
            }
            if (name === "plugged") {
                // 1: AC, 2: USB
                return isCharging ? (Math.random() < 0.5 ? 1 : 2) : 0;
            }
            if (name === "temperature") {
                // 주행 1분당 0.5도 상승 (28도 시작, 최대 42도)
                var temp = 280 + Math.floor(elapsedMins * 5);
                return Math.min(420, temp);
            }
            return this.getIntExtra(name, defaultValue);
        };
    });
}

function hook_identity_v13() {
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
        if (i) {
            try {
                const NTracker = Java.use("com.navercorp.ntracker.ntrackersdk.NTrackerContext");
                NTracker.O.implementation = function(ctx, func, info) {
                    if (info) info.a.implementation = function() { return i; };
                    return this.O(ctx, func, info);
                };
            } catch(e) {}
        }
    });
}

// Native Level (libc.so)
function hook_native_v13() {
    const libc = Process.findModuleByName("libc.so");
    if (!libc) return;
    const sys_get = Module.findExportByName(libc.name, "__system_property_get");
    if (sys_get) {
        Interceptor.attach(sys_get, {
            onEnter: function(args) { this.key = args[0].readCString(); },
            onLeave: function(retval) {
                const m = DeviceProperties.get("debug.nmap.model");
                const b = DeviceProperties.get("debug.nmap.brand");
                if (m && m !== "none") {
                    if (this.key.indexOf("model") !== -1 || this.key.indexOf("device") !== -1) args[1].writeUtf8String(m);
                    if (this.key.indexOf("brand") !== -1 || this.key.indexOf("manufacturer") !== -1) args[1].writeUtf8String(b);
                }
            }
        });
    }
}

var DeviceProperties = {
    get: function(name) {
        var val = "";
        try { val = Java.use("android.os.SystemProperties").get(name); } catch(e) {}
        return val;
    }
};

hook_native_v13();
hook_identity_v13();
hook_battery_and_uptime();

// Security & Location Jitter
setTimeout(function() {
    Java.perform(function () {
        try {
            Java.use("android.webkit.WebViewClient").onReceivedSslError.implementation = function (v, h, e) { h.proceed(); };
            Java.use('com.android.org.conscrypt.TrustManagerImpl').checkTrustedRecursive.implementation = function () { return Java.use('java.util.ArrayList').$new(); };
            Java.use("android.location.Location").isFromMockProvider.implementation = function() { return false; };
        } catch (e) {}
    });
}, 1000);
