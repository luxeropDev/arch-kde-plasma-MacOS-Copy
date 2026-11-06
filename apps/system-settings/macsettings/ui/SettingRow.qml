import QtQuick
import QtQuick.Layouts

// Строка настройки: значок (необязательно), подпись и подсказка слева, элемент управления справа
Item {
    id: root
    default property alias control: slot.data
    property string text
    property string subtitle
    property string icon
    property color tint: "#8e8e93"
    property bool separator: true
    property bool chevron: false
    signal clicked()

    Layout.fillWidth: true
    implicitHeight: Math.max(Theme.rowHeight, labels.implicitHeight + 16)

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: Theme.radius - 1
        color: root.chevron && hover.hovered ? Theme.fill : "transparent"
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 10

        SymbolIcon { visible: root.icon !== ""; icon: root.icon; tint: root.tint; size: 26 }
        ColumnLayout {
            id: labels
            Layout.fillWidth: true
            spacing: 1
            Txt { Layout.fillWidth: true; text: root.text }
            Txt {
                Layout.fillWidth: true
                visible: root.subtitle !== ""
                text: root.subtitle
                secondary: true
                font.pixelSize: 11
                wrapMode: Text.WordWrap
                elide: Text.ElideNone
            }
        }
        Row { id: slot; spacing: 8; Layout.alignment: Qt.AlignVCenter }
        Txt { visible: root.chevron; text: "›"; font.pixelSize: 18; secondary: true }
    }

    Rectangle {
        visible: root.separator
        anchors.bottom: parent.bottom
        x: root.icon !== "" ? 48 : 12
        width: parent.width - x - 12
        height: 1
        color: Theme.separator
    }

    HoverHandler { id: hover; enabled: root.chevron; cursorShape: Qt.PointingHandCursor }
    TapHandler { enabled: root.chevron; onTapped: root.clicked() }
}
