pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
    id: root

    property var raw: ({})

    readonly property string configPath:
        Quickshell.env("ROSEWIDGETS_CONFIG") ||
        ((Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config"))
            + "/rosewidgets/config.toml")

    readonly property string helperPath: {
        const base = Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")
        return base + "/rosewidgets/lib/parse-toml.py"
    }

    readonly property var appearance: raw.appearance ?? ({})
    readonly property var animations: raw.animations ?? ({})
    readonly property var theme:      raw.theme      ?? ({})
    readonly property var font:       raw.font       ?? ({})
    readonly property var paths:      raw.paths      ?? ({})

    property Process _loaderProcess: Process {
        id: _process
        command: ["python3", root.helperPath, root.configPath]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const t = text.trim()
                if (!t) return
                try { root.raw = JSON.parse(t) }
                catch (e) { console.warn("[roseforge] config parse:", e.message) }
            }
        }
    }
}
