import QtQuick

Rectangle {
    id: root
    property string text
    signal clicked()
    width: 28; height: 26; radius: 6
    color: enabled && hover.hovered ? Theme.fill : "transparent"
    opacity: enabled ? 1 : 0.3
    Txt { anchors.centerIn: parent; text: root.text; font.pixelSize: 22; anchors.verticalCenterOffset: -2 }
    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: root.clicked() }
}
