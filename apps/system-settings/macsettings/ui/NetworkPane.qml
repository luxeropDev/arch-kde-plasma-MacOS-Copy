import QtQuick
import QtQuick.Layouts

PaneBase {
    id: root
    paneId: "network"
    signal navigate(string pane)
    readonly property var d: settings.data.network || ({})

    PaneHeader { icon: "network-wired-symbolic"; tint: "#0a84ff"; title: "Сеть"; description: "Активные подключения, VPN, прокси и брандмауэр." }
    Group {
        title: "Подключения"
        SettingRow { visible: (root.d.connections || []).length === 0; text: "Нет активных подключений"; subtitle: "" }
        Repeater {
            model: root.d.connections || []
            SettingRow {
                required property var modelData
                text: modelData.name
                subtitle: modelData.type + " · " + modelData.device
                icon: modelData.type === "Wi‑Fi" ? "network-wireless-symbolic" : (modelData.type === "VPN" ? "network-vpn-symbolic" : "network-wired-symbolic")
                tint: "#0a84ff"
                Txt { text: "Подключено"; color: Theme.good }
            }
        }
    }
    Group {
        SettingRow { text: "Подключения, VPN и точка доступа…"; chevron: true; onClicked: settings.openKcm("kcm_networkmanagement") }
        SettingRow { text: "Прокси…"; chevron: true; onClicked: settings.openKcm("kcm_proxy") }
        SettingRow { text: "Брандмауэр…"; chevron: true; onClicked: settings.openKcm("kcm_firewall") }
    }
}
