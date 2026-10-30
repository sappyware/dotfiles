import QtQuick
import QtQuick.Effects
import "."

Item {
    id: root

    property var widget: null
    property var ctx: ({})

    readonly property int  pad:    widget?.layout?.padding ?? 20
    readonly property real radius: Theme.radius

    implicitWidth:  (layout.item ? layout.item.implicitWidth  : 0) + 2 * pad
    implicitHeight: (layout.item ? layout.item.implicitHeight : 0) + 2 * pad

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: root.radius
        color: Theme.glass
            ? Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, Theme.glassAlpha)
            : Theme.bg
        border.color: Theme.border
        border.width: 1

        layer.enabled: Theme.shadow
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#00000055"
            shadowBlur: 0.6
            shadowVerticalOffset: 4
        }
    }

    Loader {
        id: layout
        anchors.centerIn: parent
        sourceComponent: layoutComp
    }

    Component {
        id: layoutComp
        WidgetLayout {
            node: root.widget?.layout
            ctx: root.ctx
        }
    }
}
