Java.perform(function() {
    console.log("[*] GPS Emulator Intent Tracker Active");

    var Intent = Java.use("android.content.Intent");
    var ContextImpl = Java.use("android.app.ContextImpl");

    ContextImpl.startService.overload('android.content.Intent').implementation = function(intent) {
        console.log("\n[+] startService Called!");
        console.log("  -> Action: " + intent.getAction());
        console.log("  -> Component: " + intent.getComponent());

        var extras = intent.getExtras();
        if (extras) {
            var keySet = extras.keySet();
            var iterator = keySet.iterator();
            while (iterator.hasNext()) {
                var key = iterator.next().toString();
                var val = extras.get(key);
                console.log("  -> Extra [" + key + "]: " + val);
            }
        }
        return this.startService(intent);
    };
});
