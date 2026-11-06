import QtQuick
import QtQuick.Layouts

// «Мышь» и «Трекпад»: один файл, выбор по свойству touchpad
PaneBase {
    id: root
    paneId: "pointer"
    property bool touchpad: false
    signal navigate(string pane)
    readonly property var d: settings.data.pointer || ({})
    readonly property var devices: (touchpad ? d.touchpads : d.mice) || []

    Group {
        visible: root.devices.length === 0
        SettingRow { text: root.touchpad ? "Трекпад не найден" : "Мышь не найдена" }
    }
    Repeater {
        model: root.devices
        Group {
            required property var modelData
            title: modelData.name
            SettingRow {
                text: "Скорость перемещения"
                Txt { text: "Медленно"; secondary: true; font.pixelSize: 11 }
                MacSlider { width: 170; from: -1; to: 1; stepSize: 0.05; value: modelData.acceleration
                            onReleased: (v) => settings.setPointer(modelData.sys, "pointerAcceleration", v) }
                Txt { text: "Быстро"; secondary: true; font.pixelSize: 11 }
            }
            SettingRow {
                text: "Естественная прокрутка"
                subtitle: "Содержимое движется вслед за пальцами"
                MacSwitch { checked: modelData.naturalScroll; onToggled: (v) => settings.setPointer(modelData.sys, "naturalScroll", v) }
            }
            SettingRow {
                visible: root.touchpad && modelData.supportsTap
                text: "Касание для нажатия"
                subtitle: "Нажатие касанием одним пальцем"
                MacSwitch { checked: modelData.tapToClick; onToggled: (v) => settings.setPointer(modelData.sys, "tapToClick", v) }
            }
        }
    }
    Group {
        SettingRow { text: "Дополнительные параметры…"; chevron: true
                     onClicked: settings.openKcm(root.touchpad ? "kcm_touchpad" : "kcm_mouse") }
    }
}
