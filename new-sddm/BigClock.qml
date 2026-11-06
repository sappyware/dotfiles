import QtQuick

Item {
  id: root
  property real size: 200
  readonly property bool stacked: Config.clockStyle === "stacked"
  implicitWidth: stacked ? col.implicitWidth : inline.implicitWidth
  implicitHeight: stacked ? col.implicitHeight : inline.implicitHeight

  property date now: new Date()
  Timer { interval: 1000; repeat: true; running: true; onTriggered: root.now = new Date() }
  readonly property string hh: Qt.formatDateTime(now, Config.hour24 ? "HH" : "hh")
  readonly property string mm: Qt.formatDateTime(now, "mm")

  // A Text item is as tall as the font's full line box, which leaves a big empty band above and
  // below the digits. Measure where the digits really are and crop each row to that.
  FontMetrics { id: fm; font.family: Config.font; font.pixelSize: root.size; font.weight: Font.DemiBold }
  readonly property rect tb: { fm.ascent; fm.descent; return fm.tightBoundingRect("0123456789"); }
  readonly property bool measured: tb.height > 1
  readonly property real digitH: measured ? tb.height : size * 0.72
  readonly property real digitTop: measured ? fm.ascent + tb.y : size * 0.22   // line-box top -> digit top
  readonly property real rowGap: Math.max(6, size * Config.clockGap)

  Column {
    id: col
    visible: root.stacked
    spacing: root.rowGap
    Item {
      x: (col.width - width) / 2
      width: hTxt.implicitWidth; height: root.digitH
      Text {
        id: hTxt
        y: -root.digitTop
        text: root.hh; color: Theme.s.primaryFixed
        font.family: Config.font; font.pixelSize: root.size; font.weight: Font.DemiBold
      }
    }
    Item {
      x: (col.width - width) / 2
      width: mTxt.implicitWidth; height: root.digitH
      Text {
        id: mTxt
        y: -root.digitTop
        text: root.mm; color: Theme.s.primaryFixedDim
        font.family: Config.font; font.pixelSize: root.size; font.weight: Font.DemiBold
      }
    }
  }
  Row {
    id: inline
    visible: !root.stacked
    Text { text: root.hh + ":"; color: Theme.s.primaryFixed; font.family: Config.font; font.pixelSize: root.size * 0.62; font.weight: Font.DemiBold }
    Text { text: root.mm; color: Theme.s.primaryFixedDim; font.family: Config.font; font.pixelSize: root.size * 0.62; font.weight: Font.DemiBold }
  }
}
