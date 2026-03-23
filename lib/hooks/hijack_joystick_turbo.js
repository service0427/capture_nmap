/* 
   Turbo-Glide Hijacking Engine v2.0
   - Feature: Look-ahead Speed Control (10% Time Reduction)
   - Target: com.rosteam.gpsemulator
*/
Java.perform(function() {
    var LocationManager = Java.use('android.location.LocationManager');
    var File = Java.use('java.io.File');
    var Scanner = Java.use('java.util.Scanner');
    
    var masterPath = [];
    var activeQueue = [];
    var currentSpeedMps = 16.6; 
    var baseSpeedMps = 16.6;
    var alpha = 0.1; 

    function loadRoute() {
        var f = File.$new("/data/local/tmp/target_route.json");
        if (!f.exists()) return;
        var scanner = Scanner.$new(f);
        var content = "";
        if (scanner.hasNextLine()) content = scanner.nextLine();
        scanner.close();
        
        try {
            var raw = JSON.parse(content);
            var newPath = [];
            for (var i = 0; i < raw.length - 1; i++) {
                var p1 = raw[i], p2 = raw[i+1];
                var dLon = (p2[1] - p1[1]) * Math.PI / 180;
                var y = Math.sin(dLon) * Math.cos(p2[0] * Math.PI / 180);
                var x = Math.cos(p1[0] * Math.PI / 180) * Math.sin(p2[0] * Math.PI / 180) - Math.sin(p1[0] * Math.PI / 180) * Math.cos(p2[0] * Math.PI / 180) * Math.cos(dLon);
                var bearing = (Math.atan2(y, x) * 180 / Math.PI + 360) % 360;
                newPath.push({lat: p1[0], lng: p1[1], bearing: bearing});
            }
            masterPath = newPath;
            activeQueue = JSON.parse(JSON.stringify(masterPath));
            console.log("[✓] Turbo Engine: " + masterPath.length + " points ready.");
        } catch(e) { console.log("[!] Error loading route: " + e); }
    }

    function calculateDynamicSpeed() {
        if (activeQueue.length === 0) return baseSpeedMps;
        
        var lookAhead = 10;
        var maxDiff = 0;
        var curB = activeQueue[0].bearing;
        
        for (var i = 1; i < lookAhead && i < activeQueue.length; i++) {
            var diff = Math.abs(activeQueue[i].bearing - curB);
            if (diff > 180) diff = 360 - diff;
            if (diff > maxDiff) maxDiff = diff;
        }

        var factor = 1.0;
        if (maxDiff < 2.0) factor = 1.15; // 직선 가속
        else if (maxDiff > 10.0) factor = Math.max(0.5, 1.0 - (maxDiff / 45.0)); // 커브 감속

        currentSpeedMps = currentSpeedMps + (baseSpeedMps * factor - currentSpeedMps) * alpha;
        return currentSpeedMps;
    }

    loadRoute();

    LocationManager.setTestProviderLocation.implementation = function(provider, loc) {
        if (activeQueue.length === 0) {
            console.log("[♻️] Turbo Loop Reset...");
            loadRoute();
        }

        var next = activeQueue.shift();
        if (next) {
            var speed = calculateDynamicSpeed();
            loc.setLatitude(next.lat);
            loc.setLongitude(next.lng);
            loc.setBearing(next.bearing);
            loc.setSpeed(speed);
            loc.setTime(Java.use('java.lang.System').currentTimeMillis());
        }
        this.setTestProviderLocation(provider, loc);
    };
});
