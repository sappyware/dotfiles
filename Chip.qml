import QtQuick 2.15

// Selectable pill used for users and sessions.
Item {
    id: chip
    property string label: ""
    property string fontName: "Inter"
    property color accent: "#83a598"
    property bool selected: false
    signal clicked()

    width: txt.implicitWidth + 30
    height: 36

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: chip.selected ? chip.accent : (area.containsMouse ? "#3c3836" : "#282828")
        border { width: 2; color: chip.selected ? chip.accent : (area.containsMouse ? "#665c54" : "#504945") }
        Behavior on color { ColorAnimation { duration: 120 } }

        Text {
            id: txt
            anchors.centerIn: parent
            text: chip.label
            color: chip.selected ? "#1d2021" : "#ebdbb2"
            font { family: chip.fontName; pixelSize: 14; weight: chip.selected ? Font.Black : Font.Bold }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: chip.clicked()
    }
}