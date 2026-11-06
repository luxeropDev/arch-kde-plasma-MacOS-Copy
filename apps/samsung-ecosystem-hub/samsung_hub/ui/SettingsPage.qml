import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

PageBase {
    id: page
    readonly property var diag: hub.diagnostics
    property bool showLog: false

    Component.onCompleted: hub.refreshDiagnostics()

    PageHeader { title: "Настройки"; subtitle: "Оформление, интеграции, диагностика и журнал" }

    // ---- оформление и запуск ----
    Card {
        Layout.fillWidth: true
        padding: 24
        ColumnLayout {
            anchors.fill: parent
            spacing: 18
            Text { text: "Оформление"; color: Theme.text; font.family: Theme.font; font.pixelSize: 17; font.weight: Font.DemiBold }
            Row {
                spacing: 8
                Repeater {
                    model: [{ id: "system", name: "Системная" }, { id: "light", name: "Светлая" }, { id: "dark", name: "Тёмная" }]
                    ActionButton {
                        required property var modelData
                        text: modelData.name
                        primary: hub.theme === modelData.id
                        onClicked: hub.setTheme(modelData.id)
                    }
                }
            }
            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.hairline }
            SwitchRow {
                Layout.fillWidth: true
                title: "Запускать при входе в систему"
                subtitle: "Приложение стартует свёрнутым в трей"
                checked: hub.autostart
                onToggledByUser: (v) => hub.setAutostart(v)
            }
            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.hairline }
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Обновлять состояние каждые"
                    color: Theme.text; font.family: Theme.font; font.pixelSize: 15; font.weight: Font.Medium
                    Layout.fillWidth: true
                }
                SpinBox {
                    id: spin
                    from: 3; to: 120; value: hub.refreshSeconds
                    editable: false
                    onValueModified: hub.setRefreshSeconds(value)
                    textFromValue: (v) => v + " с"
                    contentItem: Text {
                        text: spin.textFromValue(spin.value)
                        color: Theme.text
                        font.family: Theme.font; font.pixelSize: 14; font.weight: Font.Medium
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle { implicitWidth: 130; implicitHeight: 38; radius: 19; color: Theme.fill }
                    up.indicator: Text {
                        x: spin.width - width - 14; anchors.verticalCenter: parent.verticalCenter
                        text: "+"; color: Theme.text; font.pixelSize: 20
                    }
                    down.indicator: Text {
                        x: 14; anchors.verticalCenter: parent.verticalCenter
                        text: "−"; color: Theme.text; font.pixelSize: 20
                    }
                }
            }
        }
    }

    // ---- интеграции ----
    Card {
        Layout.fillWidth: true
        padding: 24
        ColumnLayout {
            anchors.fill: parent
            spacing: 14
            RowLayout {
                Layout.fillWidth: true
                Text { text: "Интеграции и диагностика"; color: Theme.text; font.family: Theme.font; font.pixelSize: 17; font.weight: Font.DemiBold; Layout.fillWidth: true }
                ActionButton { text: "Проверить"; iconName: "refresh"; onClicked: hub.refreshDiagnostics() }
            }
            Repeater {
                model: diag.tools || []
                CheckRow {
                    required property var modelData
                    Layout.fillWidth: true
                    ok: modelData.present
                    text: modelData.command + " — " + modelData.purpose
                    hint: modelData.present ? "" : "Пакет: " + modelData.package
                }
            }
            CheckRow { Layout.fillWidth: true; ok: !!diag.budsClient; text: "GalaxyBudsClient (Flatpak)"; hint: diag.budsClient ? "" : "flatpak install flathub me.timschneeberger.GalaxyBudsClient" }
            Text {
                visible: (diag.missing || []).length > 0
                text: "Чтобы поставить недостающее, выполните в терминале:\nsudo pacman -S --needed " + (diag.missing || []).join(" ")
                color: Theme.warn
                font.family: "monospace"; font.pixelSize: 12
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
            InfoRow { label: "Сессия"; value: (diag.session ? diag.session.session + " · " + diag.session.desktop : "") }
            InfoRow { label: "Брандмауэр"; value: diag.firewall || "—" }
        }
    }

    // ---- журнал ----
    Card {
        Layout.fillWidth: true
        padding: 24
        ColumnLayout {
            anchors.fill: parent
            spacing: 12
            RowLayout {
                Layout.fillWidth: true
                Text { text: "Журнал"; color: Theme.text; font.family: Theme.font; font.pixelSize: 17; font.weight: Font.DemiBold; Layout.fillWidth: true }
                ActionButton { text: page.showLog ? "Скрыть" : "Показать"; onClicked: { page.showLog = !page.showLog; if (page.showLog) hub.refreshLog() } }
                ActionButton { text: "Папка"; onClicked: hub.openLogFolder() }
            }
            ScrollView {
                visible: page.showLog
                Layout.fillWidth: true
                Layout.preferredHeight: 220
                clip: true
                TextArea {
                    readOnly: true
                    text: hub.logText
                    color: Theme.text
                    font.family: "monospace"; font.pixelSize: 11
                    wrapMode: TextEdit.NoWrap
                    background: Rectangle { radius: 12; color: Theme.fill }
                }
            }
            Text {
                text: "Файл: " + hub.logPath
                color: Theme.textDim; font.family: Theme.font; font.pixelSize: 11
            }
        }
    }

    // ---- конфиденциальность ----
    Card {
        Layout.fillWidth: true
        padding: 24
        ColumnLayout {
            anchors.fill: parent
            spacing: 8
            Text { text: "Конфиденциальность"; color: Theme.text; font.family: Theme.font; font.pixelSize: 17; font.weight: Font.DemiBold }
            Repeater {
                model: [
                    "Приложение работает только локально: никаких серверов, аккаунтов и телеметрии.",
                    "Запускается без прав root и не открывает сетевых портов.",
                    "В журнале MAC-адреса и идентификаторы устройств маскируются.",
                    "Пароли, ADB-ключи и данные Samsung Health приложением не читаются и не сохраняются."
                ]
                Text {
                    required property string modelData
                    text: "•  " + modelData
                    color: Theme.textDim
                    font.family: Theme.font; font.pixelSize: 13
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
            Text {
                text: hub.appName + " " + hub.version
                color: Theme.textDim; opacity: 0.7
                font.family: Theme.font; font.pixelSize: 11
                Layout.topMargin: 8
            }
        }
    }
}
