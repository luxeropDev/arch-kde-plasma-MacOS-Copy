import QtQuick
import QtQuick.Layouts

PageBase {
    id: page
    signal navigate(int index)

    readonly property var st: hub.state
    readonly property var buds: st.buds || ({})
    readonly property bool clientInstalled: !!(hub.diagnostics.budsClient)

    PageHeader { title: "Galaxy Buds"; subtitle: "Соединение — через BlueZ, функции наушников — через GalaxyBudsClient" }

    Card {
        Layout.fillWidth: true
        padding: 24
        ColumnLayout {
            anchors.fill: parent
            spacing: 16
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: buds.name || "Наушники не найдены"
                    color: Theme.text
                    font.family: Theme.font; font.pixelSize: 22; font.weight: Font.DemiBold
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
                StatusBadge { state: buds.state || "unavailable" }
            }
            BatteryMeter {
                level: buds.battery === undefined ? -1 : buds.battery
                unavailableText: "Заряд не передаётся по Bluetooth"
            }
            Text {
                text: buds.message || ""
                color: Theme.textDim
                font.family: Theme.font; font.pixelSize: 13
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
            InfoRow { label: "Bluetooth"; value: !st.btKnown ? "недоступен" : (st.btPowered ? "включён" : "выключен")
                      valueColor: st.btPowered ? Theme.good : Theme.warn }
            InfoRow { label: "Модель"; value: buds.name || "—" }
            InfoRow { label: "Источник данных"; value: buds.source || "—" }
            Flow {
                Layout.fillWidth: true
                spacing: 10
                ActionButton {
                    text: st.btPowered ? "Выключить Bluetooth" : "Включить Bluetooth"
                    iconName: "bluetooth"
                    primary: st.btKnown && !st.btPowered
                    onClicked: hub.toggleBluetooth()
                }
                ActionButton {
                    visible: buds.state === "available" && st.btPowered
                    primary: true; text: "Подключить"; iconName: "buds"
                    onClicked: hub.connectBuds()
                }
                ActionButton { visible: !!buds.connected; text: "Отключить"; onClicked: hub.disconnectBuds() }
                ActionButton {
                    text: "Открыть GalaxyBudsClient"; iconName: "buds"
                    primary: !!buds.connected
                    onClicked: hub.launchBudsClient()
                }
            }
        }
    }

    Card {
        Layout.fillWidth: true
        padding: 24
        ColumnLayout {
            anchors.fill: parent
            spacing: 14
            Text {
                text: "Управление наушниками"
                color: Theme.text
                font.family: Theme.font; font.pixelSize: 17; font.weight: Font.DemiBold
            }
            CheckRow { ok: page.clientInstalled; text: "GalaxyBudsClient (Flatpak)"
                       hint: page.clientInstalled ? "Установлен. Шумоподавление, ambient, эквалайзер, заряд каждого наушника и сенсорные жесты — в нём."
                                                  : "Не установлен: flatpak install flathub me.timschneeberger.GalaxyBudsClient" }
            CheckRow { ok: false; text: "ANC / Ambient прямо в этом окне"
                       hint: "BlueZ не умеет управлять шумоподавлением Samsung — это закрытый протокол. Эти функции выполняет только GalaxyBudsClient, поэтому здесь они не дублируются." }
            CheckRow { ok: false; text: "Заряд левого и правого наушника"
                       hint: "Показывается в GalaxyBudsClient. Общий заряд виден здесь только если наушники сообщают его через стандартный профиль Bluetooth." }
        }
    }
}
