import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

PaneBase {
    id: root
    paneId: "about"
    signal navigate(string pane)
    readonly property var d: settings.data.about || ({})

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: photo.status === Image.Ready ? 330 : 220
        radius: Theme.radius
        color: Theme.group
        border.width: 0.5; border.color: Theme.groupBorder
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 6
            // Фото модели (официальный снимок ASUS ZenBook 14 UX431DA/UM431DA); если файла нет — значок
            Image {
                id: photo
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 230; Layout.preferredHeight: 230
                source: Qt.resolvedUrl("images/device.png")
                sourceSize: Qt.size(460, 460)
                fillMode: Image.PreserveAspectFit
                smooth: true; mipmap: true
            }
            Kirigami.Icon { visible: photo.status !== Image.Ready; Layout.alignment: Qt.AlignHCenter; implicitWidth: 110; implicitHeight: 110; source: "computer-laptop"; fallback: "computer" }
            Txt { Layout.alignment: Qt.AlignHCenter; text: root.d.model || "Компьютер"; font.pixelSize: 20; font.weight: Font.Bold }
            Txt { Layout.alignment: Qt.AlignHCenter; text: (root.d.os || "") + "  ·  KDE Plasma " + (root.d.plasma || ""); secondary: true }
        }
    }
    Group {
        SettingRow { text: "Имя"; Txt { text: root.d.hostname || ""; secondary: true } }
        SettingRow { text: "Процессор"; Txt { text: root.d.cpu || ""; secondary: true; width: Math.min(implicitWidth, 330) } }
        SettingRow { text: "Память"; Txt { text: (root.d.memory || 0) + " ГБ"; secondary: true } }
        SettingRow { text: "Графика"; Txt { text: root.d.gpu || "—"; secondary: true; width: Math.min(implicitWidth, 330) } }
        SettingRow { text: "Ядро"; Txt { text: root.d.kernel || ""; secondary: true } }
    }
    Group {
        title: "Хранилище"
        SettingRow {
            text: "Системный диск"
            subtitle: "Свободно " + (root.d.diskFree || 0) + " ГБ из " + (root.d.diskTotal || 0) + " ГБ"
            Rectangle {
                width: 200; height: 8; radius: 4; color: Theme.fillStrong
                anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                Rectangle { width: parent.width * (root.d.diskTotal ? root.d.diskUsed / root.d.diskTotal : 0); height: 8; radius: 4
                            color: root.d.diskTotal && root.d.diskFree / root.d.diskTotal < 0.1 ? Theme.bad : Theme.accent }
            }
        }
    }
    RowLayout {
        Layout.alignment: Qt.AlignRight
        MacButton { text: "Отчёт о системе…"; onClicked: settings.openApp("org.kde.kinfocenter") }
    }
}
