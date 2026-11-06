pragma Singleton
import QtQuick

// Цвета и размеры в духе macOS 27: светлая и тёмная схема по системной теме
QtObject {
    readonly property bool dark: Qt.styleHints.colorScheme === Qt.Dark

    readonly property color accent: "#0a84ff"
    readonly property color window: dark ? "#1e1e20" : "#ececee"
    readonly property color sidebar: dark ? "#262628" : "#e3e3e6"
    readonly property color content: dark ? "#1e1e20" : "#f2f2f4"
    readonly property color group: dark ? "#2c2c2e" : "#ffffff"
    readonly property color groupBorder: dark ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(0, 0, 0, 0.06)
    readonly property color separator: dark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.08)
    readonly property color text: dark ? "#f5f5f7" : "#1d1d1f"
    readonly property color secondary: dark ? Qt.rgba(1, 1, 1, 0.55) : Qt.rgba(0, 0, 0, 0.5)
    readonly property color fill: dark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.06)
    readonly property color fillStrong: dark ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(0, 0, 0, 0.12)
    readonly property color selection: dark ? "#0a6cdf" : "#0a7aff"
    readonly property color good: "#30d158"
    readonly property color bad: "#ff453a"

    readonly property int radius: 10
    readonly property int rowHeight: 44
    readonly property string font: "Inter"
    readonly property int fontSize: 13
}
