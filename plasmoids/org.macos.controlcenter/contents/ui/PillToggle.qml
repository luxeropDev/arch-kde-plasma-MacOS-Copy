import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PC3
import org.kde.kirigami as Kirigami

// Овальная плитка: круглая кнопка слева, название и подпись справа
Tile {
    id: pill

    property string title
    property string subtitle
    property string iconName
    property string fallbackIcon
    property bool checked
    property color accent: "#0a84ff"
    property real glass: 0.07
    signal toggled()
    signal open()

    pill: true
    implicitHeight: Kirigami.Units.gridUnit * 2.9

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Kirigami.Units.smallSpacing * 1.5
        anchors.rightMargin: Kirigami.Units.gridUnit * 0.7
        spacing: Kirigami.Units.smallSpacing * 2

        RoundToggle {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 2.2
            Layout.preferredHeight: Layout.preferredWidth
            checked: pill.checked
            accent: pill.accent
            iconName: pill.iconName
            fallbackIcon: pill.fallbackIcon
            onClicked: pill.toggled()
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            PC3.Label {
                Layout.fillWidth: true
                text: pill.title
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
            PC3.Label {
                Layout.fillWidth: true
                text: pill.subtitle
                opacity: 0.62
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                elide: Text.ElideRight
            }
        }
    }
    TapHandler {
        onTapped: (pt) => { if (pt.position.x > Kirigami.Units.gridUnit * 3) pill.open() }
    }
}
