import QtQuick
import QtQuick.Layouts

PaneBase {
    id: root
    paneId: "keyboard"
    signal navigate(string pane)
    readonly property var d: settings.data.keyboard || ({})

    Group {
        SettingRow {
            text: "Скорость повтора клавиш"
            Txt { text: "Медленно"; secondary: true; font.pixelSize: 11 }
            MacSlider { id: rate; width: 180; from: 5; to: 60; stepSize: 1; value: root.d.repeatRate || 25
                        onReleased: settings.call("keyboard.repeat", { delay: delay.value, rate: rate.value }) }
            Txt { text: "Быстро"; secondary: true; font.pixelSize: 11 }
        }
        SettingRow {
            text: "Задержка до начала повтора"
            Txt { text: "Долго"; secondary: true; font.pixelSize: 11 }
            // слайдер развёрнут: вправо — короче задержка, как в macOS
            MacSlider { width: 180; from: 0; to: 1; stepSize: 0.02
                        value: 1 - ((root.d.repeatDelay || 600) - 150) / 1350
                        onReleased: (v) => { delay.value = Math.round(150 + (1 - v) * 1350)
                                             settings.call("keyboard.repeat", { delay: delay.value, rate: rate.value }) } }
            Txt { text: "Коротко"; secondary: true; font.pixelSize: 11 }
            QtObject { id: delay; property int value: root.d.repeatDelay || 600 }
        }
    }
    Group {
        title: "Ввод текста"
        SettingRow {
            text: "Источники ввода"
            subtitle: (root.d.layouts || []).map(l => l.toUpperCase()).join(", ")
            chevron: true
            onClicked: settings.openKcm("kcm_keyboard")
        }
        SettingRow { text: "Сочетания клавиш…"; chevron: true; onClicked: settings.openKcm("kcm_keys") }
        SettingRow { text: "Проверка орфографии…"; chevron: true; onClicked: settings.openKcm("kcm_spellchecking") }
    }
}
