import QtQuick

Item {
  property var theme: ({})
  property var options: ({})
  implicitWidth: 200
  implicitHeight: 40
  Text {
    anchors.centerIn: parent
    text: "Hello, " + (options.name || "world")
    color: theme.text; font.pixelSize: 20; font.family: theme.font
  }
}
