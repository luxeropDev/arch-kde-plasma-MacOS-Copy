import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

PaneBase {
    id: root
    paneId: "wifi"
    signal navigate(string pane)
    readonly property var d: settings.data.wifi || ({})
    function bars(s) { return s > 75 ? "excellent" : s > 50 ? "good" : s > 25 ? "ok" : "weak" }

    Timer { interval: 8000; running: true; repeat: true; onTriggered: settings.load("wifi") }

    PaneHeader { icon: "network-wireless-symbolic"; tint: "#0a84ff"; title: "Wi‑Fi"
                 description: "Подключение к беспроводным сетям. Новую сеть с паролем можно добавить в дополнительных параметрах." }
    Group {
        SettingRow {
            text: "Wi‑Fi"
            icon: "network-wireless-symbolic"; tint: "#0a84ff"
            MacSwitch { checked: !!root.d.enabled; onToggled: (v) => settings.call("wifi.power", v) }
        }
        SettingRow {
            visible: !!root.d.current
            text: root.d.current || ""
            subtitle: "Подключено"
            Txt { text: "✓"; color: Theme.accent; font.weight: Font.Bold }
        }
    }
    Group {
        visible: !!root.d.enabled
        title: "Другие сети"
        Repeater {
            model: (root.d.networks || []).filter(n => !n.active)
            SettingRow {
                required property var modelData
                text: modelData.ssid
                subtitle: modelData.known ? "Сохранённая сеть" : ""
                Kirigami.Icon { visible: modelData.secure; width: 14; height: 14; source: "object-locked-symbolic"; isMask: true; color: Theme.secondary }
                Kirigami.Icon { width: 16; height: 16; source: "network-wireless-signal-" + root.bars(modelData.signal) + "-symbolic"
                                fallback: "network-wireless-symbolic"; isMask: true; color: Theme.text }
                MacButton {
                    text: modelData.known ? "Подключиться" : "Подключиться…"
                    onClicked: modelData.known ? settings.call("wifi.connect", modelData.ssid) : settings.openKcm("kcm_networkmanagement")
                }
            }
        }
    }
    Group {
        SettingRow { text: "Дополнительные параметры…"; chevron: true; onClicked: settings.openKcm("kcm_networkmanagement") }
    }
}
