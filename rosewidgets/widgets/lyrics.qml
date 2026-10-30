import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Item {
    id: root

    property var theme: ({})
    property var options: ({})

    // Polls for song changes so MPRIS that appears *after* startup,
    // or players that don't emit notify signals, still get picked up.
    Timer {
        interval: 250
        running: true
        repeat: true
        onTriggered: root.checkSongChange()
    }

    // Fast path when the player does emit signals.
    Connections {
        target: root.player
        enabled: target !== null
        function onTrackTitleChanged()  { root.checkSongChange() }
        function onTrackArtistChanged() { root.checkSongChange() }
        function onTrackAlbumChanged()  { root.checkSongChange() }
        function onMetadataChanged()    { root.checkSongChange() }
    }

    readonly property var player: {
        var players = Mpris.players.values
        for (var i = 0; i < players.length; i++)
            if (players[i].isPlaying) return players[i]
        return players.length > 0 ? players[0] : null
    }

    readonly property string title:  player ? (player.trackTitle  || "") : ""
    readonly property string artist: player ? (player.trackArtist || "") : ""
    readonly property string album:  player ? (player.trackAlbum  || "") : ""

    readonly property int dur:
        player && player.lengthSupported ? Math.round(player.length) : 0
    readonly property real pos:
        player && player.positionSupported ? player.position : 0
    readonly property real offset: Number(options.lyrics_offset) || 0
    readonly property bool showTitle: options.show_title !== false
    readonly property string align:
        options.text_align === "left" || options.text_align === "right"
            ? options.text_align : "center"

    readonly property color textColor:    Qt.color(theme.text    || "#ebdbb2")
    readonly property color subtextColor: Qt.color(theme.subtext || "#928374")
    readonly property color accentColor:  Qt.color(theme.accent  || "#83a598")

    readonly property var metadata: player && player.metadata ? player.metadata : ({})
    readonly property string trackUrl: metadataValue("xesam:url")
    readonly property string localPath: {
        var url = trackUrl
        if (!url.startsWith("file://")) return ""
        try { return decodeURIComponent(url.replace(/^file:\/\//, "")) }
        catch (e) { return "" }
    }
    readonly property string lrcPath: {
        if (localPath === "") return ""
        var slash = localPath.lastIndexOf("/")
        var dot = localPath.lastIndexOf(".")
        return dot > slash ? localPath.substring(0, dot) + ".lrc" : localPath + ".lrc"
    }

    property var lines: []
    property string status: "Nothing playing"
    property string reqKey: ""
    property int searchDropWords: 0
    property string searchQuery: ""
    property bool localLookupStarted: false
    property string lastKey: ""
    property bool refreshing: false

    // "normal"          -> local -> embedded -> LRCLIB exact -> progressive search
    // "refresh-online"  -> LRCLIB exact -> LRCLIB search -> local only
    property string loadMode: "normal"

    readonly property real rowH: 36
    readonly property int visibleRows: 5

    readonly property int idx: {
        var p = pos + offset
        var lo = 0, hi = lines.length - 1, result = -1
        while (lo <= hi) {
            var mid = (lo + hi) >> 1
            if (lines[mid].t <= p) { result = mid; lo = mid + 1 }
            else hi = mid - 1
        }
        return result
    }

    readonly property real scrollPos: {
        var i = idx
        if (i < 0) return 0
        if (i + 1 >= lines.length) return i
        var t = pos + offset
        var t0 = lines[i].t, t1 = lines[i + 1].t
        var window = Math.min((t1 - t0) * 0.5, 1.2)
        if (window <= 0 || t <= t1 - window) return i
        var f = Math.max(0, Math.min(1, (t - (t1 - window)) / window))
        f = f * f * (3 - 2 * f)
        return i + f
    }

    implicitWidth: 420
    implicitHeight: (showTitle ? 46 : 0) + visibleRows * rowH

    function metadataValue(name) {
        var v = metadata[name]
        return (v === undefined || v === null) ? "" : String(v)
    }

    function currentKey() {
        var p = player
        if (!p) return ""
        return (p.trackTitle || "") + "|" + (p.trackArtist || "") + "|" +
               (p.trackAlbum || "") + "|" + (p.uniqueId || -1)
    }

    function resetRefreshState() {
        refreshing = false
        loadMode = "normal"
    }

    function checkSongChange() {
        var k = currentKey()
        if (k === lastKey) return
        lastKey = k
        lines = []
        searchDropWords = 0
        localLookupStarted = false
        resetRefreshState()
        if (k === "") {
            status = "Nothing playing"
            reqKey = ""
            return
        }
        reqKey = k
        load()
    }

    function parseLyrics(input) {
        var out = [], plain = []
        var inputLines = String(input || "").split(/\r?\n/)
        var timestampFound = false
        for (var i = 0; i < inputLines.length; i++) {
            var rest = inputLines[i].trim(), tags = [], match
            if (/^\[(ar|al|ti|by|re|ve|length|offset|kana|la|tool|id|au):/i.test(rest)) continue
            while ((match = rest.match(/^\[(\d+):(\d+(?:\.\d+)?)\]/))) {
                tags.push(Number(match[1]) * 60 + Number(match[2]))
                rest = rest.slice(match[0].length)
            }
            var txt = rest.trim()
            if (tags.length > 0) {
                timestampFound = true
                for (var k = 0; k < tags.length; k++)
                    out.push({ t: tags[k], s: txt === "" ? "\u266A" : txt })
            } else if (txt !== "") {
                plain.push(txt)
            }
        }
        if (!timestampFound && plain.length > 0) {
            var duration = dur > 0 ? dur : plain.length * 3
            for (var j = 0; j < plain.length; j++)
                out.push({ t: j * duration / plain.length, s: plain[j] })
        }
        out.sort(function(a, b) { return a.t - b.t })
        return out
    }

    function applyText(text) {
        if (!text || String(text).trim() === "") return false
        var parsed = parseLyrics(text)
        if (parsed.length === 0) return false
        lines = parsed
        status = ""
        return true
    }

    function applyEmbeddedMetadata() {
        var keys = ["xesam:asText", "xesam:lyrics", "lyrics", "LYRICS", "UNSYNCEDLYRICS"]
        for (var i = 0; i < keys.length; i++) {
            var v = metadataValue(keys[i])
            if (v !== "" && applyText(v)) return true
        }
        return false
    }

    function args(url, withExtra, queryTitle) {
        var a = ["curl", "-sf", "-m", "10", "-A", "rosewidgets", "-G", url]
        if (queryTitle !== "") a.push("--data-urlencode", "track_name=" + queryTitle)
        if (artist !== "") a.push("--data-urlencode", "artist_name=" + artist)
        if (withExtra && album !== "") a.push("--data-urlencode", "album_name=" + album)
        if (withExtra && dur > 0) a.push("--data-urlencode", "duration=" + dur)
        return a
    }

    function searchTitle(dropWords) {
        var words = title.trim().split(/\s+/)
        if (title.trim() === "") return ""
        return words.slice(0, Math.max(0, words.length - dropWords)).join(" ")
    }

    function stopProcesses() {
        if (lrcProc.running) lrcProc.running = false
        if (metadataProc.running) metadataProc.running = false
        if (getProc.running) getProc.running = false
        if (searchProc.running) searchProc.running = false
    }

    // Normal pipeline: local first, then LRCLIB.
    function load() {
        debounce.stop()
        stopProcesses()
        lines = []
        searchDropWords = 0
        localLookupStarted = false
        reqKey = currentKey()
        if (title === "") {
            status = "Nothing playing"
            return
        }
        status = "Checking local lyrics..."
        if (lrcPath !== "") {
            localLookupStarted = true
            lrcProc.command = ["cat", lrcPath]
            lrcProc.running = true
        } else {
            checkEmbedded()
        }
    }

    // Click-with-lyrics-shown: LRCLIB first, local fallback if empty.
    function refresh() {
        if (refreshing || title === "") return
        stopProcesses()
        lines = []
        status = "Searching LRCLIB..."
        refreshing = true
        loadMode = "refresh-online"
        startExactSearch()
    }

    // refresh-online pipeline reached the end of LRCLIB with no hit.
    function tryLocalOnly() {
        status = "LRCLIB empty. Checking local..."
        if (lrcPath !== "") {
            lrcProc.command = ["cat", lrcPath]
            lrcProc.running = true
            return
        }
        tryLocalEmbedded()
    }

    function tryLocalEmbedded() {
        if (applyEmbeddedMetadata()) {
            resetRefreshState()
            return
        }
        if (localPath !== "") {
            metadataProc.command = ["ffprobe", "-v", "error", "-show_entries", "format_tags", "-of", "json", localPath]
            metadataProc.running = true
            return
        }
        status = "No lyrics found (online or local)"
        resetRefreshState()
    }

    function checkEmbedded() {
        if (reqKey !== currentKey()) return
        if (applyEmbeddedMetadata()) return
        if (localPath !== "") {
            status = "Checking embedded lyrics..."
            metadataProc.command = ["ffprobe", "-v", "error", "-show_entries", "format_tags", "-of", "json", localPath]
            metadataProc.running = true
        } else {
            startExactSearch()
        }
    }

    function startExactSearch() {
        if (reqKey !== currentKey()) return
        status = "Searching LRCLIB..."
        getProc.command = args("https://lrclib.net/api/get", true, title)
        getProc.running = true
    }

    function startSearch(query) {
        if (reqKey !== currentKey() || query === "") {
            status = "No broader search available"
            return
        }
        searchQuery = query
        status = 'Searching "' + query + '"...'
        searchProc.command = args("https://lrclib.net/api/search", false, query)
        searchProc.running = true
    }

    function retrySearch() {
        if (refreshing || title === "" || lines.length > 0) return
        if (lrcProc.running || metadataProc.running || getProc.running || searchProc.running) return
        searchDropWords++
        var query = searchTitle(searchDropWords)
        if (query === "" && artist !== "") {
            searchQuery = ""
            status = "Searching by artist..."
            searchProc.command = args("https://lrclib.net/api/search", false, "")
            searchProc.running = true
            return
        }
        startSearch(query)
    }

    function acceptSearchResults(results) {
        var best = null, bestDifference = 1e9
        if (!Array.isArray(results)) return false
        for (var i = 0; i < results.length; i++) {
            var item = results[i]
            if (!item.syncedLyrics) continue
            var difference = dur > 0 && item.duration ? Math.abs(item.duration - dur) : 0
            if (difference < bestDifference) { bestDifference = difference; best = item }
        }
        return !!(best && applyText(best.syncedLyrics))
    }

    Component.onCompleted: checkSongChange()

    FrameAnimation {
        running: root.player !== null && root.player.isPlaying && root.lines.length > 0
        onTriggered: {
            if (root.player && root.player.positionSupported)
                root.player.positionChanged()
        }
    }

    Timer {
        id: debounce
        interval: 350
        repeat: false
        onTriggered: root.startExactSearch()
    }

    Process {
        id: lrcProc
        stdout: StdioCollector {
            onStreamFinished: {
                if (root.reqKey !== root.currentKey()) return
                if (root.applyText(text)) {
                    root.resetRefreshState()
                    return
                }
                if (root.loadMode === "refresh-online") root.tryLocalEmbedded()
                else root.checkEmbedded()
            }
        }
    }

    Process {
        id: metadataProc
        stdout: StdioCollector {
            onStreamFinished: {
                if (root.reqKey !== root.currentKey()) return
                var found = false
                try {
                    var r = JSON.parse(text)
                    var tags = r.format ? r.format.tags || {} : {}
                    for (var name in tags) {
                        if (/^(lyrics|unsyncedlyrics|syncedlyrics|uslt|sylt)$/i.test(name)) {
                            if (root.applyText(tags[name])) { found = true; break }
                        }
                    }
                } catch (e) {}
                if (found) {
                    root.resetRefreshState()
                    return
                }
                if (root.loadMode === "refresh-online") {
                    root.status = "No lyrics found (online or local)"
                    root.resetRefreshState()
                } else {
                    root.startExactSearch()
                }
            }
        }
    }

    Process {
        id: getProc
        stdout: StdioCollector {
            onStreamFinished: {
                if (root.reqKey !== root.currentKey()) return
                var found = false, instrumental = false
                try {
                    var r = JSON.parse(text)
                    if (r.instrumental) instrumental = true
                    else found = root.applyText(r.syncedLyrics)
                } catch (e) {}
                if (instrumental) {
                    root.status = "Instrumental"
                    root.resetRefreshState()
                    return
                }
                if (found) {
                    root.resetRefreshState()
                    return
                }
                // Exact endpoint empty — try the search endpoint.
                root.startSearch(root.title)
            }
        }
    }

    Process {
        id: searchProc
        stdout: StdioCollector {
            onStreamFinished: {
                if (root.reqKey !== root.currentKey()) return
                var found = false
                try { found = root.acceptSearchResults(JSON.parse(text)) } catch (e) {}
                if (found) {
                    root.resetRefreshState()
                    return
                }
                if (root.loadMode === "refresh-online") {
                    // Both LRCLIB endpoints exhausted — try local.
                    root.tryLocalOnly()
                    return
                }
                root.status = "No results. Click to broaden search."
            }
        }
    }

    // Background click:
    //   lyrics shown     -> refresh (LRCLIB first, local fallback)
    //   lyrics not shown -> broaden search
    MouseArea {
        anchors.fill: parent
        z: 0
        onClicked: {
            if (root.lines.length > 0) root.refresh()
            else root.retrySearch()
        }
    }

    Column {
        visible: root.showTitle
        width: parent.width
        height: 46
        spacing: 1
        Text {
            width: parent.width
            text: root.title || "Lyrics"
            color: root.textColor
            elide: Text.ElideRight
            font.pixelSize: 15
            font.weight: Font.DemiBold
            font.family: root.theme.font || "sans-serif"
        }
        Text {
            width: parent.width
            text: root.artist
            color: root.subtextColor
            elide: Text.ElideRight
            font.pixelSize: 12
            font.family: root.theme.font || "sans-serif"
        }
    }

    Item {
        id: body
        y: root.showTitle ? 46 : 0
        width: parent.width
        height: root.visibleRows * root.rowH

        Text {
            anchors.centerIn: parent
            width: parent.width - 20
            visible: root.lines.length === 0
            text: root.status
            color: root.refreshing ? root.accentColor : root.subtextColor
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            font.pixelSize: 14
            font.family: root.theme.font || "sans-serif"
            Behavior on color { ColorAnimation { duration: 200 } }
        }

        Item {
            id: list
            visible: root.lines.length > 0
            anchors.fill: parent
            clip: true

            Item {
                id: column
                width: parent.width
                height: root.lines.length * root.rowH
                y: (list.height - root.rowH) / 2 - root.scrollPos * root.rowH

                Repeater {
                    model: root.lines
                    Item {
                        id: lyricRow
                        required property var modelData
                        required property int index
                        y: index * root.rowH
                        width: column.width
                        height: root.rowH

                        Text {
                            anchors {
                                fill: parent
                                leftMargin: root.align === "left" ? 14 : 4
                                rightMargin: root.align === "right" ? 14 : 4
                            }
                            horizontalAlignment:
                                root.align === "left" ? Text.AlignLeft :
                                root.align === "right" ? Text.AlignRight : Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            text: lyricRow.modelData.s
                            elide: Text.ElideRight
                            font.family: root.theme.font || "sans-serif"
                            font.pixelSize: 16
                            font.weight: lyricRow.index === root.idx ? Font.DemiBold : Font.Normal
                            color: lyricRow.index === root.idx ? root.accentColor : root.subtextColor
                            opacity: lyricRow.index === root.idx ? 1.0 : 0.38
                            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (root.player && root.player.canSeek)
                                    root.player.position = Math.max(0, lyricRow.modelData.t - root.offset)
                                else
                                    root.refresh()
                            }
                            onDoubleClicked: root.refresh()
                        }
                    }
                }
            }
        }
    }
}