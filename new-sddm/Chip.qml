import QtQuick

Item {
  id: root
  property string text: ""
  property bool clickable: true
  signal clicked()
  width: lbl.implicitWidth + 36; height: 34
  scale: ma.pressed ? 0.95 : 1
  Behavior on scale { SpringAnimation { spring: 5; damping: 0.3; epsilon: 0.002 } }

  MdShape { anchors.fill: parent; kind: "pill"; color: Qt.alpha(Theme.s.surfaceContainerHigh, 0.85) }
  Tx { id: lbl; anchors.centerIn: parent; role: "labelLarge"; text: root.text }
  MouseArea { id: ma; anchors.fill: parent; enabled: root.clickable; onClicked: root.clicked() }
}
