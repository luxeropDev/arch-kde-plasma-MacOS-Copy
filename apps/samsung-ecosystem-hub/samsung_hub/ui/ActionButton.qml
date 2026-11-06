import QtQuick
import QtQuick.Controls.Basic

// Кнопка действия: primary — залитая акцентом, иначе стеклянная
Button {
    id: root
    property string iconName
    property bool primary: false
    property bool danger: false
    property bool working: false

    implicitHeight: 40
    implicitWidth: row.implicitWidth + 32
    hoverEnabled: true
    opacity: enabled ? 1 : 0.45
    scale: down ? 0.97 : 1
    Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }

    contentItem: Row {
        id: row
        spacing: 8
        anchors.centerIn: parent
        Icon {
            visible: root.iconName !== ""
            anchors.verticalCenter: parent.verticalCenter
            name: root.iconName
            size: 18
            color: root.primary ? "white" : (root.danger ? Theme.bad : Theme.text)
            RotationAnimator on rotation { running: root.working; from: 0; to: 360; duration: 900; loops: Animation.Infinite }
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            color: root.primary ? "white" : (root.danger ? Theme.bad : Theme.text)
            font.family: Theme.font
            font.pixelSize: 14
            font.weight: Font.Medium
        }
    }

    background: Rectangle {
        radius: height / 2
        color: root.primary ? (root.hovered ? Qt.lighter(Theme.accent, 1.1) : Theme.accent)
                            : (root.hovered ? Theme.fillHover : Theme.fill)
        border.width: root.primary ? 0 : 1
        border.color: Theme.hairline
        Behavior on color { ColorAnimation { duration: Theme.anim } }
    }
}
