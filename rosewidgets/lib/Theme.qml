pragma Singleton
import QtQuick

QtObject {
    id: root

    readonly property color bg:       Config.theme.bg        ?? "#1e1e2e"
    readonly property color fg:       Config.theme.fg        ?? "#cdd6f4"
    readonly property color accent:   Config.theme.accent    ?? "#f5c2e7"
    readonly property color accentFg: Config.theme.accent_fg ?? "#1e1e2e"
    readonly property color muted:    Config.theme.muted     ?? "#9399b2"
    readonly property color border:   Config.theme.border    ?? "#313244"
    readonly property color urgent:   Config.theme.urgent    ?? "#f38ba8"
    readonly property color green:    Config.theme.green     ?? "#a6e3a1"
    readonly property color yellow:   Config.theme.yellow    ?? "#f9e2af"
    readonly property color blue:     Config.theme.blue      ?? "#89dceb"
    readonly property color purple:   Config.theme.purple    ?? "#cba6f7"
    readonly property color orange:   Config.theme.orange    ?? "#fab387"

    readonly property string fontFamily:  Config.font.family       ?? "Iosevka Nerd Font"
    readonly property int    sizeSmall:   Config.font.size_small   ?? 12
    readonly property int    sizeBody:    Config.font.size_body    ?? 14
    readonly property int    sizeTitle:   Config.font.size_title   ?? 18
    readonly property int    sizeDisplay: Config.font.size_display ?? 52

    readonly property real radius:      Config.appearance.corner_radius    ?? 14
    readonly property bool glass:       Config.appearance.glass            ?? false
    readonly property real glassAlpha:  Config.appearance.background_alpha ?? 0.85
    readonly property bool shadow:      Config.appearance.shadow           ?? true

    readonly property bool   animEnabled:  Config.animations.enabled     ?? true
    readonly property int    animDuration: Config.animations.duration_ms ?? 200
    readonly property string animEasing:   Config.animations.easing      ?? "OutCubic"

    function token(name) {
        switch (name) {
            case "bg":       return bg
            case "fg":       return fg
            case "accent":   return accent
            case "accentFg": return accentFg
            case "muted":    return muted
            case "border":   return border
            case "urgent":   return urgent
            case "green":    return green
            case "yellow":   return yellow
            case "blue":     return blue
            case "purple":   return purple
            case "orange":   return orange
            default:         return null
        }
    }
}
