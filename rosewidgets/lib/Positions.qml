pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
    id: root

    readonly property string dir:
        (Config.paths.state_dir ?? "~/.local/state/rosewidgets")
            .replace("~", Quickshell.env("HOME"))
    readonly property string file: dir + "/positions.json"

    property var data: ({})

    function position(id, fallback) {
        const p = data[id]
        return p ? Qt.point(p.x, p.y) : fallback
    }

    function save(id, x, y) {
        const next = Object.assign({}, data)
        next[id] = { x: Math.round(x), y: Math.round(y) }
        data = next
        const content = JSON.stringify(next, null, 2)
        const script =
            "mkdir -p '" + dir + "' && cat > '" + file + "' <<'RWJSON'\n" +
            content + "\nRWJSON"
        Quickshell.execDetached(["sh", "-c", script])
    }

    property Process _readerProcess: Process {
        id: _reader
        command: ["cat", root.file]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const t = text.trim()
                if (!t) { root.data = ({}); return }
                try { root.data = JSON.parse(t) || ({}) }
                catch (e) { root.data = ({}) }
            }
        }
    }
}
