import QtQuick
import QtQuick.Layouts

PageBase {
    id: page
    readonly property var st: hub.state
    readonly property var watch: st.watch || ({})
    readonly property var phone: st.phone || ({})

    PageHeader { title: "Galaxy Watch"; subtitle: "Часы управляются через телефон, а не напрямую через Linux" }

    Card {
        Layout.fillWidth: true
        padding: 24
        ColumnLayout {
            anchors.fill: parent
            spacing: 16
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: watch.name || "Galaxy Watch"
                    color: Theme.text
                    font.family: Theme.font; font.pixelSize: 22; font.weight: Font.DemiBold
                    Layout.fillWidth: true
                }
                StatusBadge { state: watch.state || "via_phone" }
            }
            BatteryMeter {
                level: watch.battery === undefined ? -1 : watch.battery
                unavailableText: "Заряд часов недоступен на ПК"
            }
            Text {
                text: watch.message || ""
                color: Theme.textDim
                font.family: Theme.font; font.pixelSize: 13
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
            InfoRow { label: "Источник данных"; value: watch.source || "—" }
            InfoRow {
                label: "Телефон"
                value: phone.connected ? "на связи — часы синхронизируются с ним через Galaxy Wearable" : "не подключён"
                valueColor: phone.connected ? Theme.good : Theme.textDim
            }
            InfoRow { label: "Последняя синхронизация"; value: "не определяется — Galaxy Wearable не даёт этих данных Linux" }
        }
    }

    Card {
        Layout.fillWidth: true
        padding: 24
        ColumnLayout {
            anchors.fill: parent
            spacing: 14
            Text {
                text: "Что возможно"
                color: Theme.text
                font.family: Theme.font; font.pixelSize: 17; font.weight: Font.DemiBold
            }
            CheckRow { ok: true; text: "Уведомления на часах"
                       hint: "Часы получают уведомления с телефона. Уведомления с ПК на часы идут через телефон: KDE Connect → Android → часы." }
            CheckRow { ok: false; text: "Заряд, пульс, сон, шаги"
                       hint: "Эти данные хранятся в Samsung Health и Health Connect на телефоне. Прямого Linux-доступа нет, а обходить защиту Samsung мы не будем." }
            CheckRow { ok: false; text: "Прямое подключение часов к Linux"
                       hint: "Galaxy Watch сопрягаются только с телефоном. Если часы когда-нибудь появятся в Bluetooth ПК, они отобразятся здесь автоматически." }
        }
    }
}
