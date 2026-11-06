import QtQuick
import QtQuick.Layouts

// Крупная шапка раздела: значок, название и описание (как в macOS 26/27)
Rectangle {
    id: root
    property string icon
    property color tint: "#8e8e93"
    property string title
    property string description

    Layout.fillWidth: true
    implicitHeight: col.implicitHeight + 36
    radius: Theme.radius
    color: Theme.group
    border.width: 0.5
    border.color: Theme.groupBorder

    ColumnLayout {
        id: col
        anchors.centerIn: parent
        width: parent.width - 48
        spacing: 8
        SymbolIcon { Layout.alignment: Qt.AlignHCenter; icon: root.icon; tint: root.tint; size: 56 }
        Txt {
            Layout.alignment: Qt.AlignHCenter
            text: root.title
            font.pixelSize: 20
            font.weight: Font.Bold
        }
        Txt {
            Layout.fillWidth: true
            visible: root.description !== ""
            text: root.description
            secondary: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            elide: Text.ElideNone
        }
    }
}
