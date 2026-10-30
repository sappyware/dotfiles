import QtQuick 2.15

// Outlined pill with a colored dot; fills with its tone on hover.
Item {
    id: btn
    property string label: ""
    property string fontName: "Inter"
    property color tone: "#fb4934"
    signal clicked()

    width: row.implicitWidth + 40
    height: 42

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: area.containsMouse ? btn.tone : "#282828"
        border { width: 2; color: area.containsMouse ? btn.tone : "#504945" }
        scale: area.pressed ? 0.95 : 1
        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on scale { NumberAnimation { duration: 80 } }

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 10
            Rectangle {
                width: 9; height: 9; radius: 4.5
                anchors.verticalCenter: parent.verticalCenter
                color: area.containsMouse ? "#1d2021" : btn.tone
            }
            Text {
                text: btn.label
                color: area.containsMouse ? "#1d2021" : "#ebdbb2"
                font { family: btn.fontName; pixelSize: 15; weight: Font.ExtraBold }
            }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.clicked()
    }
}