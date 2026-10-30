import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import "Expr.js" as Expr
import "."

// Recursive renderer for the widget's layout tree.
// Recursion uses Loader{source: Qt.resolvedUrl(...)} to break the
// compile-time cycle that direct WidgetLayout{...} would create.
Item {
    id: wl

    property var node: null
    property var ctx: ({})

    implicitWidth:  loader.item ? (loader.item.implicitWidth  || 0) : 0
    implicitHeight: loader.item ? (loader.item.implicitHeight || 0) : 0

    Loader {
        id: loader
        sourceComponent: {
            if (!wl.node) return null
            if (wl.node.if !== undefined) {
                const v = Expr.evalValue("{" + wl.node.if + "}", wl.ctx)
                if (v !== "true" && v !== "1") return null
            }
            switch (wl.node.type) {
                case "column":   return colComp
                case "row":      return rowComp
                case "text":     return textComp
                case "icon":     return iconComp
                case "button":   return buttonComp
                case "image":    return imageComp
                case "spacer":   return spacerComp
                case "divider":  return dividerComp
                case "progress": return progressComp
                default:         return null
            }
        }
    }

    // Keep the loaded item's node/ctx reactive when wl.node or wl.ctx change.
    Binding {
        target: loader.item
        property: "node"
        value: wl.node
        when: loader.item !== null
        restoreMode: Binding.RestoreNone
    }
    Binding {
        target: loader.item
        property: "ctx"
        value: wl.ctx
        when: loader.item !== null
        restoreMode: Binding.RestoreNone
    }

    // ── Containers ─────────────────────────────────────────────────────
    Component {
        id: colComp
        Column {
            id: col
            property var node
            property var ctx
            spacing: node?.spacing ?? 8
            Repeater {
                model: node?.children ?? []
                delegate: Loader {
                    id: childColLoader
                    property var childNode: modelData
                    property var childCtx: col.ctx
                    source: Qt.resolvedUrl("WidgetLayout.qml")
                    Binding {
                        target: childColLoader.item
                        property: "node"
                        value: childColLoader.childNode
                        when: childColLoader.item !== null
                        restoreMode: Binding.RestoreNone
                    }
                    Binding {
                        target: childColLoader.item
                        property: "ctx"
                        value: childColLoader.childCtx
                        when: childColLoader.item !== null
                        restoreMode: Binding.RestoreNone
                    }
                }
            }
        }
    }

    Component {
        id: rowComp
        Row {
            id: row
            property var node
            property var ctx
            spacing: node?.spacing ?? 8
            Repeater {
                model: node?.children ?? []
                delegate: Loader {
                    id: childRowLoader
                    property var childNode: modelData
                    property var childCtx: row.ctx
                    source: Qt.resolvedUrl("WidgetLayout.qml")
                    Binding {
                        target: childRowLoader.item
                        property: "node"
                        value: childRowLoader.childNode
                        when: childRowLoader.item !== null
                        restoreMode: Binding.RestoreNone
                    }
                    Binding {
                        target: childRowLoader.item
                        property: "ctx"
                        value: childRowLoader.childCtx
                        when: childRowLoader.item !== null
                        restoreMode: Binding.RestoreNone
                    }
                }
            }
        }
    }

    // ── Leaves ─────────────────────────────────────────────────────────
    Component {
        id: textComp
        Text {
            property var node
            property var ctx
            text: Expr.evalValue(node?.value ?? "", ctx)
            color: Expr.evalColor(node?.color ?? "@fg", Theme)
            font.family: Theme.fontFamily
            font.pixelSize: node?.size ?? Theme.sizeBody
            font.bold: node?.weight === "bold"
            wrapMode: Text.WordWrap
            maximumLineCount: node?.max_lines ?? 99
            elide: Text.ElideRight
        }
    }

    Component {
        id: iconComp
        Text {
            property var node
            property var ctx
            text: Expr.evalValue(node?.value ?? "", ctx)
            color: Expr.evalColor(node?.color ?? "@fg", Theme)
            font.family: Theme.fontFamily
            font.pixelSize: node?.size ?? Theme.sizeBody
        }
    }

    Component {
        id: imageComp
        Rectangle {
            property var node
            property var ctx
            implicitWidth:  node?.size ?? 64
            implicitHeight: node?.size ?? 64
            radius: node?.radius ?? 8
            color: "transparent"
            clip: true
            Image {
                anchors.fill: parent
                source: Expr.evalValue(node?.source ?? "", ctx)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }
    }

    Component {
        id: spacerComp
        Item {
            property var node
            property var ctx
            implicitWidth:  node?.w ?? 0
            implicitHeight: node?.h ?? 0
        }
    }

    Component {
        id: dividerComp
        Rectangle {
            property var node
            property var ctx
            implicitWidth:  node?.w ?? 200
            implicitHeight: 1
            color: Theme.border
        }
    }

    Component {
        id: progressComp
        Item {
            property var node
            property var ctx
            implicitWidth:  node?.w ?? 180
            implicitHeight: 8

            readonly property real frac: {
                const raw = Number(Expr.evalValue("{" + (node?.value ?? "0") + "}", ctx))
                return Math.min(1, Math.max(0, isNaN(raw) ? 0 : raw))
            }

            Rectangle { anchors.fill: parent; radius: 4; color: Theme.border }
            Rectangle {
                width: parent.width * parent.frac
                height: parent.height
                radius: 4
                color: Expr.evalColor(node?.color ?? "@accent", Theme)
            }
        }
    }

    Component {
        id: buttonComp
        Rectangle {
            id: btn
            property var node
            property var ctx
            implicitWidth:  btnLabel.implicitWidth + 20
            implicitHeight: btnLabel.implicitHeight + 12
            radius: 8
            color: btnArea.containsMouse ? Qt.lighter(Theme.bg, 1.3) : "transparent"
            border.color: Theme.border
            border.width: 1

            Text {
                id: btnLabel
                anchors.centerIn: parent
                text: Expr.evalValue(btn.node?.value ?? "", btn.ctx)
                color: Expr.evalColor(btn.node?.color ?? "@fg", Theme)
                font.family: Theme.fontFamily
                font.pixelSize: btn.node?.size ?? Theme.sizeBody
                font.bold: btn.node?.weight === "bold"
            }

            MouseArea {
                id: btnArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (btn.node?.run) wl.runCommand(btn.node.run)
                    else if (btn.node?.action) wl.dispatchAction(btn.node.action)
                }
            }
        }
    }

    // ── Actions ────────────────────────────────────────────────────────
    function runCommand(cmd) {
        if (Array.isArray(cmd))
            Quickshell.execDetached(cmd)
        else if (typeof cmd === "string")
            Quickshell.execDetached(["sh", "-c", cmd])
    }

    function dispatchAction(action) {
        const p = Mpris.players
        const vals = p && (p.values ?? p)
        const player = vals && vals.length > 0 ? vals[0] : null
        switch (action) {
            case "media.toggle": player?.togglePlaying(); break
            case "media.next":   player?.next();          break
            case "media.prev":   player?.previous();      break
            case "volume.up":    Quickshell.execDetached(["sh", "-c", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"]); break
            case "volume.down":  Quickshell.execDetached(["sh", "-c", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"]); break
            case "volume.mute":  Quickshell.execDetached(["sh", "-c", "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"]); break
            default:             console.warn("[roseforge] unknown action:", action)
        }
    }
}
