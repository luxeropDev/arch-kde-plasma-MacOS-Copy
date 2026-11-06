import QtQuick
import QtQuick.Layouts

PageBase {
    id: page
    signal navigate(int index)

    readonly property var st: hub.state
    readonly property var phone: st.phone || ({})
    readonly property bool paired: !!(phone.details && phone.details.kdeconnectId) && phone.state === "connected"
    readonly property bool hasKc: !!(phone.details && phone.details.kdeconnectId)

    PageHeader { title: "Galaxy Phone"; subtitle: "Связь с телефоном через KDE Connect и ADB" }

    Card {
        Layout.fillWidth: true
        padding: 24
        ColumnLayout {
            anchors.fill: parent
            spacing: 16
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: phone.name || "Телефон не найден"
                    color: Theme.text
                    font.family: Theme.font; font.pixelSize: 22; font.weight: Font.DemiBold
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
                StatusBadge { state: phone.state || "unavailable" }
            }
            BatteryMeter { level: phone.battery === undefined ? -1 : phone.battery; charging: !!phone.charging }
            Text {
                text: phone.message || ""
                color: Theme.textDim
                font.family: Theme.font; font.pixelSize: 13
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
            InfoRow { label: "Источник данных"; value: phone.source || "—" }
            InfoRow { label: "KDE Connect"; value: st.kdeconnectAvailable ? "установлен" : "не установлен"
                      valueColor: st.kdeconnectAvailable ? Theme.good : Theme.bad }
            Flow {
                Layout.fillWidth: true
                spacing: 10
                ActionButton {
                    visible: page.hasKc && !page.paired
                    primary: true; text: "Сопрячь"; iconName: "link"
                    onClicked: hub.pairPhone()
                }
                ActionButton { visible: page.paired; text: "Пинг"; iconName: "bell"; onClicked: hub.pingPhone() }
                ActionButton { visible: page.paired; text: "Найти телефон"; iconName: "bell-ring"; onClicked: hub.ringPhone() }
                ActionButton { visible: page.paired; text: "Отправить буфер обмена"; iconName: "clipboard"; onClicked: hub.sendClipboard() }
                ActionButton { visible: page.paired; text: "Отправить файл"; iconName: "transfer"; onClicked: page.navigate(4) }
                ActionButton { visible: page.paired; text: "Разорвать сопряжение"; danger: true; onClicked: hub.unpairPhone() }
            }
        }
    }

    // ---- уведомления ----
    Card {
        Layout.fillWidth: true
        padding: 24
        ColumnLayout {
            anchors.fill: parent
            spacing: 12
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Уведомления телефона"
                    color: Theme.text
                    font.family: Theme.font; font.pixelSize: 17; font.weight: Font.DemiBold
                    Layout.fillWidth: true
                }
                ActionButton { text: "Загрузить"; iconName: "bell"; enabled: page.paired; onClicked: hub.loadNotifications() }
            }
            Text {
                text: hub.notificationsText !== "" ? hub.notificationsText
                      : "Уведомления с телефона KDE Connect показывает как системные уведомления Plasma. Здесь можно запросить список текущих."
                color: Theme.textDim
                font.family: Theme.font; font.pixelSize: 12
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }
    }

    // ---- что доступно ----
    Card {
        Layout.fillWidth: true
        padding: 24
        ColumnLayout {
            anchors.fill: parent
            spacing: 14
            Text {
                text: "Доступные функции"
                color: Theme.text
                font.family: Theme.font; font.pixelSize: 17; font.weight: Font.DemiBold
            }
            CheckRow { ok: st.kdeconnectAvailable && page.paired; text: "Уведомления, буфер обмена, файлы"
                       hint: "Работают через KDE Connect после сопряжения. Android разрешает читать буфер обмена только при открытом приложении." }
            CheckRow { ok: !!st.scrcpyAvailable && !!st.adbAvailable; text: "Зеркалирование экрана"
                       hint: "Нужны scrcpy и android-tools, а на телефоне — включённая вами USB-отладка." }
            CheckRow { ok: phone.battery !== undefined && phone.battery >= 0; text: "Заряд телефона"
                       hint: "Передаётся плагином «Батарея» KDE Connect или по ADB." }
        }
    }
}
