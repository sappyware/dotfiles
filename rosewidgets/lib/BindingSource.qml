import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick

Item {
    id: root

    property string name: ""
    property var spec: ({})
    property var data: ({})

    readonly property string source: spec.source ?? ""

    // ── Clock ─────────────────────────────────────────────────────────
    Timer {
        running: root.source === "clock"
        interval: root.spec.interval_ms ?? 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.tickClock()
    }

    function tickClock() {
        const d = new Date()
        const pad = n => String(n).padStart(2, "0")
        data = {
            time_hhmm:   pad(d.getHours()) + ":" + pad(d.getMinutes()),
            time_hhmmss: pad(d.getHours()) + ":" + pad(d.getMinutes()) + ":" + pad(d.getSeconds()),
            date_long:   d.toLocaleDateString([], { weekday: "long", month: "long", day: "numeric" }),
            date_short:  d.toLocaleDateString([], { month: "short", day: "numeric" }),
            day:         d.getDate(),
            month:       d.toLocaleDateString([], { month: "long" }),
            year:        d.getFullYear(),
            hour:        d.getHours(),
            minute:      d.getMinutes(),
            second:      d.getSeconds(),
            weekday:     d.toLocaleDateString([], { weekday: "long" })
        }
    }

    // ── HTTP ──────────────────────────────────────────────────────────
    Timer {
        running: root.source === "http"
        interval: root.spec.interval_ms ?? 1800000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.fetchHttp()
    }

    function fetchHttp() {
        const xhr = new XMLHttpRequest()
        xhr.onreadystatechange = () => {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                try { root.data = JSON.parse(xhr.responseText) }
                catch (e) { console.warn("[roseforge] http parse:", e.message) }
            }
        }
        xhr.open("GET", root.spec.url)
        xhr.send()
    }

    // ── Exec ──────────────────────────────────────────────────────────
    Timer {
        running: root.source === "exec"
        interval: root.spec.interval_ms ?? 5000
        repeat: true
        triggeredOnStart: true
        onTriggered: execProc.running = true
    }

    Process {
        id: execProc
        command: root.spec.command ?? ["true"]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = text.trim()
                if (root.spec.parse === "json") {
                    try { root.data = JSON.parse(t) }
                    catch (e) { root.data = { output: t, error: e.message } }
                } else {
                    root.data = { output: t }
                }
            }
        }
    }

    // ── MPRIS ─────────────────────────────────────────────────────────
    readonly property var mprisPlayer: {
        if (root.source !== "mpris") return null
        const p = Mpris.players
        if (!p) return null
        const vals = p.values ?? p
        if (!vals || vals.length === undefined) return null
        return vals.length > 0 ? vals[0] : null
    }

    onMprisPlayerChanged: updateMpris()
    Component.onCompleted: if (root.source === "mpris") updateMpris()

    Connections {
        target: root.mprisPlayer
        function onTrackTitleChanged()  { root.updateMpris() }
        function onTrackArtistChanged() { root.updateMpris() }
        function onTrackAlbumChanged()  { root.updateMpris() }
        function onTrackArtUrlChanged() { root.updateMpris() }
        function onIsPlayingChanged()   { root.updateMpris() }
    }

    function updateMpris() {
        const p = root.mprisPlayer
        data = p ? {
            title:   p.trackTitle  ?? "",
            artist:  p.trackArtist ?? "",
            album:   p.trackAlbum  ?? "",
            art_url: p.trackArtUrl ?? "",
            playing: p.isPlaying   ?? false
        } : {
            title:   "Nothing playing",
            artist:  "",
            album:   "",
            art_url: "",
            playing: false
        }
    }
}
