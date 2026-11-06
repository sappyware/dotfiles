import QtQuick

Item {
  id: root
  required property var ctx
  width: 380; height: 58

  MdShape { anchors.fill: parent; kind: "pill"; color: Qt.alpha(Theme.s.surfaceContainerHigh, 0.92); strokeWidth: 2; strokeColor: Theme.s.primary }
  Tx {
    visible: root.ctx.text.length === 0
    anchors { left: parent.left; leftMargin: 26; verticalCenter: parent.verticalCenter }
    role: "bodyLarge"; color: Theme.s.onSurfaceVariant; text: "Password"
  }
  Row {
    anchors { left: parent.left; leftMargin: 26; right: ok.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
    spacing: 8; clip: true; layoutDirection: Qt.LeftToRight
    Repeater {
      model: Math.min(24, root.ctx.text.length)
      Rectangle {
        width: 10; height: 10; radius: 5; color: Theme.s.onSurface
        scale: 0.2
        Component.onCompleted: scale = 1
        Behavior on scale { SpringAnimation { spring: 6; damping: 0.3; epsilon: 0.002 } }
      }
    }
  }
  MdButton {
    id: ok
    width: 46; height: 46
    anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
    shape: "circle"; pressedShape: "cookie"
    bg: Theme.s.primary; fg: Theme.s.onPrimary; icon: "enter"; iconSize: 22
    onClicked: root.ctx.submit()
  }
}
