import QtQuick
import Quickshell

Item {
  id: root
  property var theme: ({})
  property var options: ({})

  readonly property real syn: 29.530588853
  readonly property bool south: options.hemisphere === "south"
  readonly property real age: {
    var d = (clk.date.getTime() - Date.UTC(2000, 0, 6, 18, 14)) / 86400000;
    return ((d % syn) + syn) % syn;
  }
  readonly property real phase: age / syn
  readonly property real illum: (1 - Math.cos(2 * Math.PI * phase)) / 2
  readonly property var names: ["New Moon", "Waxing Crescent", "First Quarter", "Waxing Gibbous",
    "Full Moon", "Waning Gibbous", "Last Quarter", "Waning Crescent"]
  readonly property string phaseName: names[Math.floor(phase * 8 + 0.5) % 8]

  function until(target) { return ((target - age) % syn + syn) % syn; }
  function when(days) {
    var d = new Date(clk.date.getTime() + days * 86400000);
    return Qt.formatDate(d, "ddd d MMM");
  }

  implicitWidth: 290
  implicitHeight: 116

  SystemClock { id: clk; precision: SystemClock.Minutes }

  Canvas {
    id: cv
    width: 112; height: 112
    anchors.verticalCenter: parent.verticalCenter

    property real ph: root.phase
    property color lit: "#ece9dc"
    property color dark: root.theme.surface !== undefined ? root.theme.surface : "#313244"

    onPhChanged: requestPaint()
    onLitChanged: requestPaint()
    onDarkChanged: requestPaint()
    Component.onCompleted: requestPaint()

    // deterministic pseudo-random so the texture never flickers between repaints
    function rnd(i) {
      var x = Math.sin(i * 127.1 + 311.7) * 43758.5453123;
      return x - Math.floor(x);
    }

    // darken (f<1) / lighten toward white (f>1) a QML color into a css rgba string
    function sh(col, f, a) {
      var r = col.r, g = col.g, b = col.b;
      if (f <= 1) { r *= f; g *= f; b *= f; }
      else { var t = f - 1; r += (1 - r) * t; g += (1 - g) * t; b += (1 - b) * t; }
      return "rgba(" + ((r * 255) | 0) + "," + ((g * 255) | 0) + "," +
             ((b * 255) | 0) + "," + (a === undefined ? 1 : a) + ")";
    }

    onPaint: {
      var c = getContext("2d");
      var TAU = Math.PI * 2;
      c.reset();
      c.clearRect(0, 0, width, height);

      var cx = width / 2, cy = height / 2;
      var r = Math.min(width, height) / 2 - 6;
      var i, t, x, y;

      // ---------- soft halo ----------
      var halo = c.createRadialGradient(cx, cy, r * 0.96, cx, cy, r * 1.12);
      halo.addColorStop(0, "rgba(236,233,220,0.20)");
      halo.addColorStop(0.45, "rgba(236,233,220,0.06)");
      halo.addColorStop(1, "rgba(236,233,220,0)");
      c.fillStyle = halo;
      c.beginPath(); c.arc(cx, cy, r * 1.12, 0, TAU); c.fill();

      // ---------- lit surface ----------
      c.save();
      c.beginPath(); c.arc(cx, cy, r, 0, TAU); c.clip();

      // base regolith: bright top-left, slightly grey bottom-right
      var base = c.createRadialGradient(cx - r * 0.38, cy - r * 0.42, r * 0.05,
                                        cx, cy, r * 1.25);
      base.addColorStop(0.00, sh(lit, 1.16));
      base.addColorStop(0.42, sh(lit, 1.02));
      base.addColorStop(0.78, sh(lit, 0.88));
      base.addColorStop(1.00, sh(lit, 0.72));
      c.fillStyle = base;
      c.fillRect(cx - r, cy - r, r * 2, r * 2);

      // maria (large soft dark plains)
      var maria = [
        [-0.30, -0.34, 0.36],
        [ 0.06, -0.46, 0.22],
        [ 0.32, -0.08, 0.30],
        [-0.04,  0.14, 0.30],
        [-0.44,  0.24, 0.20],
        [ 0.36,  0.38, 0.17]
      ];
      for (i = 0; i < maria.length; i++) {
        var mx = cx + maria[i][0] * r, my = cy + maria[i][1] * r, mr = maria[i][2] * r;
        var mg = c.createRadialGradient(mx, my, mr * 0.10, mx, my, mr);
        mg.addColorStop(0.0, "rgba(110,108,120,0.34)");
        mg.addColorStop(0.6, "rgba(118,116,128,0.19)");
        mg.addColorStop(1.0, "rgba(126,124,136,0)");
        c.fillStyle = mg;
        c.beginPath(); c.arc(mx, my, mr, 0, TAU); c.fill();
      }

      // craters: soft pit + tiny sunlit rim on the upper-left
      for (i = 0; i < 64; i++) {
        var ang  = cv.rnd(i * 3 + 1) * TAU;
        var dist = Math.sqrt(cv.rnd(i * 3 + 2)) * 0.94 * r;
        var px = cx + Math.cos(ang) * dist;
        var py = cy + Math.sin(ang) * dist;
        var cr = (0.014 + Math.pow(cv.rnd(i * 3 + 3), 3) * 0.080) * r;

        var cg = c.createRadialGradient(px - cr * 0.30, py - cr * 0.30, cr * 0.05,
                                        px, py, cr);
        cg.addColorStop(0.00, "rgba(146,143,138,0.32)");
        cg.addColorStop(0.65, "rgba(154,151,146,0.17)");
        cg.addColorStop(1.00, "rgba(162,159,154,0)");
        c.fillStyle = cg;
        c.beginPath(); c.arc(px, py, cr, 0, TAU); c.fill();

        c.strokeStyle = "rgba(255,253,246,0.18)";
        c.lineWidth = Math.max(0.7, cr * 0.18);
        c.beginPath();
        c.arc(px, py, cr * 0.90, Math.PI * 1.02, Math.PI * 1.78);
        c.stroke();
      }

      // limb darkening so the disc reads as a sphere
      var limb = c.createRadialGradient(cx, cy, r * 0.68, cx, cy, r);
      limb.addColorStop(0, "rgba(38,34,48,0)");
      limb.addColorStop(1, "rgba(38,34,48,0.30)");
      c.fillStyle = limb;
      c.beginPath(); c.arc(cx, cy, r, 0, TAU); c.fill();

      c.restore();

      // ---------- night side ----------
      var k = Math.cos(TAU * ph);
      var s = (ph < 0.5 ? 1 : -1) * (root.south ? -1 : 1);
      var N = 64;

      c.beginPath();
      for (i = 0; i <= N; i++) {          // dark limb
        t = Math.PI * i / N;
        x = cx - s * r * Math.sin(t);
        y = cy - r * Math.cos(t);
        if (i === 0) c.moveTo(x, y); else c.lineTo(x, y);
      }
      for (i = N; i >= 0; i--) {          // terminator
        t = Math.PI * i / N;
        c.lineTo(cx + s * k * r * Math.sin(t), cy - r * Math.cos(t));
      }
      c.closePath();

      c.fillStyle = sh(dark, 0.82, 0.94);
      c.fill();

      // depth: darker toward the far limb
      var sg = c.createRadialGradient(cx + s * r * 0.55, cy - r * 0.15, r * 0.10,
                                      cx - s * r * 0.70, cy, r * 1.60);
      sg.addColorStop(0, "rgba(0,0,0,0)");
      sg.addColorStop(1, "rgba(0,0,0,0.38)");
      c.fillStyle = sg;
      c.fill();

      // faint earthshine rim on the dark limb
      c.strokeStyle = "rgba(190,198,225,0.11)";
      c.lineWidth = 1.2;
      c.beginPath();
      c.arc(cx, cy, r - 0.6,
            s > 0 ? Math.PI * 0.5 : -Math.PI * 0.5,
            s > 0 ? Math.PI * 1.5 : Math.PI * 0.5);
      c.stroke();

      // crisp outer edge
      c.strokeStyle = "rgba(255,255,255,0.10)";
      c.lineWidth = 1;
      c.beginPath(); c.arc(cx, cy, r, 0, TAU); c.stroke();
    }
  }

  Column {
    anchors { left: cv.right; leftMargin: 18; right: parent.right; verticalCenter: parent.verticalCenter }
    spacing: 3
    Text {
      width: parent.width; elide: Text.ElideRight
      text: root.phaseName
      color: root.theme.text; font.pixelSize: 17; font.weight: Font.DemiBold; font.family: root.theme.font
    }
    Text {
      text: Math.round(root.illum * 100) + "% illuminated"
      color: root.theme.accent; font.pixelSize: 13; font.family: root.theme.font
    }
    Text {
      text: "Age " + root.age.toFixed(1) + " days"
      color: root.theme.subtext; font.pixelSize: 12; font.family: root.theme.font
    }
    Item { width: 1; height: 6 }
    Text {
      text: "Full   " + root.when(root.until(root.syn / 2))
      color: root.theme.subtext; font.pixelSize: 12; font.family: root.theme.font
    }
    Text {
      text: "New   " + root.when(root.until(root.syn))
      color: root.theme.subtext; font.pixelSize: 12; font.family: root.theme.font
    }
  }
}