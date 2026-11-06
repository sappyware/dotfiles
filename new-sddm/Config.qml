pragma Singleton
import QtQuick

// Values come from theme.conf. Main.qml copies SDDM's `config` map into `data` at startup;
// everything here is a binding on it, so defaults apply for any key that is missing.
QtObject {
  id: root
  property var data: ({})

  function s(k, d) { var v = data[k]; return (v === undefined || v === null || v === "") ? d : String(v); }
  function b(k, d) { var v = s(k, ""); return v === "" ? d : (v === "true" || v === "1" || v === "yes"); }
  function n(k, d) { var v = parseFloat(s(k, "")); return isNaN(v) ? d : v; }

  readonly property string background: s("background", "")
  readonly property string input: s("input", "password") === "pin" ? "pin" : "password"
  readonly property bool keypad: b("keypad", false)
  readonly property int pinLength: Math.round(n("pin_length", 0))
  readonly property string font: s("font", "Google Sans")
  readonly property string md3Mode: s("md3_mode", "dark") === "light" ? "light" : "dark"
  readonly property string md3Seed: s("seed", "#6750A4")
  readonly property real blur: n("blur", 64)
  readonly property real dim: n("dim", 0.35)
  readonly property bool hour24: b("hour24", false)
  readonly property string clockStyle: s("clock", "stacked") === "inline" ? "inline" : "stacked"
  readonly property real clockGap: n("clock_gap", 0.06)
  readonly property int idleTimeout: Math.round(n("idle_timeout", 20))
  readonly property bool powerOn: b("power_buttons", true)
  readonly property bool weatherOn: b("weather", true)
  readonly property string weatherLoc: s("weather_location", "")
  readonly property bool weatherPlace: b("weather_show_place", false)
  readonly property bool imperial: s("weather_units", "metric") === "imperial"
}
