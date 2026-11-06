import QtQuick

// Переключатель macOS: акцентный, когда включён
Item {
    id: root
    property bool checked: false
    signal toggled(bool value)

    implicitWidth: 38; implicitHeight: 22
    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? Theme.accent : Theme.fillStrong
        Behavior on color { ColorAnimation { duration: 140 } }
        Rectangle {
            width: parent.height - 4; height: width; radius: width / 2
            y: 2
            x: root.checked ? parent.width - width - 2 : 2
            color: "white"
            border.width: 0.5
            border.color: Qt.rgba(0, 0, 0, 0.12)
            Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        }
    }
    TapHandler { onTapped: { root.checked = !root.checked; root.toggled(root.checked) } }
    HoverHandler { cursorShape: Qt.PointingHandCursor }
}
