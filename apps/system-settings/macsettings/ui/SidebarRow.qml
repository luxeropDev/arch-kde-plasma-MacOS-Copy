import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property var item: ({})
    property bool selected: false
    signal clicked()

    implicitHeight: 30
    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: 8; anchors.rightMargin: 8
        radius: 7
        color: root.selected ? Theme.selection : (hover.hovered ? Theme.fill : "transparent")
    }
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14; anchors.rightMargin: 14
        spacing: 8
        SymbolIcon { icon: root.item.icon || ""; tint: root.item.tint || "#8e8e93"; size: 20 }
        Txt {
            Layout.fillWidth: true
            text: root.item.name || ""
            color: root.selected ? "white" : Theme.text
        }
    }
    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: root.clicked() }
}
