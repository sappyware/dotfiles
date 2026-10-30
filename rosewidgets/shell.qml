import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import "lib"

ShellRoot {
    id: root

    readonly property var manifest: [
        { id: "clock",         file: "clock.jsonc" },
        { id: "weather",       file: "weather.jsonc" },
        { id: "media",         file: "media.jsonc" },
        { id: "quicksettings", file: "quicksettings.jsonc" }
    ]

    PanelWindow {
        id: panel

        anchors { top: true; bottom: true; left: true; right: true }
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        // Input region: clicks inside this box reach the widgets;
        // everything else passes through to the apps below.
        // Enlarge it if you drag a card outside the default box.
        mask: Region { x: 0; y: 0; width: 1400; height: 900 }

        Item {
            id: canvas
            anchors.fill: parent

            Repeater {
                model: root.manifest.length
                delegate: WidgetHost { manifest: root.manifest[index] }
            }
        }
    }
}
