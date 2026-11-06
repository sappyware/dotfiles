import QtQuick

Item {
  id: root
  required property var ctx
  property real unit: 800
  readonly property bool pin: Config.input === "pin"
  readonly property bool pad: Config.keypad
  readonly property real key: Math.max(52, Math.min(80, unit * 0.095))
  readonly property real fieldW: pin ? Math.max(dots.implicitWidth, 200) : 380
  width: pad ? Math.max(3 * key + 28, fieldW) : fieldW
  height: col.implicitHeight

  Column {
    id: col
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: 16

    MdShape {
      anchors.horizontalCenter: parent.horizontalCenter
      width: 64; height: 64
      kind: root.ctx.error !== "" ? "pebble" : (root.ctx.busy ? "sunny" : "cookie")
      color: root.ctx.error !== "" ? Theme.s.errorContainer : Theme.s.primaryContainer
      Icon {
        anchors.centerIn: parent; width: 30; height: 30; kind: "lock"
        color: root.ctx.error !== "" ? Theme.s.onErrorContainer : Theme.s.onPrimaryContainer
      }
    }
    Tx {
      anchors.horizontalCenter: parent.horizontalCenter
      role: "titleMedium"
      color: root.ctx.error !== "" ? Theme.s.error : Theme.s.onSurface
      text: root.ctx.busy ? "Checking\u2026" : (root.ctx.error !== "" ? root.ctx.error : (root.ctx.caps ? "Caps Lock is on" : (root.pin ? "Enter PIN" : "Enter password")))
    }
    Item {
      id: entry
      anchors.horizontalCenter: parent.horizontalCenter
      width: root.pin ? dots.implicitWidth : field.width
      height: root.pin ? 28 : field.height
      transform: Translate { id: tr }
      PinDots { id: dots; visible: root.pin; ctx: root.ctx; anchors.centerIn: parent }
      PasswordField { id: field; visible: !root.pin; ctx: root.ctx }
    }
    Item { visible: root.pad; width: 1; height: 6 }
    PinPad { visible: root.pad; anchors.horizontalCenter: parent.horizontalCenter; ctx: root.ctx; key: root.key }
    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 10
      Chip { visible: root.ctx.userName !== ""; text: root.ctx.userLabel; clickable: root.ctx.userCount > 1; onClicked: root.ctx.nextUser() }
      Chip { visible: root.ctx.sessionLabel !== ""; text: root.ctx.sessionLabel; clickable: root.ctx.sessionCount > 1; onClicked: root.ctx.nextSession() }
    }
  }

  SequentialAnimation {
    id: shk
    NumberAnimation { target: tr; property: "x"; to: -16; duration: 55 }
    NumberAnimation { target: tr; property: "x"; to: 14; duration: 70 }
    NumberAnimation { target: tr; property: "x"; to: -10; duration: 70 }
    NumberAnimation { target: tr; property: "x"; to: 6; duration: 60 }
    NumberAnimation { target: tr; property: "x"; to: 0; duration: 60 }
  }
  Connections { target: root.ctx; function onShakeChanged() { shk.restart(); } }
}
