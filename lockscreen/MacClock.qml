/*
    Часы экрана блокировки в стиле macOS: дата сверху, крупное время под ней.
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: macClock

    property date now: new Date()
    readonly property int screenHeight: Window.window ? Window.window.height : 1080

    spacing: 0

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: macClock.now = new Date()
    }

    PlasmaComponents3.Label {
        Layout.alignment: Qt.AlignHCenter
        text: {
            const s = Qt.locale().toString(macClock.now, "dddd, d MMMM")
            return s.charAt(0).toUpperCase() + s.slice(1)
        }
        color: Qt.rgba(1, 1, 1, 0.92)
        font.pixelSize: Math.round(macClock.screenHeight * 0.024)
        font.weight: Font.DemiBold
        textFormat: Text.PlainText
    }

    PlasmaComponents3.Label {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: -Math.round(macClock.screenHeight * 0.012)
        text: Qt.formatTime(macClock.now, "H:mm")
        color: Qt.rgba(1, 1, 1, 0.88)
        font.pixelSize: Math.round(macClock.screenHeight * 0.125)
        font.weight: Font.Bold
        font.letterSpacing: -Math.round(macClock.screenHeight * 0.002)
        textFormat: Text.PlainText
    }
}
