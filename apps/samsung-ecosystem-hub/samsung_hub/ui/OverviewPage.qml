import QtQuick
import QtQuick.Layouts

PageBase {
    id: page
    signal navigate(int index)

    readonly property var st: hub.state
    readonly property var phone: st.phone || ({})
    readonly property var buds: st.buds || ({})
    readonly property var watch: st.watch || ({})

    PageHeader {
        title: "Samsung Ecosystem"
        subtitle: "Телефон, наушники и часы Galaxy в одном месте"
    }

    // ---- общий статус ----
    Card {
        Layout.fillWidth: true
        padding: 22
        RowLayout {
            anchors.fill: parent
            spacing: 18
            Rectangle {
                Layout.preferredWidth: 14; Layout.preferredHeight: 14; radius: 7
                color: (st.connectedCount || 0) > 0 ? Theme.good : Theme.textDim
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    text: st.summary || "Проверяю устройства…"
                    color: Theme.text
                    font.family: Theme.font; font.pixelSize: 20; font.weight: Font.DemiBold
                }
                Text {
                    text: st.updatedAt ? "Последнее обновление данных: " + st.updatedAt : ""
                    color: Theme.textDim
                    font.family: Theme.font; font.pixelSize: 12
                }
            }
            ActionButton {
                text: "Обновить"
                iconName: "refresh"
                working: hub.busy
                onClicked: hub.refresh()
            }
        }
    }

    // ---- карточки устройств ----
    GridLayout {
        Layout.fillWidth: true
        columns: page.width > 800 ? 3 : (page.width > 560 ? 2 : 1)
        columnSpacing: 20
        rowSpacing: 20

        DeviceCard {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.alignment: Qt.AlignTop
            device: page.phone
            iconName: "phone"
            tint: "#0a84ff"
            primaryText: page.phone.connected ? "Отправить файл"
                       : (page.phone.details && page.phone.details.kdeconnectId ? "Сопрячь" : "")
            primaryIcon: page.phone.connected ? "transfer" : "link"
            onPrimaryClicked: page.phone.connected ? page.navigate(4) : hub.pairPhone()
            onOpenClicked: page.navigate(1)
        }
        DeviceCard {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.alignment: Qt.AlignTop
            device: page.buds
            iconName: "buds"
            tint: "#7d5cff"
            primaryText: page.buds.connected ? "GalaxyBudsClient"
                       : (page.buds.state === "available" && st.btPowered ? "Подключить"
                       : (st.btKnown && !st.btPowered ? "Включить Bluetooth" : ""))
            primaryIcon: page.buds.connected ? "buds" : "bluetooth"
            onPrimaryClicked: page.buds.connected ? hub.launchBudsClient()
                            : (st.btPowered ? hub.connectBuds() : hub.toggleBluetooth())
            onOpenClicked: page.navigate(2)
        }
        DeviceCard {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.alignment: Qt.AlignTop
            device: page.watch
            iconName: "watch"
            tint: "#ff7a45"
            onOpenClicked: page.navigate(3)
        }
    }

    // ---- быстрые действия ----
    Card {
        Layout.fillWidth: true
        padding: 22
        ColumnLayout {
            anchors.fill: parent
            spacing: 14
            Text {
                text: "Быстрые действия"
                color: Theme.text
                font.family: Theme.font; font.pixelSize: 17; font.weight: Font.DemiBold
            }
            Flow {
                Layout.fillWidth: true
                spacing: 10
                ActionButton { text: "Отправить файл"; iconName: "transfer"; onClicked: page.navigate(4) }
                ActionButton { text: "Зеркалировать экран"; iconName: "mirror"; onClicked: page.navigate(5) }
                ActionButton { text: "Открыть GalaxyBudsClient"; iconName: "buds"; onClicked: hub.launchBudsClient() }
                ActionButton {
                    text: st.btPowered ? "Выключить Bluetooth" : "Включить Bluetooth"
                    iconName: "bluetooth"
                    onClicked: hub.toggleBluetooth()
                }
                ActionButton {
                    text: "Буфер обмена → телефон"
                    iconName: "clipboard"
                    enabled: !!page.phone.connected
                    onClicked: hub.sendClipboard()
                }
            }
        }
    }
}
