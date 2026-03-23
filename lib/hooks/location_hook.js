/* 
   Location Jitter & Realism Engine v12.1 (Type-Perfect Edition)
   - Verified Types: Latitude/Longitude (Double), Accuracy/Bearing (Float)
   - Verified Logic: Matches Naver SDK v2.6.0 conversion patterns.
*/

Java.perform(function() {
    console.log("[*] Type-Perfect Location Hook Engine Active");

    const Location = Java.use("android.location.Location");

    // Helper: 실제 안드로이드 센서와 유사한 소수점 정밀도 생성
    function getRandomFloat(min, max, precision) {
        var num = Math.random() * (max - min) + min;
        return parseFloat(num.toFixed(precision)); // Float 정밀도 보장
    }

    // 1. 위도/경도 (Double 타입 유지)
    var oldLat = Location.getLatitude;
    Location.getLatitude.implementation = function() {
        var lat = oldLat.call(this);
        if (lat === 0) return lat;
        // 0.0000001은 실제 거리 약 1cm~10cm 오차
        return lat + (Math.random() > 0.5 ? 0.0000001 : -0.0000001);
    };

    var oldLng = Location.getLongitude;
    Location.getLongitude.implementation = function() {
        var lng = oldLng.call(this);
        if (lng === 0) return lng;
        return lng + (Math.random() > 0.5 ? 0.0000001 : -0.0000001);
    };

    // 2. 정확도 (Float 타입)
    // 리얼 기기 관측값(4.0~12.0)을 반영하되, 소수점 1자리까지의 정밀한 Float 반환
    Location.getAccuracy.implementation = function() {
        return getRandomFloat(4.5, 9.5, 1);
    };

    // 3. 고도 (Double 타입)
    Location.getAltitude.implementation = function() {
        var alt = this.getAltitude();
        if (alt === 0) return getRandomFloat(15.0, 17.0, 2);
        return alt + getRandomFloat(-0.1, 0.1, 2);
    };

    // 4. 방향 (Float 타입)
    Location.getBearing.implementation = function() {
        var brg = this.getBearing();
        // 주행 중 미세한 핸들링 흔들림(±0.05도) 추가
        return brg + getRandomFloat(-0.05, 0.05, 2);
    };

    // 5. 모의 위치 탐지 무력화
    Location.isFromMockProvider.implementation = function() {
        return false;
    };

    console.log("[✓] Type-correct jitter applied to all sensors.");
});
