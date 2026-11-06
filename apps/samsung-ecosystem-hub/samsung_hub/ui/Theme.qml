pragma Singleton
import QtQuick

// Цветовая система: светлая и тёмная темы, выбранная тема приходит из Main.qml
QtObject {
    id: theme

    property string mode: "system"          // system | light | dark
    readonly property bool dark: mode === "dark" || (mode === "system" && Qt.styleHints.colorScheme === Qt.Dark)

    readonly property color accent: "#0a84ff"
    readonly property color accent2: "#7d5cff"
    readonly property color good: dark ? "#32d74b" : "#28a745"
    readonly property color warn: "#ff9f0a"
    readonly property color bad: "#ff453a"

    readonly property color bgTop: dark ? "#10131c" : "#eef2fa"
    readonly property color bgBottom: dark ? "#1b1633" : "#e2e7f7"
    readonly property color sidebar: dark ? Qt.rgba(1, 1, 1, 0.045) : Qt.rgba(1, 1, 1, 0.55)
    readonly property color card: dark ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(1, 1, 1, 0.72)
    readonly property color cardHover: dark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(1, 1, 1, 0.88)
    readonly property color border: dark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(1, 1, 1, 0.9)
    readonly property color hairline: dark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.07)
    readonly property color text: dark ? "#f5f5f7" : "#1d1d1f"
    readonly property color textDim: dark ? Qt.rgba(1, 1, 1, 0.62) : Qt.rgba(0, 0, 0, 0.55)
    readonly property color fill: dark ? Qt.rgba(1, 1, 1, 0.09) : Qt.rgba(0, 0, 0, 0.055)
    readonly property color fillHover: dark ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.09)
    readonly property color shadow: dark ? Qt.rgba(0, 0, 0, 0.45) : Qt.rgba(40, 50, 100, 0.0)
    readonly property color shadowSoft: dark ? "#66000000" : "#26283c78"

    readonly property int radius: 22
    readonly property int radiusSmall: 14
    readonly property string font: "Inter"

    readonly property int anim: 160
}
