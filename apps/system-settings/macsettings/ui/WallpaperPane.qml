import QtQuick
import QtQuick.Layouts

PaneBase {
    id: root
    paneId: "wallpaper"
    signal navigate(string pane)
    readonly property var d: settings.data.wallpaper || ({})
    readonly property var current: (d.items || []).find(w => w.path === d.current || d.current.indexOf(w.path) === 0)

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 150
        radius: Theme.radius
        color: Theme.group
        border.width: 0.5; border.color: Theme.groupBorder
        RowLayout {
            anchors.fill: parent; anchors.margins: 16
            spacing: 16
            Image {
                Layout.preferredWidth: 190; Layout.preferredHeight: 118
                source: root.current ? "file://" + root.current.preview : ""
                sourceSize: Qt.size(380, 236)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                layer.enabled: true
                Rectangle { anchors.fill: parent; color: "transparent"; radius: 8; border.width: 0.5; border.color: Theme.groupBorder }
            }
            ColumnLayout {
                Layout.fillWidth: true
                Txt { text: root.current ? root.current.name : "Обои"; font.pixelSize: 17; font.weight: Font.Bold }
                Txt { text: "Применяются к рабочему столу и экрану блокировки"; secondary: true; wrapMode: Text.WordWrap; elide: Text.ElideNone; Layout.fillWidth: true }
            }
        }
    }
    Txt { text: "Обои"; font.weight: Font.DemiBold }
    GridLayout {
        id: grid
        Layout.fillWidth: true
        columns: 4
        columnSpacing: 12; rowSpacing: 12
        Repeater {
            model: root.d.items || []
            ColumnLayout {
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredWidth: (grid.width - grid.columnSpacing * 3) / 4
                Layout.maximumWidth: Layout.preferredWidth
                spacing: 4
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: width * 0.62
                    radius: 8
                    color: Theme.fill
                    border.width: root.current && root.current.path === modelData.path ? 3 : 0
                    border.color: Theme.accent
                    Image {
                        anchors.fill: parent; anchors.margins: parent.border.width
                        source: "file://" + modelData.preview
                        sourceSize: Qt.size(320, 200)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                    TapHandler { onTapped: settings.call("wallpaper.set", modelData.path) }
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                }
                Txt { Layout.fillWidth: true; text: modelData.name; secondary: true; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter }
            }
        }
    }
    Group {
        SettingRow { text: "Другие обои и слайд-шоу…"; chevron: true; onClicked: settings.openKcm("kcm_wallpaper") }
    }
}
