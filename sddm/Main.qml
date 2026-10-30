import QtQuick 2.15

// Gruvbox Dark Hard / Aqua: bold typographic SDDM login (Inter)
// Core QtQuick only, works on Qt5 and Qt6 greeters.

Rectangle {
    id: root
    width: 1280
    height: 800
    color: gruvbox.bg
    clip: true

    // ------------------------------------------------------------------ palette
    // Gruvbox Dark Hard (semantic names from your palette)
    QtObject {
        id: gruvbox

        // backgrounds
        readonly property color dark0_hard: "#1d2021"
        readonly property color dark0:      "#282828"
        readonly property color dark0_soft: "#32302f"
        readonly property color dark1:      "#3c3836"
        readonly property color dark2:      "#504945"
        readonly property color dark3:      "#665c54"
        readonly property color dark4:      "#7c6f64"

        // foregrounds
        readonly property color light0_hard: "#f9f5d7"
        readonly property color light0:      "#fbf1c7"
        readonly property color light0_soft: "#f2e5bc"
        readonly property color light1:      "#ebdbb2"
        readonly property color light2:      "#d5c4a1"
        readonly property color light3:      "#bdae93"
        readonly property color light4:      "#a89984"
        readonly property color gray:        "#928374"

        // neutral colors
        readonly property color neutral_red:    "#cc241d"
        readonly property color neutral_green:  "#98971a"
        readonly property color neutral_yellow: "#d79921"
        readonly property color neutral_blue:   "#458588"
        readonly property color neutral_purple: "#b16286"
        readonly property color neutral_aqua:   "#689d6a"
        readonly property color neutral_orange: "#d65d0e"

        // bright colors
        readonly property color bright_red:    "#fb4934"
        readonly property color bright_green:  "#b8bb26"
        readonly property color bright_yellow: "#fabd2f"
        readonly property color bright_blue:   "#83a598"
        readonly property color bright_purple: "#d3869b"
        readonly property color bright_aqua:   "#8ec07c"
        readonly property color bright_orange: "#fe8019"

        // faded colors
        readonly property color faded_red:    "#9d0006"
        readonly property color faded_green:  "#79740e"
        readonly property color faded_yellow: "#b57614"
        readonly property color faded_blue:   "#076678"
        readonly property color faded_purple: "#8f3f71"
        readonly property color faded_aqua:   "#427b58"
        readonly property color faded_orange: "#af3a03"

        // semantic colors
        readonly property color bg:        "#1d2021"
        readonly property color fg:        "#ebdbb2"
        readonly property color border:    "#3c3836"
        readonly property color muted:     "#a89984"
        readonly property color accent:    "#83a598"
        readonly property color accent_fg: "#1d2021"
        readonly property color selection: "#504945"
    }

    // ------------------------------------------------------------------ config
    readonly property string fontName: config.font ? config.font : "Inter"
    readonly property var accents: ({
        accent:   gruvbox.accent,
        red:      gruvbox.bright_red,
        green:    gruvbox.bright_green,
        yellow:   gruvbox.bright_yellow,
        blue:     gruvbox.bright_blue,
        purple:   gruvbox.bright_purple,
        aqua:     gruvbox.accent,
        orange:   gruvbox.bright_orange,
        neutral_aqua: gruvbox.neutral_aqua
    })
    readonly property color accent: (config.accent && accents[config.accent]) ? accents[config.accent] : gruvbox.accent
    readonly property bool use24h: config.clock24 !== "false"

    // ------------------------------------------------------------------ state
    property bool busy: false
    property bool failed: false
    property bool showPw: false
    property real shakeX: 0
    property date now: new Date()

    property int curIdx: -1
    property string curUser: ""
    property string curReal: ""
    property string curIcon: ""
    property int sessionIdx: sessionModel.lastIndex

    function selectUser(i, name, real, icon) {
        curIdx = i
        curUser = name
        curReal = (real && real.length > 0) ? real : name
        var s = icon ? String(icon) : ""
        if (s.length > 0 && s.charAt(0) === "/") s = "file://" + s
        curIcon = s
        failed = false
        pw.text = ""
    }

    function greeting() {
        var h = now.getHours()
        if (h < 5)  return "Still up,"
        if (h < 12) return "Good morning,"
        if (h < 18) return "Good afternoon,"
        return "Good evening,"
    }

    function doLogin() {
        if (busy || pw.text.length === 0 || curUser.length === 0)
            return
        failed = false
        busy = true
        busyGuard.restart()
        sddm.login(curUser, pw.text, sessionIdx)
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            busyGuard.stop()
            root.busy = false
            root.failed = true
            pw.text = ""
            shake.restart()
            pw.forceActiveFocus()
        }
        function onLoginSucceeded() {
            busyGuard.stop()
            root.busy = false
        }
    }

    // Safety net: the preview/test mode never answers a login, so unlock the UI again.
    Timer {
        id: busyGuard
        interval: 6000
        onTriggered: root.busy = false
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }

    // ------------------------------------------------------------------ background
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: gruvbox.dark0_hard }
            GradientStop { position: 1.0; color: gruvbox.dark0 }
        }
    }

    Image {
        anchors.fill: parent
        source: config.background ? config.background : ""
        fillMode: Image.PreserveAspectCrop
        visible: status === Image.Ready
    }

    // dot grid
    Canvas {
        anchors.fill: parent
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            var c = getContext("2d")
            c.reset()
            c.fillStyle = "rgba(235,219,178,0.06)"
            for (var x = 24; x < width; x += 32)
                for (var y = 24; y < height; y += 32) {
                    c.beginPath()
                    c.arc(x, y, 1.4, 0, Math.PI * 2)
                    c.fill()
                }
        }
    }

    // concentric rings behind the card
    Repeater {
        model: 4
        delegate: Rectangle {
            readonly property real d: root.height * (0.8 + index * 0.42)
            width: d; height: d; radius: d / 2
            x: root.width * 0.76 - d / 2
            y: root.height * 0.5 - d / 2
            color: "transparent"
            border.width: index === 0 ? 3 : 2
            border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.20 - index * 0.04)
        }
    }

    Rectangle {
        width: root.height * 0.55; height: width; radius: width / 2
        x: -width * 0.35; y: -height * 0.4
        color: Qt.rgba(0.514, 0.647, 0.596, 0.07)   // #83a598 tint
    }

    // ------------------------------------------------------------------ left: typography
    Column {
        id: hero
        anchors { left: parent.left; leftMargin: root.width * 0.07; verticalCenter: parent.verticalCenter; verticalCenterOffset: -root.height * 0.04 }
        spacing: 6

        Text {
            text: root.greeting()
            color: gruvbox.light3
            font { family: root.fontName; pixelSize: 30; weight: Font.Bold }
        }
        Text {
            text: root.curReal.length > 0 ? root.curReal : "Welcome"
            color: root.accent
            font { family: root.fontName; pixelSize: 64; weight: Font.Black; letterSpacing: -2 }
        }

        Item { width: 1; height: 14 }

        Row {
            id: clockRow
            spacing: 0
            readonly property int px: Math.min(root.height * 0.24, 200)
            readonly property real colonShift: -0.07
            readonly property real colonGap: 0

            Text {
                text: Qt.formatDateTime(root.now, root.use24h ? "HH" : "h")
                color: gruvbox.fg
                font { family: root.fontName; pixelSize: clockRow.px; weight: Font.Black; letterSpacing: -6 }
            }
            Text {
                text: ":"
                color: root.accent
                y: clockRow.px * clockRow.colonShift
                leftPadding: clockRow.colonGap
                rightPadding: clockRow.colonGap
                font { family: root.fontName; pixelSize: clockRow.px; weight: Font.Black }
            }
            Text {
                text: Qt.formatDateTime(root.now, "mm")
                color: gruvbox.fg
                font { family: root.fontName; pixelSize: clockRow.px; weight: Font.Black; letterSpacing: -6 }
            }
        }

        Text {
            text: Qt.formatDateTime(root.now, "dddd, MMMM d").toUpperCase()
            color: gruvbox.muted
            font { family: root.fontName; pixelSize: 18; weight: Font.ExtraBold; letterSpacing: 4 }
        }
    }

    // ------------------------------------------------------------------ right: card
    Item {
        id: cardWrap
        width: 400
        height: card.height
        anchors { right: parent.right; rightMargin: root.width * 0.07; verticalCenter: parent.verticalCenter }
        opacity: 0
        transform: Translate { x: root.shakeX }
        Component.onCompleted: intro.start()

        ParallelAnimation {
            id: intro
            NumberAnimation { target: cardWrap; property: "opacity"; to: 1; duration: 450; easing.type: Easing.OutCubic }
        }

        // offset block shadow
        Rectangle {
            x: 12; y: 12
            width: card.width; height: card.height
            radius: card.radius
            color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.16)
        }

        Rectangle {
            id: card
            width: parent.width
            height: content.height + 56
            radius: 28
            color: Qt.rgba(0.157, 0.157, 0.157, 0.92)   // dark0 at 92%
            border {
                width: 2
                color: root.failed ? gruvbox.bright_red : gruvbox.dark2
            }
            Behavior on border.color { ColorAnimation { duration: 150 } }

            Column {
                id: content
                x: 28; y: 28
                width: card.width - 56
                spacing: 18

                // identity
                Row {
                    spacing: 16
                    Rectangle {
                        id: avatar
                        width: 84; height: 84; radius: 26
                        color: root.accent
                        Text {
                            anchors.centerIn: parent
                            text: root.curReal.length > 0 ? root.curReal.charAt(0).toUpperCase() : "?"
                            color: gruvbox.accent_fg
                            font { family: root.fontName; pixelSize: 44; weight: Font.Black }
                        }
                        Canvas {
                            id: pic
                            anchors.fill: parent
                            property string src: root.curIcon
                            property string loaded: ""
                            onSrcChanged: {
                                if (src.length > 0) loadImage(src)
                                requestPaint()
                            }
                            Component.onCompleted: if (src.length > 0) loadImage(src)
                            onImageLoaded: requestPaint()
                            onPaint: {
                                var c = getContext("2d")
                                c.reset()
                                if (src.length === 0 || !isImageLoaded(src)) return
                                var r = 26, w = width, h = height
                                c.beginPath()
                                c.moveTo(r, 0)
                                c.arcTo(w, 0, w, h, r)
                                c.arcTo(w, h, 0, h, r)
                                c.arcTo(0, h, 0, 0, r)
                                c.arcTo(0, 0, w, 0, r)
                                c.closePath()
                                c.clip()
                                c.drawImage(src, 0, 0, w, h)
                            }
                        }
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        Text {
                            text: root.curReal
                            color: gruvbox.fg
                            elide: Text.ElideRight
                            width: content.width - avatar.width - 16
                            font { family: root.fontName; pixelSize: 28; weight: Font.Black; letterSpacing: -0.5 }
                        }
                        Text {
                            text: "@" + root.curUser
                            color: gruvbox.muted
                            font { family: root.fontName; pixelSize: 15; weight: Font.Bold }
                        }
                    }
                }

                // user chips (only when more than one user)
                Flow {
                    width: parent.width
                    spacing: 8
                    visible: userModel.count > 1
                    Repeater {
                        model: userModel
                        delegate: Chip {
                            label: model.name
                            accent: root.accent
                            fontName: root.fontName
                            selected: root.curIdx === index
                            onClicked: { root.selectUser(index, model.name, model.realName, model.icon); pw.forceActiveFocus() }
                            Component.onCompleted: if (index === userModel.lastIndex) root.selectUser(index, model.name, model.realName, model.icon)
                        }
                    }
                }
                // keep selection working for the single-user case too
                Repeater {
                    model: userModel.count > 1 ? 0 : userModel
                    delegate: Item {
                        width: 0; height: 0
                        Component.onCompleted: root.selectUser(index, model.name, model.realName, model.icon)
                    }
                }

                // password
                Column {
                    width: parent.width
                    spacing: 8
                    Text {
                        text: "PASSWORD"
                        color: root.failed ? gruvbox.bright_red : gruvbox.light3
                        font { family: root.fontName; pixelSize: 12; weight: Font.ExtraBold; letterSpacing: 2.5 }
                    }
                    Rectangle {
                        width: parent.width
                        height: 58
                        radius: 18
                        color: gruvbox.dark0_hard
                        border {
                            width: 2
                            color: root.failed ? gruvbox.bright_red : (pw.activeFocus ? root.accent : gruvbox.dark2)
                        }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        TextInput {
                            id: pw
                            anchors { left: parent.left; leftMargin: 20; right: toggle.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                            echoMode: root.showPw ? TextInput.Normal : TextInput.Password
                            passwordCharacter: "●"
                            color: gruvbox.fg
                            selectionColor: root.accent
                            selectedTextColor: gruvbox.accent_fg
                            clip: true
                            focus: true
                            enabled: !root.busy
                            font { family: root.fontName; pixelSize: 20; weight: Font.Bold }
                            onAccepted: root.doLogin()
                            onTextChanged: root.failed = false
                            Keys.onEscapePressed: text = ""

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: pw.text.length === 0
                                text: "Type it in…"
                                color: gruvbox.gray
                                font { family: root.fontName; pixelSize: 20; weight: Font.Bold }
                            }
                        }

                        Text {
                            id: toggle
                            anchors { right: parent.right; rightMargin: 18; verticalCenter: parent.verticalCenter }
                            text: root.showPw ? "HIDE" : "SHOW"
                            color: toggleArea.containsMouse ? root.accent : gruvbox.muted
                            font { family: root.fontName; pixelSize: 12; weight: Font.ExtraBold; letterSpacing: 2 }
                            MouseArea {
                                id: toggleArea
                                anchors { fill: parent; margins: -8 }
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { root.showPw = !root.showPw; pw.forceActiveFocus() }
                            }
                        }
                    }
                    Text {
                        height: 18
                        text: root.failed ? "Wrong password. Try again." : ""
                        color: gruvbox.bright_red
                        font { family: root.fontName; pixelSize: 14; weight: Font.Bold }
                    }
                }

                // sign in
                Rectangle {
                    id: signIn
                    width: parent.width
                    height: 60
                    radius: 18
                    color: root.accent
                    opacity: pw.text.length > 0 ? 1 : 0.35
                    scale: signMouse.pressed ? 0.98 : 1
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                    Behavior on scale { NumberAnimation { duration: 80 } }

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: "white"
                        opacity: signMouse.containsMouse && pw.text.length > 0 ? 0.14 : 0
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: root.busy ? "Signing in…" : "Sign in  →"
                        color: gruvbox.accent_fg
                        font { family: root.fontName; pixelSize: 20; weight: Font.Black; letterSpacing: 0.5 }
                    }
                    MouseArea {
                        id: signMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: pw.text.length > 0
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.doLogin()
                    }
                }

                // session
                Column {
                    width: parent.width
                    spacing: 8
                    Text {
                        text: "SESSION"
                        color: gruvbox.light3
                        font { family: root.fontName; pixelSize: 12; weight: Font.ExtraBold; letterSpacing: 2.5 }
                    }
                    Flow {
                        width: parent.width
                        spacing: 8
                        Repeater {
                            model: sessionModel
                            delegate: Chip {
                                label: model.name
                                accent: root.accent
                                fontName: root.fontName
                                selected: root.sessionIdx === index
                                onClicked: { root.sessionIdx = index; pw.forceActiveFocus() }
                            }
                        }
                    }
                }
            }
        }

        SequentialAnimation {
            id: shake
            NumberAnimation { target: root; property: "shakeX"; to: -16; duration: 45 }
            NumberAnimation { target: root; property: "shakeX"; to: 16;  duration: 70 }
            NumberAnimation { target: root; property: "shakeX"; to: -11; duration: 60 }
            NumberAnimation { target: root; property: "shakeX"; to: 8;   duration: 55 }
            NumberAnimation { target: root; property: "shakeX"; to: 0;   duration: 45 }
        }
    }

    // ------------------------------------------------------------------ bottom-left: power
    Row {
        anchors { left: parent.left; leftMargin: root.width * 0.07; bottom: parent.bottom; bottomMargin: 44 }
        spacing: 12

        PowerButton {
            visible: sddm.canSuspend
            label: "Sleep"
            tone: gruvbox.bright_purple
            fontName: root.fontName
            onClicked: sddm.suspend()
        }
        PowerButton {
            visible: sddm.canReboot
            label: "Restart"
            tone: gruvbox.bright_yellow
            fontName: root.fontName
            onClicked: sddm.reboot()
        }
        PowerButton {
            visible: sddm.canPowerOff
            label: "Shut down"
            tone: gruvbox.bright_red
            fontName: root.fontName
            onClicked: sddm.powerOff()
        }
    }

    Component.onCompleted: pw.forceActiveFocus()
}