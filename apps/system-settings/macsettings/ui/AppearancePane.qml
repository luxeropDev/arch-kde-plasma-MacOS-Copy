import QtQuick
import QtQuick.Layouts

PaneBase {
    id: root
    paneId: "appearance"
    signal navigate(string pane)
    readonly property var d: settings.data.appearance || ({})
    readonly property var accents: [
        { id: "multicolor", color: "conic" }, { id: "blue", color: "#007aff" }, { id: "purple", color: "#af52de" },
        { id: "pink", color: "#ff2d55" }, { id: "red", color: "#ff3b30" }, { id: "orange", color: "#ff9500" },
        { id: "yellow", color: "#ffcc00" }, { id: "green", color: "#34c759" }, { id: "graphite", color: "#8e8e93" } ]

    Group {
        SettingRow {
            text: "Оформление"
            implicitHeight: 120
            RowLayout {
                spacing: 18
                AppearanceTile { mode: "auto"; label: "Авто"; selected: root.d.mode === "auto"; onClicked: settings.call("appearance.mode", "auto") }
                AppearanceTile { mode: "light"; label: "Светлое"; selected: root.d.mode === "light"; onClicked: settings.call("appearance.mode", "light") }
                AppearanceTile { mode: "dark"; label: "Тёмное"; selected: root.d.mode === "dark"; onClicked: settings.call("appearance.mode", "dark") }
            }
        }
        SettingRow {
            text: "Цвет акцента"
            Row {
                spacing: 8
                Repeater {
                    model: root.accents
                    Rectangle {
                        required property var modelData
                        width: 18; height: 18; radius: 9
                        color: modelData.color === "conic" ? "transparent" : modelData.color
                        border.width: root.d.accent === modelData.id ? 2 : 0.5
                        border.color: root.d.accent === modelData.id ? Theme.text : Qt.rgba(0, 0, 0, 0.2)
                        ConicalGradientDot { anchors.fill: parent; visible: modelData.color === "conic" }
                        TapHandler { onTapped: settings.call("appearance.accent", modelData.id) }
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                    }
                }
            }
        }
        SettingRow {
            text: "Стекло (Liquid Glass)"
            subtitle: "Насколько сильно размывается фон под строкой меню, Dock и прозрачными окнами"
            Txt { text: "Прозрачное"; secondary: true; font.pixelSize: 11; anchors.verticalCenter: parent ? parent.verticalCenter : undefined }
            MacSlider { width: 160; from: 1; to: 15; stepSize: 1; value: root.d.glass || 10
                        onReleased: (v) => settings.call("appearance.glass", Math.round(v)) }
            Txt { text: "Матовое"; secondary: true; font.pixelSize: 11; anchors.verticalCenter: parent ? parent.verticalCenter : undefined }
        }
    }
    Group {
        SettingRow { text: "Глобальная тема…"; chevron: true; onClicked: settings.openKcm("kcm_lookandfeel") }
        SettingRow { text: "Цвета…"; chevron: true; onClicked: settings.openKcm("kcm_colors") }
        SettingRow { text: "Значки и курсор…"; chevron: true; onClicked: settings.openKcm("kcm_icons") }
    }
    Txt {
        Layout.fillWidth: true
        text: "«Авто» переключает светлое и тёмное оформление по времени суток — это делает служба KDE."
        secondary: true; font.pixelSize: 11; wrapMode: Text.WordWrap; elide: Text.ElideNone
    }
}
