Java.perform(function() {
    console.log("============================================================");
    console.log("   🔍 REAL-DEVICE SENSOR & LOCATION OBSERVER");
    console.log("============================================================");

    const Location = Java.use("android.location.Location");
    
    // 1. GPS 오차(Accuracy) 관측
    Location.getAccuracy.implementation = function() {
        var acc = this.getAccuracy();
        console.log("[GPS] Accuracy: " + acc.toFixed(2) + "m");
        return acc;
    };

    // 2. 고도(Altitude) 관측
    Location.getAltitude.implementation = function() {
        var alt = this.getAltitude();
        console.log("[GPS] Altitude: " + alt.toFixed(2) + "m");
        return alt;
    };

    // 3. 방향(Bearing) 관측
    Location.getBearing.implementation = function() {
        var brg = this.getBearing();
        if (brg !== 0) {
            console.log("[GPS] Bearing: " + brg.toFixed(2) + "°");
        }
        return brg;
    };

    // 4. 가속도 센서(Accelerometer) 관측 - 물리적 흔들림 확인
    const SensorEvent = Java.use("android.hardware.SensorEvent");
    const Sensor = Java.use("android.hardware.Sensor");

    // 센서 데이터는 배열 형태이므로 내부 값을 출력
    // 네이버 앱이 SensorEventListener를 구현한 지점을 가로채는 것이 더 정확하지만,
    // 일단 시스템 레벨의 데이터 흐름을 봅니다.
});
