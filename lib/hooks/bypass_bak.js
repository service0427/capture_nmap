/* 
   Naver Map Master Bypass Script v1.0 (Consolidated)
   - Goal: Total Identity Dominance. Zero Errors. High Fidelity.
   - Patterns: adid (UUID), ssaid (16-hex), ni (32-hex), nlog_id (16-mixed).
   - Features: Native Scrubber + Java Eraser + Humanity Jitter.
*/

console.log("\n[!!!] MASTER BYPASS SYSTEM V1.0 START [!!!]");

(function() {
    // 1. 유니크 식별자 생성기
    function uuidv4() { return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) { var r = Math.random() * 16 | 0, v = c == 'x' ? r : (r & 0x3 | 0x8); return v.toString(16); }); }
    function hex(len) { var res = ""; var c = "0123456789abcdef"; for (var i = 0; i < len; i++) res += c.charAt(Math.floor(Math.random() * c.length)); return res; }
    function mixed(len) { var res = ""; var c = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"; for (var i = 0; i < len; i++) res += c.charAt(Math.floor(Math.random() * c.length)); return res; }

    // [세션 마스터 Identity]
    var MASTER_ID = {
        ADID: uuidv4(),
        SSAID: hex(16),
        IDFV: uuidv4(),
        NI: hex(32),
        TOKEN: mixed(16),
        INSTALL_TS: 1774000000 + Math.floor(Math.random() * 1000000),
        STORAGE: (113000000000 + Math.floor(Math.random() * 1000000000)),
        SERIAL: "SN" + Math.floor(Math.random() * 100000000)
    };

    // [기존 고착 데이터 리스트]
    var GHOSTS = {
        ADID: "f43946e9-bcd3-4cee-a5fb-dea35a25c416",
        SSAID: "e6019a5182dfb4d4",
        TOKEN: "MINrZnh9x9jTNelh",
        TS: "1773888604"
    };

    console.log("[*] Final Identity Synced for Session:");
    console.log("    > New SSAID: " + MASTER_ID.SSAID);
    console.log("    > New Token: " + MASTER_ID.TOKEN);

    // ========== A. Native Layer: Secure Atomic Control ==========
    function hookNative(name, onEnter, onLeave) {
        try {
            var ptr = Module.findExportByName(null, name) || Module.findExportByName("libc.so", name);
            if (ptr) Interceptor.attach(ptr, { onEnter: onEnter, onLeave: onLeave });
        } catch(e) {}
    }

    // 1. Native Property (Serial)
    hookNative("__system_property_get", function(args) { this.k = args[0].readCString(); }, function(retval) {
        if (this.k && (this.k.indexOf("serial") !== -1 || this.k.indexOf("build.id") !== -1)) {
            args[1].writeUtf8String(MASTER_ID.SERIAL);
            retval.replace(MASTER_ID.SERIAL.length);
        }
    });

    // 2. Native Buffer Scrubber (write/send)
    hookNative("write", function(args) {
        var len = args[2].toInt32();
        if (len > 64) {
            try {
                var s = args[1].readUtf8String(len);
                if (s && (s.indexOf("MINrZnh9") !== -1 || s.indexOf(GHOSTS.ADID.substring(0,8)) !== -1)) {
                    s = s.replace(/MINrZnh9x9jTNelh/g, MASTER_ID.TOKEN);
                    s = s.replace(/f43946e9-bcd3-4cee-a5fb-dea35a25c416/g, MASTER_ID.ADID);
                    args[1].writeUtf8String(s);
                }
            } catch(e) {}
        }
    }, function(retval) {});

    // ========== B. Java Layer: Absolute Framework Mastery ==========
    Java.perform(function() {
        var Long = Java.use("java.lang.Long");
        var entering = false;

        // 1. Universal Map/Container Scrubber (Type-Safe)
        var mapTypes = ["java.util.HashMap", "android.util.ArrayMap", "java.util.LinkedHashMap"];
        mapTypes.forEach(function(cls) {
            try {
                Java.use(cls).put.implementation = function(k, v) {
                    if (entering || k === null) return this.put(k, v);
                    entering = true;
                    try {
                        var ks = k.toString();
                        if (ks === "adid" || ks === "da-dd") v = MASTER_ID.ADID;
                        else if (ks === "ssaid") v = MASTER_ID.SSAID;
                        else if (ks === "idfv" || ks === "da-dv") v = MASTER_ID.IDFV;
                        else if (ks === "ni") v = MASTER_ID.NI;
                        else if (ks === "install_ts" && v !== null && v.toString() === GHOSTS.TS) v = Long.valueOf(MASTER_ID.INSTALL_TS);
                        else if (ks === "storage_size") v = Long.valueOf(MASTER_ID.STORAGE);
                        else if (ks === "nlog_id" && v !== null && v.toString().indexOf("MINrZnh9") !== -1) {
                            var p = v.toString().split('.');
                            if (p.length === 3) v = p[0] + "." + p[1] + "." + MASTER_ID.TOKEN;
                        }
                        // Humanity Jitter: screen_duration 미세 변조
                        else if (ks === "screen_duration" && typeof v === 'number') {
                            v = Long.valueOf(v + (Math.floor(Math.random() * 400) - 200));
                        }
                    } catch(e) {}
                    var res = this.put(k, v);
                    entering = false;
                    return res;
                };
            } catch(e) {}
        });

        // 2. SharedPreferences Master Overwrite
        try {
            Java.use("android.app.SharedPreferencesImpl").getLong.implementation = function(k, d) {
                if (k.indexOf("FirstOpenTime") !== -1 || k.indexOf("install") !== -1) return MASTER_ID.INSTALL_TS;
                return this.getLong(k, d);
            };
        } catch(e) {}

        console.log("[✓] Master Core Monolith fully deployed.");
    });

    console.log("[✓] MASTER BYPASS READY.\n");
})();
