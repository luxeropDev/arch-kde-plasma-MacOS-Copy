import QtQuick
import org.kde.kirigami as Kirigami

// Круглая кнопка: белая (как в macOS) или цветная, когда включена
Rectangle {
    id: toggle

    property bool checked: false
    property string iconName
    property string fallbackIcon: "emblem-symbolic-link"
    property color accent: "#0a84ff"
    property color checkedIconColor: "white"
    property real iconScale: 1
    signal clicked()

    implicitWidth: Kirigami.Units.gridUnit * 2.1
    implicitHeight: implicitWidth
    radius: width / 2
    color: checked ? accent
                   : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, mouse.containsMouse ? 0.26 : 0.17)
    border.width: 1
    border.color: Qt.rgba(1, 1, 1, checked ? 0.25 : 0.12)
    Behavior on color { ColorAnimation { duration: 140 } }

    scale: mouse.pressed ? 0.92 : 1
    Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }

    Kirigami.Icon {
        anchors.centerIn: parent
        width: Kirigami.Units.iconSizes.small * toggle.iconScale
        height: width
        source: toggle.iconName
        fallback: toggle.fallbackIcon
        isMask: true
        color: toggle.checked ? toggle.checkedIconColor : Kirigami.Theme.textColor
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: toggle.clicked()
    }
}
