import QtQuick
import QtQuick.Layouts

PaneBase {
    id: root
    paneId: "bluetooth"
    signal navigate(string pane)
    readonly property var d: settings.data.bluetooth || ({})

    Timer { interval: 6000; running: true; repeat: true; onTriggered: settings.load("bluetooth") }

    PaneHeader { icon: "network-bluetooth-symbolic"; tint: "#0a84ff"; title: "Bluetooth"
                 description: "Подключение наушников, клавиатур и других устройств. Новые устройства добавляются в дополнительных параметрах." }
    Group {
        SettingRow {
            text: "Bluetooth"
            subtitle: root.d.available === false ? "Адаптер не найден" : ""
            icon: "network-bluetooth-symbolic"; tint: "#0a84ff"
            MacSwitch { enabled: root.d.available !== false; checked: !!root.d.enabled; onToggled: (v) => settings.call("bt.power", v) }
        }
    }
    Group {
        title: "Мои устройства"
        visible: (root.d.devices || []).length > 0
        Repeater {
            model: root.d.devices || []
            SettingRow {
                required property var modelData
                text: modelData.name
                subtitle: (modelData.connected ? "Подключено" : "Не подключено") + (modelData.battery >= 0 ? " · " + modelData.battery + "%" : "")
                icon: modelData.icon ? modelData.icon + "-symbolic" : "network-bluetooth-symbolic"
                tint: modelData.connected ? "#0a84ff" : "#8e8e93"
                MacButton {
                    enabled: !!root.d.enabled
                    text: modelData.connected ? "Отключить" : "Подключить"
                    onClicked: settings.call(modelData.connected ? "bt.disconnect" : "bt.connect", modelData.address)
                }
            }
        }
    }
    Group {
        SettingRow { text: "Добавить устройство и другие параметры…"; chevron: true; onClicked: settings.openKcm("kcm_bluetooth") }
    }
}
