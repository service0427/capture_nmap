Java.perform(function() {
    console.log("[*] DEV BOOST: Forcing Naver Map speed to 999 km/h...");
    const Location = Java.use("android.location.Location");

    Location.getSpeed.implementation = function() {
        // 999 km/h = 277.5 m/s
        return 277.5;
    };
});
