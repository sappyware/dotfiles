import QtQuick
import QtQuick.Effects

Item {
  id: root
  required property var ctx
  property url wall: ""
  readonly property bool authing: ctx.authing
  readonly property var s: Theme.s
  readonly property real vh: height
  readonly property real vw: width
  readonly property real hintTop: vh - vh * 0.035 - 46
  focus: true
  function grab() { forceActiveFocus(); }
  Component.onCompleted: grab()
  onVisibleChanged: if (visible) grab()
  // the compositor hands keyboard focus to a lock surface some time after it is mapped (and to
  // whichever monitor the pointer is on), so keep re-claiming it until we really have it
  Timer { interval: 250; repeat: true; running: !root.activeFocus; onTriggered: root.grab() }
  HoverHandler { onHoveredChanged: root.grab() }

  // spring Behaviors stay off until the surface has its final size, otherwise everything
  // flies in from (0,0) when the compositor resizes the surface after creation
  property bool settled: false
  Timer { id: settle; interval: 450; onTriggered: root.settled = true }
  onWidthChanged: if (!settled) settle.restart()
  onHeightChanged: if (!settled) settle.restart()

  Keys.onPressed: event => {
    var k = event.key;
    var mod = event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier);
    event.accepted = true;
    ctx.poke();
    if (k === Qt.Key_Escape) ctx.back();
    else if (k === Qt.Key_Return || k === Qt.Key_Enter) { if (!ctx.authing) ctx.open(); else ctx.submit(); }
    else if (k === Qt.Key_Backspace) ctx.backspace();
    else if (k === Qt.Key_U && (event.modifiers & Qt.ControlModifier)) ctx.clear();
    else if (!mod && event.text.length === 1 && event.text >= " ") ctx.type(event.text);
    else if (!mod && k !== Qt.Key_Shift && k !== Qt.Key_Control && k !== Qt.Key_Alt && k !== Qt.Key_Meta && k !== Qt.Key_CapsLock) ctx.open();
  }

  // ---- background ----
  Rectangle { anchors.fill: parent; color: root.s.surface }
  Rectangle {
    anchors.fill: parent
    gradient: Gradient {
      GradientStop { position: 0; color: root.s.primaryContainer }
      GradientStop { position: 1; color: root.s.surface }
    }
    opacity: 0.55
  }
  // The wallpaper is cropped to fill the screen *inside* an item that is rendered as a layer, and the blur is
  // applied to that layer. (Using the Image itself as the effect source samples its raw texture and ignores
  // fillMode, which is what stretched wallpapers that aren't the screen's shape.)
  Item {
    id: wpBox
    anchors.fill: parent
    clip: true
    opacity: wp.status === Image.Ready ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 500 } }
    layer.enabled: true
    layer.effect: MultiEffect {
      blurEnabled: Config.blur > 0
      blurMax: Math.max(1, Config.blur)
      blur: root.authing ? 1.0 : 0.0
      Behavior on blur { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
    }
    Image {
      id: wp
      anchors.fill: parent
      asynchronous: true
      source: root.wall
      fillMode: Image.PreserveAspectCrop
      autoTransform: true
    }
  }
  Rectangle {
    anchors.fill: parent; color: "black"
    opacity: Math.min(0.85, Config.dim + (root.authing ? 0.22 : 0))
    Behavior on opacity { NumberAnimation { duration: 500 } }
  }
  Rectangle {
    anchors { left: parent.left; right: parent.right; top: parent.top }
    height: root.vh * 0.55
    opacity: root.authing ? 0 : 1
    Behavior on opacity { NumberAnimation { duration: 400 } }
    gradient: Gradient {
      GradientStop { position: 0; color: "#70000000" }
      GradientStop { position: 1; color: "#00000000" }
    }
  }
  Rectangle {
    anchors.fill: parent
    color: Qt.alpha(root.s.surface, 0.30)
    opacity: root.authing ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 500 } }
  }

  // ---- unlock gesture: click, wheel or swipe up ----
  MouseArea {
    anchors.fill: parent
    property real y0: 0
    onPressed: m => { y0 = m.y; root.grab(); }
    onReleased: m => { if (!root.ctx.authing && (y0 - m.y > 50 || Math.abs(y0 - m.y) < 8)) root.ctx.open(); else root.ctx.poke(); }
    onWheel: root.ctx.open()
  }

  // ---- top bar ----
  MdShape {
    x: 28; y: 24; width: 40; height: 40
    kind: "cookie"; color: Qt.alpha(root.s.primaryContainer, 0.95)
    Icon { anchors.centerIn: parent; width: 20; height: 20; kind: "lock"; color: root.s.onPrimaryContainer }
  }
  PowerRow {
    visible: Config.powerOn
    anchors { right: parent.right; rightMargin: 28; top: parent.top; topMargin: 22 }
  }

  // ---- clock + at-a-glance ----
  Item {
    id: clockWrap
    // idle: the clock block is centred on the screen, so the space above it and below it must both
    // be able to hold what lives there (top bar above, media card + hint below)
    readonly property real mediaTop: root.hintTop - 24
    readonly property real maxBlockH: Math.min(2 * mediaTop - root.vh, root.vh - 2 * 90)
    readonly property real digit: Math.max(80, Math.min(root.vw * 0.26, root.vh * 0.32,
      (maxBlockH - 60) / 1.65))
    // authing: clock shrinks, and clock + entry block are centred together as one group
    readonly property real authScale: 0.36
    readonly property real authGap: root.vh * 0.04
    readonly property real authGroupH: bc.height * authScale + authGap + auth.height
    readonly property real authTop: Math.max(root.vh * 0.05, (root.vh - authGroupH) / 2)
    readonly property real authBottom: authTop + bc.height * authScale
    width: Math.max(bc.width, glance.width); height: stack.implicitHeight
    anchors.horizontalCenter: parent.horizontalCenter
    transformOrigin: Item.Top
    y: root.authing ? authTop : Math.round((root.vh - height) / 2)
    scale: root.authing ? authScale : 1
    Behavior on y { enabled: root.settled; SpringAnimation { spring: 2.4; damping: 0.28; epsilon: 0.2 } }
    Behavior on scale { enabled: root.settled; SpringAnimation { spring: 2.4; damping: 0.28; epsilon: 0.002 } }

    Column {
      id: stack
      width: clockWrap.width
      spacing: clockWrap.digit * 0.06
      BigClock { id: bc; x: (stack.width - width) / 2; size: clockWrap.digit }
      Row {
        id: glance
        x: (stack.width - width) / 2
        spacing: 12
        opacity: root.authing ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: 250 } }
        Tx { px: Math.max(18, root.vh * 0.028); text: Qt.formatDate(bc.now, "ddd, MMM d"); anchors.verticalCenter: parent.verticalCenter }
        Row {
          visible: Config.weatherOn && wx.ok
          spacing: 8
          anchors.verticalCenter: parent.verticalCenter
          Tx { px: Math.max(18, root.vh * 0.028); text: "\u00B7"; color: root.s.onSurfaceVariant; anchors.verticalCenter: parent.verticalCenter }
          Icon { width: Math.max(22, root.vh * 0.032); height: width; kind: wx.kind; color: root.s.tertiaryFixedDim; anchors.verticalCenter: parent.verticalCenter }
          Tx { px: Math.max(18, root.vh * 0.028); text: wx.temp; anchors.verticalCenter: parent.verticalCenter }
          Tx { visible: Config.weatherPlace && wx.place !== ""; px: Math.max(16, root.vh * 0.024); text: wx.place; color: root.s.onSurfaceVariant; anchors.verticalCenter: parent.verticalCenter }
        }
      }
    }
  }
  WeatherData { id: wx }

  // ---- bottom hint ----
  Column {
    anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: root.vh * 0.035 }
    spacing: 2
    opacity: root.authing ? 0 : 0.9
    Behavior on opacity { NumberAnimation { duration: 250 } }
    Icon {
      anchors.horizontalCenter: parent.horizontalCenter
      width: 26; height: 26; kind: "chevron-up"; color: root.s.onSurface
      SequentialAnimation on y {
        loops: Animation.Infinite; running: !root.authing
        NumberAnimation { to: -5; duration: 700; easing.type: Easing.InOutSine }
        NumberAnimation { to: 0; duration: 700; easing.type: Easing.InOutSine }
      }
    }
    Tx { anchors.horizontalCenter: parent.horizontalCenter; role: "labelLarge"; text: "Click, swipe up or type to log in" }
  }

  // ---- PIN / password entry ----
  AuthBlock {
    id: auth
    ctx: root.ctx
    unit: root.vh
    anchors.horizontalCenter: parent.horizontalCenter
    y: root.authing ? clockWrap.authBottom + clockWrap.authGap : root.vh
    opacity: root.authing ? 1 : 0
    visible: opacity > 0.01
    Behavior on y { enabled: root.settled; SpringAnimation { spring: 2.2; damping: 0.3; epsilon: 0.2 } }
    Behavior on opacity { NumberAnimation { duration: 300 } }
  }
}
