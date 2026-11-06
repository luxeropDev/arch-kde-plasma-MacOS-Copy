import QtQuick
import QtQuick.Layouts

PaneBase {
    id: root
    paneId: "displays"
    signal navigate(string pane)
    readonly property var d: settings.data.displays || ({})

    PaneHeader { icon: "video-display-symbolic"; tint: "#0a84ff"; title: "Встроенный дисплей"; description: "" }
    Group {
        SettingRow {
            visible: !!root.d.hasBrightness
            text: "Яркость"
            MacSlider { id: bright; width: 240; from: 0.02; to: 1; value: root.d.brightness || 1; live: true
                        onMoved: (v) => throttle.restart() }
            Timer { id: throttle; interval: 80; onTriggered: settings.call("display.brightness", bright.value) }
        }
        SettingRow {
            text: "Night Shift"
            subtitle: "Тёплые цвета экрана, чтобы меньше уставали глаза"
            MacSwitch { checked: !!root.d.nightShift; onToggled: (v) => settings.call("display.night", v) }
        }
    }
    Group {
        SettingRow { text: "Разрешение, масштаб и расположение мониторов…"; chevron: true; onClicked: settings.openKcm("kcm_kscreen") }
        SettingRow { text: "Расписание Night Shift…"; chevron: true; onClicked: settings.openKcm("kcm_nightlight") }
    }
}
