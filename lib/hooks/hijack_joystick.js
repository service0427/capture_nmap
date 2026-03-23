Java.perform(function() {
    var LocationManager = Java.use('android.location.LocationManager');
    var File = Java.use('java.io.File');
    var Scanner = Java.use('java.util.Scanner');
    var masterPath = [];
    var interpolatedQueue = [];

    function loadAndInterpolate() {
        var f = File.$new("/data/local/tmp/target_route.json");
        if (!f.exists()) return;
        
        var scanner = Scanner.$new(f);
        var content = "";
        if (scanner.hasNextLine()) content = scanner.nextLine();
        scanner.close();
        
        try {
            var raw = JSON.parse(content);
            if (raw.length < 2) return;

            interpolatedQueue = [];
            // Catmull-Rom 보간 로직
            for (var i = 0; i < raw.length - 1; i++) {
                var p0 = raw[i === 0 ? 0 : i - 1];
                var p1 = raw[i];
                var p2 = raw[i + 1];
                var p3 = (i + 2 >= raw.length) ? raw[raw.length - 1] : raw[i + 2];

                for (var t = 0; t < 1; t += 0.05) { // 더 촘촘하게 20단계 보간
                    var lat = 0.5 * ((2 * p1[0]) + (-p0[0] + p2[0]) * t + (2 * p0[0] - 5 * p1[0] + 4 * p2[0] - p3[0]) * (t * t) + (-p0[0] + 3 * p1[0] - 3 * p2[0] + p3[0]) * (t * t * t));
                    var lng = 0.5 * ((2 * p1[1]) + (-p0[1] + p2[1]) * t + (2 * p0[1] - 5 * p1[1] + 4 * p2[1] - p3[1]) * (t * t) + (-p0[1] + 3 * p1[1] - 3 * p2[1] + p3[1]) * (t * t * t));
                    interpolatedQueue.push([lat, lng]);
                }
            }
            console.log("[✓] Interpolation Applied: " + interpolatedQueue.length + " points.");
        } catch(e) {
            console.log("[!] Error parsing route: " + e);
        }
    }

    loadAndInterpolate();

    LocationManager.setTestProviderLocation.implementation = function(provider, loc) {
        if (interpolatedQueue.length === 0) {
            loadAndInterpolate();
        }
        
        var next = interpolatedQueue.shift();
        if (next) {
            loc.setLatitude(next[0]);
            loc.setLongitude(next[1]);
        }
        
        this.setTestProviderLocation(provider, loc);
    };
});
