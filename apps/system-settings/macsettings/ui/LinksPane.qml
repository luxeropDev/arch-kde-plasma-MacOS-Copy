import QtQuick
import QtQuick.Layouts

// Раздел-«каталог»: шапка и строки, открывающие модули настроек KDE
PaneBase {
    id: root
    property var spec: ({ rows: [] })
    property var info: ({})
    signal navigate(string pane)

    PaneHeader {
        visible: !root.spec.user
        icon: root.info.icon || ""
        tint: root.info.tint || "#8e8e93"
        title: root.info.name || ""
        description: root.spec.description || ""
    }
    Rectangle {
        visible: !!root.spec.user
        Layout.fillWidth: true
        implicitHeight: 150
        radius: Theme.radius
        color: Theme.group
        border.width: 0.5; border.color: Theme.groupBorder
        readonly property var user: settings.data.user || ({})
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 6
            Avatar { Layout.alignment: Qt.AlignHCenter; size: 72; user: parent.parent.user }
            Txt { Layout.alignment: Qt.AlignHCenter; text: parent.parent.user.name || ""; font.pixelSize: 18; font.weight: Font.Bold }
            Txt { Layout.alignment: Qt.AlignHCenter; text: "Логин: " + (parent.parent.user.login || ""); secondary: true }
        }
    }
    Group {
        Repeater {
            model: root.spec.rows
            SettingRow {
                required property var modelData
                text: modelData.text
                subtitle: modelData.subtitle || ""
                icon: modelData.icon || ""
                tint: modelData.tint || "#8e8e93"
                chevron: true
                onClicked: modelData.pane ? root.navigate(modelData.pane) : settings.openKcm(modelData.kcm)
            }
        }
    }
    Txt {
        Layout.fillWidth: true
        visible: root.spec.rows.some(r => r.kcm)
        text: "Пункты со стрелкой открывают соответствующий модуль настроек KDE."
        secondary: true
        font.pixelSize: 11
        horizontalAlignment: Text.AlignHCenter
    }
}
