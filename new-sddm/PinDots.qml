import QtQuick

Item {
  id: root
  required property var ctx
  readonly property int count: Math.min(14, Math.max(ctx.text.length, Config.pinLength))
  implicitWidth: Math.max(row.implicitWidth, 20)
  implicitHeight: 24

  Row {
    id: row
    anchors.centerIn: parent
    spacing: 12
    Repeater {
      model: root.count
      Rectangle {
        required property int index
        readonly property bool filled: index < root.ctx.text.length
        width: 14; height: 14; radius: 7
        color: filled ? Theme.s.primary : "transparent"
        border.width: 2; border.color: filled ? Theme.s.primary : Theme.s.outline
        scale: filled ? 1 : 0.8
        Behavior on scale { SpringAnimation { spring: 6; damping: 0.3; epsilon: 0.002 } }
        Behavior on color { ColorAnimation { duration: 120 } }
      }
    }
  }
}
