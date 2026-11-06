import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Dialogs
import QtQuick.Layouts

PageBase {
    id: page
    readonly property var phone: hub.state.phone || ({})
    readonly property bool ready: !!phone.connected && !!(phone.details && phone.details.kdeconnectId)
    readonly property string status: hub.transfer.status || "idle"

    PageHeader { title: "Передача файлов"; subtitle: "Файлы уходят на телефон через KDE Connect" }

    Card {
        id: dropCard
        Layout.fillWidth: true
        Layout.preferredHeight: 260
        padding: 0

        Rectangle {
            anchors.fill: parent
            anchors.margins: 14
            radius: Theme.radius - 6
            color: drop.containsDrag ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.14) : "transparent"
            border.width: 2
            border.color: drop.containsDrag ? Theme.accent : Theme.hairline
            Behavior on color { ColorAnimation { duration: Theme.anim } }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 14
                Icon { Layout.alignment: Qt.AlignHCenter; name: "transfer"; size: 46; color: Theme.accent }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: page.ready ? "Перетащите файлы сюда" : "Телефон не подключён"
                    color: Theme.text
                    font.family: Theme.font; font.pixelSize: 20; font.weight: Font.DemiBold
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: page.ready ? "или выберите их в системном диалоге"
                                     : "Подключите телефон на вкладке Phone (KDE Connect)"
                    color: Theme.textDim
                    font.family: Theme.font; font.pixelSize: 13
                }
                ActionButton {
                    Layout.alignment: Qt.AlignHCenter
                    primary: true
                    text: "Выбрать файлы…"
                    iconName: "file"
                    enabled: page.ready && page.status !== "sending"
                    onClicked: picker.open()
                }
            }
        }
        DropArea {
            id: drop
            anchors.fill: parent
            enabled: page.ready && page.status !== "sending"
            onDropped: (d) => { if (d.hasUrls) hub.shareFiles(d.urls) }
        }
    }

    Card {
        Layout.fillWidth: true
        visible: page.status !== "idle"
        padding: 22
        ColumnLayout {
            anchors.fill: parent
            spacing: 12
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                Rectangle {
                    Layout.preferredWidth: 12; Layout.preferredHeight: 12; radius: 6
                    color: page.status === "done" ? Theme.good : (page.status === "error" ? Theme.bad : Theme.accent)
                }
                Text {
                    text: page.status === "sending" ? "Отправка" : (page.status === "done" ? "Готово" : "Ошибка")
                    color: Theme.text
                    font.family: Theme.font; font.pixelSize: 16; font.weight: Font.DemiBold
                    Layout.fillWidth: true
                }
                ActionButton {
                    visible: page.status !== "sending"
                    text: "Скрыть"
                    onClicked: hub.resetTransfer()
                }
            }
            Rectangle {
                Layout.fillWidth: true
                visible: page.status === "sending"
                height: 6; radius: 3
                color: Theme.fill
                clip: true
                Rectangle {
                    id: bar
                    width: parent.width * 0.3; height: parent.height; radius: 3
                    color: Theme.accent
                    SequentialAnimation on x {
                        running: page.status === "sending"
                        loops: Animation.Infinite
                        NumberAnimation { from: -bar.width; to: bar.parent.width; duration: 1100; easing.type: Easing.InOutQuad }
                    }
                }
            }
            Text {
                text: hub.transfer.message || ""
                color: page.status === "error" ? Theme.bad : Theme.textDim
                font.family: Theme.font; font.pixelSize: 13
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }
    }

    Text {
        text: "KDE Connect передаёт файл в фоне и показывает ход загрузки в своём системном уведомлении, поэтому точный процент здесь не отображается."
        color: Theme.textDim
        font.family: Theme.font; font.pixelSize: 12
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }

    FileDialog {
        id: picker
        title: "Файлы для отправки на телефон"
        fileMode: FileDialog.OpenFiles
        onAccepted: hub.shareFiles(selectedFiles)
    }
}
