/* 
   Native Movement Engine v13.4 (Advanced Driving Physics)
   - Goal: Fix freezing issue after starting navigation.
   - Feature: Real-time Speed & Bearing calculation between waypoints.
*/

Java.perform(function() {
    console.log("[*] Native Movement Engine v13.4 Active (Physics Mode)");

    const Location = Java.use("android.location.Location");
    const ROUTE_FILE = "/data/local/tmp/target_route.json";
    
    var route = [];
    try {
        var file = new File(ROUTE_FILE, "r");
        var content = file.readText();
        file.close();
        var pts = JSON.parse(content);
        for (var i = 0; i < pts.length; i++) {
            route.push({ lat: parseFloat(pts[i][0]), lng: parseFloat(pts[i][1]) });
        }
        console.log("[Engine] Loaded " + route.length + " waypoints.");
    } catch (e) { console.log("[!] Load Error: " + e); }

    var currentIndex = 0;
    var currentLat = 0, currentLng = 0;
    var lastLat = 0, lastLng = 0;
    var currentSpeed = 15.5; // m/s (약 55km/h)
    var currentBearing = 0.0;

    // --- 수학 함수: 두 점 사이의 방위각(Bearing) 계산 ---
    function calculateBearing(lat1, lon1, lat2, lon2) {
        var dLon = (lon2 - lon1) * Math.PI / 180;
        var y = Math.sin(dLon) * Math.cos(lat2 * Math.PI / 180);
        var x = Math.cos(lat1 * Math.PI / 180) * Math.sin(lat2 * Math.PI / 180) -
                Math.sin(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * Math.cos(dLon);
        var brng = Math.atan2(y, x) * 180 / Math.PI;
        return (brng + 360) % 360;
    }

    // 1초마다 물리 상태 업데이트
    if (route.length > 0) {
        setInterval(function() {
            if (currentIndex < route.length) {
                lastLat = currentLat;
                lastLng = currentLng;
                
                currentLat = route[currentIndex].lat;
                currentLng = route[currentIndex].lng;

                // 이동 중이라면 각도 계산
                if (lastLat !== 0) {
                    currentBearing = calculateBearing(lastLat, lastLng, currentLat, currentLng);
                }
                
                if (currentIndex % 5 === 0) {
                    console.log("[Engine] Driving... Node: " + currentIndex + "/" + route.length + " (" + currentLat.toFixed(5) + ", " + currentLng.toFixed(5) + ") Brg: " + currentBearing.toFixed(1));
                }

                currentIndex++;
                if (currentIndex >= route.length) currentIndex = 0;
            }
        }, 1000);
    }

    // --- 핵심: 내비 엔진이 참조하는 모든 Getter 후킹 ---
    
    Location.getLatitude.implementation = function() {
        return currentLat !== 0 ? currentLat + (Math.random()-0.5)*0.0000002 : this.getLatitude();
    };

    Location.getLongitude.implementation = function() {
        return currentLng !== 0 ? currentLng + (Math.random()-0.5)*0.0000002 : this.getLongitude();
    };

    Location.getBearing.implementation = function() {
        return currentBearing !== 0 ? currentBearing : this.getBearing();
    };

    Location.getSpeed.implementation = function() {
        // 내비 모드에서는 속도가 0이면 멈춤. 강제로 주행 속도 주입.
        return currentLat !== 0 ? currentSpeed + (Math.random()-0.5)*0.5 : this.getSpeed();
    };

    // 타임스탬프 갱신 (엔진이 데이터가 '옛날 것'이라고 판단하지 못하게 함)
    Location.getTime.implementation = function() { return Date.now(); };
    Location.getElapsedRealtimeNanos.implementation = function() {
        const SystemClock = Java.use("android.os.SystemClock");
        return SystemClock.elapsedRealtimeNanos();
    };

    // 기타 FDS 필드
    Location.getAccuracy.implementation = function() { return 5.5; };
    Location.getVerticalAccuracyMeters.implementation = function() { return 4.2; };
    Location.isFromMockProvider.implementation = function() { return false; };

    console.log("[✓] Physics-based Movement Engine Ready.");
});
