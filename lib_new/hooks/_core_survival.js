/* 
   Core Survival System (V3 Refactored)
   - Goal: Prevent App Crash & Skip Agreement Screen rendering bug.
   - Executed: ALWAYS (Even in --no-filter mode)
*/

console.log("[*] Core Survival System Loaded");

// 1. Android 14/15 MTE (Heap Tagging) Crash Prevention
function patch_heap_tagging() {
    try {
        // [ENHANCED] Use Module.findExportByName correctly with null as first arg for broad search
        var set_heap_tagging = Module.findExportByName(null, "android_set_heap_tagging_level");
        if (set_heap_tagging) {
            Interceptor.attach(set_heap_tagging, {
                onEnter: function(args) { 
                    // Force level to 0 (MTE off)
                    args[0] = ptr(0); 
                }
            });
            console.log("[✓] MTE Layer 1 Active (android_set_heap_tagging_level)");
        }

        var prctl = Module.findExportByName(null, "prctl");
        if (prctl) {
            Interceptor.attach(prctl, {
                onEnter: function(args) {
                    var option = args[0].toInt32();
                    if (option === 53) { // PR_SET_TAGGED_ADDR_CTRL
                        // Force tag mode to 0 (disabled)
                        args[1] = ptr(0); 
                    }
                }
            });
            console.log("[✓] MTE Layer 2 Active (prctl)");
        }
    } catch(e) {
        console.log("[-] MTE Patch Error: " + e);
    }
}

// 2. FDS Stealth (Hide Root, Magisk, Developer Options)
function hook_stealth() {
    if (!Java.available) return;
    Java.perform(function() {
        try {
            var File = Java.use("java.io.File");
            File.exists.implementation = function() {
                var name = this.getName();
                if (name === "su" || name === "magisk" || name === "frida-server" || name === "busybox") return false;
                return this.exists.call(this);
            };

            var SettingsGlobal = Java.use("android.provider.Settings$Global");
            SettingsGlobal.getInt.overload('android.content.ContentResolver', 'java.lang.String', 'int').implementation = function(cr, name, def) {
                if (name === "development_settings_enabled" || name === "adb_enabled") return 0;
                return this.getInt(cr, name, def);
            };

            var SettingsSecure = Java.use("android.provider.Settings$Secure");
            SettingsSecure.getInt.overload('android.content.ContentResolver', 'java.lang.String', 'int').implementation = function(cr, name, def) {
                if (name === "development_settings_enabled" || name === "adb_enabled") return 0;
                return this.getInt(cr, name, def);
            };

            var System = Java.use("java.lang.System");
            var getProp = System.getProperty.overload('java.lang.String');
            System.getProperty.overload('java.lang.String').implementation = function(key) {
                if (key === "ro.debuggable" || key === "ro.secure") {
                    return key === "ro.secure" ? "1" : "0";
                }
                return getProp.call(System, key);
            };
        } catch(e) {}
    });
}

// 3. Skip Agreement Screen (Prevents rendering crash on start)
function skip_agreement_screen() {
    if (!Java.available) return;
    Java.perform(function() {
        try {
            Java.use("android.app.SharedPreferencesImpl").getBoolean.implementation = function(k, d) {
                // Sometimes checked for permissions agreements
                if (k.indexOf("agree") !== -1) return true;
                return this.getBoolean(k, d);
            };
            
            var INSTALL_TS = 1774000000 + Math.floor(Math.random() * 100000);
            Java.use("android.app.SharedPreferencesImpl").getLong.implementation = function(k, d) {
                if (k.indexOf("FirstOpenTime") !== -1 || k.indexOf("install") !== -1) return INSTALL_TS;
                return this.getLong(k, d);
            };
            console.log("[+] Agreement Screen Skipped Successfully");
        } catch(e) {}
    });
}

// Boot sequence: MTE patch MUST be first.
setTimeout(patch_heap_tagging, 50);
setTimeout(hook_stealth, 150);
setTimeout(skip_agreement_screen, 600);
