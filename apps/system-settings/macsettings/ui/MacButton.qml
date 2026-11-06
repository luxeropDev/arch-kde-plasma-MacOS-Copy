import QtQuick

// Кнопка macOS: обычная (светлая) или основная (акцентная)
Rectangle {
    id: root
    property string text
    property bool primary: false
    signal clicked()

    implicitWidth: label.implicitWidth + 24
    implicitHeight: 24
    radius: 6
    color: primary ? Theme.accent : (hover.hovered ? Theme.fillStrong : Theme.fill)
    border.width: primary ? 0 : 0.5
    border.color: Theme.groupBorder
    opacity: enabled ? (tap.pressed ? 0.75 : 1) : 0.45

    Txt {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: root.primary ? "white" : Theme.text
    }
    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { id: tap; onTapped: root.clicked() }
}
