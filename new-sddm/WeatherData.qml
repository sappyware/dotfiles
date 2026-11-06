import QtQuick

// Weather over plain HTTPS (open-meteo). No helper process needed, so it works inside SDDM.
Item {
  id: root
  property bool ok: false
  property string temp: ""
  property string desc: ""
  property string place: ""
  property string kind: "cloud"
  property bool busy: false

  function kindOf(c) {
    if (c >= 95) return "bolt";
    if ((c >= 71 && c <= 77) || c === 85 || c === 86) return "snow";
    if ((c >= 51 && c <= 67) || (c >= 80 && c <= 82)) return "rain";
    if (c === 45 || c === 48) return "fog";
    if (c <= 1) return "sun";
    return "cloud";
  }
  function get(url, done, fail) {
    var x = new XMLHttpRequest();
    x.onreadystatechange = function () {
      if (x.readyState !== XMLHttpRequest.DONE) return;
      if (x.status !== 200) { fail(); return; }
      var j;
      try { j = JSON.parse(x.responseText); } catch (e) { fail(); return; }
      try { done(j); } catch (e2) { fail(); }
    };
    x.open("GET", url);
    x.send();
  }
  function forecast(lat, lon, place) {
    var u = "https://api.open-meteo.com/v1/forecast?latitude=" + lat + "&longitude=" + lon
          + "&current=temperature_2m,weather_code&temperature_unit=" + (Config.imperial ? "fahrenheit" : "celsius");
    get(u, function (j) {
      root.temp = Math.round(j.current.temperature_2m) + "\u00B0";
      root.kind = root.kindOf(j.current.weather_code);
      root.place = place;
      root.ok = true;
      root.busy = false;
    }, fail);
  }
  function fail() { root.busy = false; retry.restart(); }
  function refresh() {
    if (!Config.weatherOn || busy) return;
    busy = true;
    if (Config.weatherLoc !== "") {
      get("https://geocoding-api.open-meteo.com/v1/search?count=1&name=" + encodeURIComponent(Config.weatherLoc), function (j) {
        var r = j.results[0];
        root.forecast(r.latitude, r.longitude, r.name);
      }, fail);
    } else {
      get("https://ipwho.is/", function (j) {
        if (j.success === false) throw new Error("geoip");
        root.forecast(j.latitude, j.longitude, j.city || "");
      }, fail);
    }
  }
  // the greeter often starts before the network is up, so retry soon instead of waiting half an hour
  Timer { id: retry; interval: 20000; onTriggered: root.refresh() }
  Timer { interval: 1800000; repeat: true; running: Config.weatherOn; triggeredOnStart: true; onTriggered: root.refresh() }
}
