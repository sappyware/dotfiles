import Quickshell
import Quickshell.Io
import QtQuick
import "."
import "Jsonc.js" as Jsonc

Item {
    id: root

    required property var manifest
    property var widget: null
    property var bindings: ({})

    readonly property string widgetsDir:
        (Config.paths.widgets_dir ?? "~/.config/rosewidgets/widgets")
            .replace("~", Quickshell.env("HOME"))

    FileView {
        id: fileView
        path: root.widgetsDir + "/" + root.manifest.file
        watchChanges: true
        onLoaded:      root.parseWidget(fileView.text)
        onFileChanged: root.parseWidget(fileView.text)
    }

    function parseWidget(raw) {
        if (!raw) return
        try {
            const parsed = JSON.parse(Jsonc.strip(raw))
            parsed.id = parsed.id ?? root.manifest.id
            root.widget = parsed
            root.initBindings()
            const fb = { x: parsed.position?.x ?? 40, y: parsed.position?.y ?? 40 }
            const saved = Positions.position(parsed.id, fb)
            root.x = saved.x
            root.y = saved.y
        } catch (e) {
            console.warn("[roseforge] widget parse:", root.manifest.file, e.message)
        }
    }

    function initBindings() {
        if (!widget) return
        // Destroy old binding sources so saves don't leak.
        for (const name in bindings) {
            const b = bindings[name]
            if (b && b.destroy) b.destroy()
        }
        const next = {}
        const specs = widget.data ?? {}
        for (const name in specs) {
            const comp = Qt.createComponent(Qt.resolvedUrl("BindingSource.qml"))
            if (comp.status === Component.Ready) {
                const src = comp.createObject(root, { name: name, spec: specs[name] })
                if (src) next[name] = src
            } else if (comp.status === Component.Error) {
                console.warn("[roseforge] BindingSource:", comp.errorString())
            }
        }
        // Reassign to trigger the `context` binding.
        bindings = next
    }

    readonly property var context: {
        const ctx = { theme: Theme, config: Config }
        for (const name in bindings) {
            ctx[name] = bindings[name].data
        }
        return ctx
    }

    width: card.implicitWidth
    height: card.implicitHeight
    opacity: 0

    Card {
        id: card
        widget: root.widget
        ctx: root.context
        anchors.fill: parent
    }

    MouseArea {
        id: dragArea
        anchors.fill: parent
        drag.target: root
        drag.axis: Drag.XAndYAxis
        drag.minimumX: 0
        drag.minimumY: 0
        drag.maximumX: parent ? parent.width  - root.width  : 99999
        drag.maximumY: parent ? parent.height - root.height : 99999
        cursorShape: Qt.ClosedHandCursor
        onReleased: {
            if (root.widget) Positions.save(root.widget.id, root.x, root.y)
        }
    }

    Component.onCompleted: fadeIn.start()

    NumberAnimation {
        id: fadeIn
        target: root
        property: "opacity"
        to: 1
        duration: Theme.animEnabled ? Theme.animDuration : 0
        easing.type: "OutCubic"
    }
}
