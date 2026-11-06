import QtQuick

Grid {
  id: root
  required property var ctx
  property real key: 76
  columns: 3
  spacing: 14
  Repeater {
    model: ["1", "2", "3", "4", "5", "6", "7", "8", "9", "bs", "0", "ok"]
    MdButton {
      required property string modelData
      readonly property bool isBs: modelData === "bs"
      readonly property bool isOk: modelData === "ok"
      width: root.key; height: root.key
      shape: "circle"; pressedShape: isOk ? "cookie" : "squircle"
      bg: isOk ? Theme.s.primary : (isBs ? Theme.s.secondaryContainer : Qt.alpha(Theme.s.surfaceContainerHighest, 0.92))
      fg: isOk ? Theme.s.onPrimary : (isBs ? Theme.s.onSecondaryContainer : Theme.s.onSurface)
      label: (isBs || isOk) ? "" : modelData
      icon: isBs ? "backspace" : (isOk ? "enter" : "")
      glyphSize: root.key * 0.42; iconSize: root.key * 0.36
      onClicked: { if (isBs) root.ctx.backspace(); else if (isOk) root.ctx.submit(); else root.ctx.type(modelData); }
    }
  }
}
