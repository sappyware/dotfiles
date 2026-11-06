import QtQuick

Text {
  property string role: "bodyMedium"
  property real px: 0
  readonly property var ty: Theme.typeScale[role]
  font.family: Config.font
  font.pixelSize: px > 0 ? px : ty.size
  font.weight: ty.weight
  font.letterSpacing: ty.ls
  color: Theme.s.onSurface
}
