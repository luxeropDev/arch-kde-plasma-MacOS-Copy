import QtQuick
import QtQuick.Layouts

PaneBase {
    id: root
    paneId: "battery"
    signal navigate(string pane)
    readonly property var d: settings.data.battery || ({})
    readonly property var states: ({ "charging": "Заряжается", "discharging": "Работа от аккумулятора",
                                     "fully-charged": "Полностью заряжен", "pending-charge": "Подключён, не заряжается" })
    readonly property var profileNames: ({ "power-saver": "Экономия энергии", "balanced": "Автоматически", "performance": "Высокая мощность" })

    PaneHeader {
        icon: "battery-full-symbolic"; tint: "#30c75a"
        title: root.d.present ? root.d.percent + "%" : "Аккумулятор"
        description: root.d.present ? (root.states[root.d.state] || root.d.state || "") : "Аккумулятор не найден"
    }
    Group {
        visible: !!root.d.present
        SettingRow {
            text: "Состояние аккумулятора"
            subtitle: root.d.health >= 0 ? "Максимальная ёмкость: " + root.d.health + "%" : ""
            Txt { text: root.d.health < 0 ? "—" : (root.d.health >= 80 ? "Нормальное" : "Рекомендуется обслуживание")
                    color: root.d.health >= 80 ? Theme.text : "#ff9f0a" }
        }
        SettingRow {
            visible: root.d.cycles >= 0
            text: "Циклы перезарядки"
            Txt { text: String(root.d.cycles); secondary: true }
        }
        SettingRow {
            visible: (root.d.profiles || []).length > 0
            text: "Режим энергопотребления"
            MacPopup {
                options: (root.d.profiles || []).map(p => ({ value: p, text: root.profileNames[p] || p }))
                current: root.d.profile
                onPicked: (v) => settings.call("battery.profile", v)
            }
        }
    }
    Group {
        SettingRow { text: "Параметры энергосбережения…"; subtitle: "Сон, яркость при работе от аккумулятора, крышка"; chevron: true
                     onClicked: settings.openKcm("kcm_powerdevilprofilesconfig") }
        SettingRow { text: "Сведения о питании…"; chevron: true; onClicked: settings.openKcm("kcm_energyinfo") }
    }
}
