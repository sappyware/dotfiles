import QtQuick

Canvas {
  id: c
  property string kind: "play"
  property color color: "white"
  property real level: 1
  property bool charging: false
  onColorChanged: requestPaint()
  onKindChanged: requestPaint()
  onLevelChanged: requestPaint()
  onChargingChanged: requestPaint()
  onWidthChanged: requestPaint()
  onHeightChanged: requestPaint()
  onPaint: {
    var g = getContext("2d");
    g.reset();
    g.scale(width / 24, height / 24);
    g.fillStyle = c.color; g.strokeStyle = c.color; g.lineWidth = 1.7; g.lineJoin = "round"; g.lineCap = "round";
    function poly(p, strokeOnly) {
      g.beginPath(); g.moveTo(p[0][0], p[0][1]);
      for (var i = 1; i < p.length; i++) g.lineTo(p[i][0], p[i][1]);
      g.closePath(); if (!strokeOnly) g.fill(); g.stroke();
    }
    function rect(x, y, w, h) { poly([[x, y], [x + w, y], [x + w, y + h], [x, y + h]]); }
    function line(a, b, x, y) { g.beginPath(); g.moveTo(a, b); g.lineTo(x, y); g.stroke(); }
    function dot(x, y, r) { g.beginPath(); g.arc(x, y, r, 0, Math.PI * 2); g.fill(); }
    function cloud(dy) { dot(8, 14.5 + dy, 3.5); dot(12.8, 11.8 + dy, 4.6); dot(17.2, 14.5 + dy, 3.2); g.fillRect(8, 14.5 + dy, 9.2, 3.5); }
    function wifi(lv) {
      g.lineWidth = 1.9;
      for (var i = 0; i < 3; i++) {
        g.globalAlpha = i < lv ? 1 : 0.3;
        g.beginPath(); g.arc(12, 19, [5, 9, 13][i], -3 * Math.PI / 4, -Math.PI / 4); g.stroke();
      }
      g.globalAlpha = 1; dot(12, 19, 1.5);
    }
    var k = kind;
    if (k === "play") poly([[8.9, 5.9], [8.9, 18.1], [18.3, 12]]);
    else if (k === "pause") { rect(6.9, 5.9, 2.2, 12.2); rect(14.9, 5.9, 2.2, 12.2); }
    else if (k === "prev") { rect(6.9, 6.9, 0.2, 10.2); poly([[10.4, 12], [17.2, 17.1], [17.2, 6.9]]); }
    else if (k === "next") { poly([[6.8, 6.9], [6.8, 17.1], [13.6, 12]]); rect(16.9, 6.9, 0.2, 10.2); }
    else if (k === "lock") {
      rect(6, 11, 12, 8.5);
      g.lineWidth = 2; g.beginPath(); g.moveTo(8.6, 11); g.lineTo(8.6, 8); g.arc(12, 8, 3.4, Math.PI, 2 * Math.PI); g.lineTo(15.4, 11); g.stroke();
    }
    else if (k === "backspace") {
      g.lineWidth = 1.8; poly([[9, 5.5], [20.5, 5.5], [20.5, 18.5], [9, 18.5], [3, 12]], true);
      line(12.6, 9.2, 17, 14.8); line(17, 9.2, 12.6, 14.8);
    }
    else if (k === "enter") { g.lineWidth = 2.4; g.beginPath(); g.moveTo(5.5, 12.5); g.lineTo(10, 17); g.lineTo(18.5, 7.5); g.stroke(); }
    else if (k === "chevron-up") { g.lineWidth = 2.2; g.beginPath(); g.moveTo(6, 15); g.lineTo(12, 9); g.lineTo(18, 15); g.stroke(); }
    else if (k === "power") { g.lineWidth = 2; line(12, 4, 12, 12); g.beginPath(); g.arc(12, 12.5, 7.4, -Math.PI / 2 + 0.6, 1.5 * Math.PI - 0.6); g.stroke(); }
    else if (k === "restart") { g.lineWidth = 2; g.beginPath(); g.arc(12, 12, 7, -0.9, 4.4); g.stroke(); poly([[9.2, 1.8], [9.2, 8.8], [13.2, 5.3]]); }
    else if (k === "moon") { g.beginPath(); g.arc(11.5, 12, 7.5, 0, Math.PI * 2); g.fill(); g.globalCompositeOperation = "destination-out"; g.beginPath(); g.arc(15.5, 9.5, 6.4, 0, Math.PI * 2); g.fill(); g.globalCompositeOperation = "source-over"; }
    else if (k === "wifi") wifi(Math.round(level));
    else if (k === "wifi-off") { wifi(0); g.lineWidth = 2; line(5, 4.5, 19.5, 19); }
    else if (k === "battery") {
      g.lineWidth = 1.6; poly([[4.5, 7.5], [17, 7.5], [17, 16.5], [4.5, 16.5]], true);
      rect(18.4, 10.4, 0.6, 3.2);
      g.globalAlpha = charging ? 0.45 : 1;
      var lv = Math.max(0, Math.min(1, level));
      if (lv > 0.02) g.fillRect(6.2, 9.2, 9.1 * lv, 5.6);
      g.globalAlpha = 1;
      if (charging) poly([[11.4, 8], [8, 12.6], [10.6, 12.6], [9.6, 16.2], [13.6, 11.2], [11, 11.2]]);
    }
    else if (k === "sun") {
      dot(12, 12, 4); g.lineWidth = 1.8;
      for (var i = 0; i < 8; i++) { var a = i * Math.PI / 4; line(12 + 6.8 * Math.cos(a), 12 + 6.8 * Math.sin(a), 12 + 9.4 * Math.cos(a), 12 + 9.4 * Math.sin(a)); }
    }
    else if (k === "cloud") cloud(0);
    else if (k === "rain") { cloud(-3); g.lineWidth = 1.7; line(8, 19, 7, 22); line(12, 19, 11, 22); line(16, 19, 15, 22); }
    else if (k === "snow") { cloud(-3); dot(8, 20, 1.2); dot(12, 21.5, 1.2); dot(16, 20, 1.2); }
    else if (k === "bolt") { cloud(-3); poly([[12.8, 14], [9.5, 19], [12, 19], [11, 23], [15, 17.5], [12.5, 17.5]]); }
    else if (k === "fog") { g.lineWidth = 2; line(4, 8.5, 20, 8.5); line(6.5, 12.5, 18, 12.5); line(4, 16.5, 15.5, 16.5); }
  }
}
