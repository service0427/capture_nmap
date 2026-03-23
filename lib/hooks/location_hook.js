/* 
   Location Jitter & Realism Engine v12.2 (Vertical Jitter Edition) - ORIGINAL
   - Goal: Eliminate field 7 (Vertical Accuracy) being 0.0
   - Feature: Enforce realistic altitude errors to match physical movements.
*/

Java.perform(function() {
    console.log("[*] High-Fidelity Location Hook Engine v12.2 Active");

    const Location = Java.use("android.location.Location");

    function getRandomFloat(min, max, precision) {
        var num = Math.random() * (max - min) + min;
        return parseFloat(num.toFixed(precision));
    }

    Location.getLatitude.implementation = function() {
        var lat = this.getLatitude();
        if (lat === 0) return lat;
        return lat + (Math.random() > 0.5 ? 0.0000001 : -0.0000001);
    };

    Location.getLongitude.implementation = function() {
        var lng = this.getLongitude();
        if (lng === 0) return lng;
        return lng + (Math.random() > 0.5 ? 0.0000001 : -0.0000001);
    };

    Location.getAccuracy.implementation = function() {
        return getRandomFloat(4.5, 9.5, 1);
    };

    Location.getAltitude.implementation = function() {
        var alt = this.getAltitude();
        if (alt === 0) return getRandomFloat(15.5, 17.5, 2);
        return alt + getRandomFloat(-0.1, 0.1, 2);
    };

    try {
        Location.hasVerticalAccuracy.implementation = function() { return true; };
        Location.getVerticalAccuracyMeters.implementation = function() {
            return getRandomFloat(3.5, 8.5, 1);
        };
    } catch(e) {}

    Location.getBearing.implementation = function() {
        var brg = this.getBearing();
        return brg + getRandomFloat(-0.05, 0.05, 2);
    };

    Location.isFromMockProvider.implementation = function() {
        return false;
    };

    var oldSet = Location.set;
    Location.set.implementation = function(loc) {
        var res = oldSet.call(this, loc);
        try {
            this.setVerticalAccuracyMeters(getRandomFloat(3.5, 8.5, 1));
        } catch(err) {}
        return res;
    };

    console.log("[✓] v12.2 Vertical Jitter restored.");
});
