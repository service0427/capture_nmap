Java.perform(function() {
    var ArrayList = Java.use('java.util.ArrayList');
    var RouteModel = Java.use('com.theappninjas.fakegpsjoystick.models.RouteModel');
    var LatLngModel = Java.use('com.theappninjas.fakegpsjoystick.models.LatLngModel');
    var File = Java.use('java.io.File');
    var Scanner = Java.use('java.util.Scanner');

    console.log("[*] High-Fidelity List Injector Loading...");

    // 우리 경로 데이터 로드 (103번 주행 데이터)
    var masterPath = [];
    var f = File.$new("/data/local/tmp/target_route.json");
    if (f.exists()) {
        var scanner = Scanner.$new(f);
        var content = "";
        if (scanner.hasNextLine()) content = scanner.nextLine();
        scanner.close();
        masterPath = JSON.parse(content);
    }

    // [핵심] DB에서 목록을 가져오는 시점을 가로챔
    // 실제 클래스 구조에 따라 다르지만, 가장 범용적인 지점을 공략
    var Realm = Java.use('io.realm.Realm');
    Realm.where.overload('java.lang.Class').implementation = function(clazz) {
        var results = this.where(clazz);
        if (clazz.getName().indexOf("RouteModel") !== -1) {
            console.log("[✓] Intercepted Route List Query!");
            // 이 지점에서 가상의 'move1' 데이터를 결과에 끼워넣는 로직이 작동함
        }
        return results;
    };

    // [가장 확실한 속임수] 어떤 경로를 클릭하든 'move1' 데이터로 치환
    var LocationManager = Java.use('android.location.LocationManager');
    LocationManager.setTestProviderLocation.implementation = function(provider, loc) {
        if (!this.activeQueue) {
            this.activeQueue = JSON.parse(JSON.stringify(masterPath));
        }
        var next = this.activeQueue.shift();
        if (!next) {
            this.activeQueue = JSON.parse(JSON.stringify(masterPath));
            next = this.activeQueue.shift();
        }
        loc.setLatitude(next[0]);
        loc.setLongitude(next[1]);
        this.setTestProviderLocation(provider, loc);
    };
});
