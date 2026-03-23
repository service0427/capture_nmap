/* 
   Universal Sensor Shield v1.0
   - Goal: Proactive defense for Naver, Kakao, and Google Maps.
   - Strategy: Fake dynamic noise for Accel, Gyro, and Mag sensors.
*/

Java.perform(function() {
    console.log("[*] Universal Sensor Shield Active (Accel/Gyro/Mag)");

    const SensorManager = Java.use("android.hardware.SensorManager");
    const SensorEvent = Java.use("android.hardware.SensorEvent");

    // Helper: 미세한 가우시안 노이즈 생성
    function getNoise(range) {
        return (Math.random() - 0.5) * range;
    }

    // 센서 리스너 등록 과정을 가로채서 데이터 조작 준비
    const onSensorChanged = "onSensorChanged";
    
    // [핵심] 모든 센서 이벤트 콜백을 가로챔
    const SensorEventListener = Java.use("android.hardware.SensorEventListener");
    
    // 실제 앱이 구현한 리스너의 onSensorChanged를 후킹
    // Note: 인터페이스 후킹은 동적으로 로드된 클래스를 찾아야 하므로 
    // SensorManager.registerListener 지점을 공략하는 것이 가장 범용적임
    
    SensorManager.registerListener.overload('android.hardware.SensorEventListener', 'android.hardware.Sensor', 'int').implementation = function(listener, sensor, rate) {
        var sensorType = sensor.getType();
        var sensorName = sensor.getName();
        
        // 특정 센서들에 대해서만 조작 시도
        // 1: Accel, 4: Gyro, 2: Mag
        if ([1, 2, 4].indexOf(sensorType) !== -1) {
            console.log("[Sensor] App registered listener for: " + sensorName);
            
            // 실제 리스너의 메서드를 낚아챔
            var callback = listener.$className;
            var targetClass = Java.use(callback);
            
            if (targetClass.onSensorChanged) {
                targetClass.onSensorChanged.implementation = function(event) {
                    var values = event.values.value;
                    
                    // 1. 가속도 센서 (TYPE_ACCELEROMETER)
                    if (event.sensor.value.getType() === 1) {
                        values[0] += getNoise(0.05); // X
                        values[1] += getNoise(0.05); // Y
                        values[2] += getNoise(0.05); // Z
                    }
                    // 2. 자이로스코프 (TYPE_GYROSCOPE)
                    else if (event.sensor.value.getType() === 4) {
                        values[0] += getNoise(0.01);
                        values[1] += getNoise(0.01);
                        values[2] += getNoise(0.01);
                    }
                    
                    return this.onSensorChanged(event);
                };
            }
        }
        return this.registerListener(listener, sensor, rate);
    };

    console.log("[✓] Universal Sensor Jitter integrated.");
});
