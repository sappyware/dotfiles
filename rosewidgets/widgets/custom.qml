
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property var theme: ({})
    property var options: ({})

    implicitWidth: 300
    implicitHeight: 180

    Process {
        id: launch

        command: [
            "/usr/bin/kitty",
            "--title", "pipes-widget",
            "bash", "-lc",
            "exec pipes.sh"
        ]
    }

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: "#1d2021"
        border.width: 1
        border.color: "#504945"

        Column {
            anchors.centerIn: parent
            spacing: 12

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8

                Rectangle {
                    width: 9
                    height: 9
                    radius: 5
                    color: "#fe8019"
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "pipes.sh"
                    color: "#ebdbb2"
                    font.family: "monospace"
                    font.pixelSize: 17
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "terminal animation"
                color: "#a89984"
                font.family: "monospace"
                font.pixelSize: 11
            }

            Rectangle {
                width: 112
                height: 36
                radius: 7
                color: launch.running ? "#504945" : "#fe8019"
                anchors.horizontalCenter: parent.horizontalCenter

                Text {
                    anchors.centerIn: parent
                    text: launch.running ? "launching..." : "run pipes"
                    color: launch.running ? "#ebdbb2" : "#282828"
                    font.family: "monospace"
                    font.pixelSize: 12
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: !launch.running
                    cursorShape: Qt.PointingHandCursor

                    onClicked: launch.running = true
                }
            }
        }
    }
}
