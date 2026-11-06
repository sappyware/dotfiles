import QtQuick

Item {
  id: root
  width: 1920; height: 1080   // SDDM resizes this to the screen

  LockContext { id: ctx }
  LockSurface {
    anchors.fill: parent
    ctx: ctx
    wall: Config.background !== "" ? Qt.resolvedUrl(Config.background) : ""
  }

  // hand theme.conf (SDDM's `config`) to the Config singleton
  Component.onCompleted: {
    var keys = ["background", "seed", "input", "keypad", "pin_length", "font", "md3_mode", "blur", "dim",
                "hour24", "clock", "clock_gap", "idle_timeout", "power_buttons", "weather",
                "weather_location", "weather_show_place", "weather_units"];
    var d = {};
    try { for (var i = 0; i < keys.length; i++) d[keys[i]] = config[keys[i]]; } catch (e) { console.warn("roselogin: could not read theme.conf"); }
    Config.data = d;
  }
}
