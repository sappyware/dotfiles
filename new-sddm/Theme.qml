pragma Singleton
import QtQuick
import "md3.js" as Md3

QtObject {
  id: root
  readonly property var typeScale: ({
    displayLarge:   { size: 57, weight: Font.Normal, ls: -0.25 },
    displayMedium:  { size: 45, weight: Font.Normal, ls: 0 },
    displaySmall:   { size: 36, weight: Font.Normal, ls: 0 },
    headlineMedium: { size: 28, weight: Font.Normal, ls: 0 },
    titleLarge:     { size: 22, weight: Font.Normal, ls: 0 },
    titleMedium:    { size: 16, weight: Font.Medium, ls: 0.15 },
    titleSmall:     { size: 14, weight: Font.Medium, ls: 0.1 },
    bodyLarge:      { size: 16, weight: Font.Normal, ls: 0.5 },
    bodyMedium:     { size: 14, weight: Font.Normal, ls: 0.25 },
    bodySmall:      { size: 12, weight: Font.Normal, ls: 0.4 },
    labelLarge:     { size: 14, weight: Font.Medium, ls: 0.1 },
    labelMedium:    { size: 12, weight: Font.Medium, ls: 0.5 },
    labelSmall:     { size: 11, weight: Font.Medium, ls: 0.5 }
  })

  // SDDM can't run helpers, so the seed colour comes from theme.conf (install.sh derives it from your wallpaper)
  readonly property bool dark: Config.md3Mode !== "light"
  readonly property var s: Md3.scheme(Config.md3Seed, dark)
}
