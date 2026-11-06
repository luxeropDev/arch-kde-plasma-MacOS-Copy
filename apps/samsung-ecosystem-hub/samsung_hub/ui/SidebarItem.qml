import QtQuick

Item {
    id: root
    property string iconName
    property string text
    property bool selected: false
    property bool compact: false
    signal clicked()

    implicitHeight: 44
    implicitWidth: 200

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: root.selected ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, Theme.dark ? 0.28 : 0.16)
                             : (hover.hovered ? Theme.fill : "transparent")
        Behavior on color { ColorAnimation { duration: Theme.anim } }
    }
    Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: root.compact ? (root.width - 20) / 2 : 14
        spacing: 12
        Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: root.iconName
            size: 20
            color: root.selected ? Theme.accent : Theme.textDim
        }
        Text {
            visible: !root.compact
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            color: root.selected ? Theme.text : Theme.textDim
            font.family: Theme.font
            font.pixelSize: 14
            font.weight: root.selected ? Font.DemiBold : Font.Normal
        }
    }
    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: root.clicked() }
    Accessible.role: Accessible.Button
    Accessible.name: root.text
}
