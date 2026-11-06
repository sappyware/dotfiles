import QtQuick

// Login state. Same API the lock screen's UI already used (text / authing / error / shake / busy),
// but submit() hands the password to SDDM instead of PAM.
Item {
  id: root
  visible: false
  property string text: ""
  property bool authing: false
  property string error: ""
  property int shake: 0
  property bool busy: false
  readonly property bool pin: Config.input === "pin"
  readonly property bool caps: { try { return keyboard.capsLock; } catch (e) { return false; } }

  // users / sessions, collected from SDDM's models
  property var userNames: []
  property var userReals: []
  property var sessionNames: []
  property int userIndex: 0
  property int sessionIndex: 0
  readonly property int userCount: userNames.length
  readonly property int sessionCount: sessionNames.length
  readonly property string userName: userNames[userIndex] || ""
  readonly property string userLabel: userReals[userIndex] || userName
  readonly property string sessionLabel: sessionNames[sessionIndex] || ""

  Repeater {
    model: userModel
    delegate: Item {
      Component.onCompleted: {
        var n = root.userNames.slice(), r = root.userReals.slice();
        n[index] = model.name; r[index] = model.realName;
        root.userNames = n; root.userReals = r;
        if (model.name === userModel.lastUser) root.userIndex = index;
      }
    }
  }
  Repeater {
    model: sessionModel
    delegate: Item {
      Component.onCompleted: {
        var n = root.sessionNames.slice();
        n[index] = model.name;
        root.sessionNames = n;
      }
    }
  }
  Component.onCompleted: {
    if (sessionModel.lastIndex >= 0) sessionIndex = sessionModel.lastIndex;
  }

  function nextUser() { if (busy || userCount < 2) return; userIndex = (userIndex + 1) % userCount; text = ""; error = ""; poke(); }
  function nextSession() { if (busy || sessionCount < 2) return; sessionIndex = (sessionIndex + 1) % sessionCount; poke(); }

  function open() { authing = true; idle.restart(); }
  function poke() { if (authing) idle.restart(); }
  function back() { if (busy) return; authing = false; text = ""; error = ""; idle.stop(); }
  function type(ch) {
    if (busy) return;
    open(); error = ""; text += ch;
    if (pin && Config.pinLength > 0 && text.length >= Config.pinLength) submit();
  }
  function backspace() { if (busy) return; open(); error = ""; text = text.slice(0, -1); }
  function clear() { if (busy) return; text = ""; error = ""; }
  function submit() {
    if (busy || text === "" || userName === "") return;
    error = ""; busy = true; idle.restart();
    sddm.login(userName, text, sessionIndex);
  }

  Connections {
    target: sddm
    function onLoginFailed() {
      root.busy = false;
      root.error = root.pin ? "Wrong PIN" : "Wrong password";
      root.text = "";
      root.shake++;
    }
    function onLoginSucceeded() { root.error = ""; }
  }
  Timer { id: idle; interval: Math.max(5, Config.idleTimeout) * 1000; onTriggered: root.back() }
}
