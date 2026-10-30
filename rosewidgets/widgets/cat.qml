
import QtQuick

Item {
    id: root

    property var theme: ({})
    property var options: ({})

    implicitWidth: 180
    implicitHeight: 140

    AnimatedImage {
        anchors.fill: parent
        source: Qt.resolvedUrl("cat.gif")
        fillMode: Image.PreserveAspectFit
        playing: root.visible
        speed: 1.0
        cache: false
    }
}
