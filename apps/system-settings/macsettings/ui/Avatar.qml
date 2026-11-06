import QtQuick
import QtQuick.Effects

// Аватар: фото пользователя или инициалы на градиенте
Item {
    id: root
    property var user: ({})
    property int size: 40
    implicitWidth: size; implicitHeight: size

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        visible: img.status !== Image.Ready
        gradient: Gradient {
            GradientStop { position: 0; color: "#a0a4ad" }
            GradientStop { position: 1; color: "#6e727b" }
        }
        Txt {
            anchors.centerIn: parent
            text: (root.user.name || "?").split(" ").map(w => w.charAt(0)).join("").slice(0, 2).toUpperCase()
            color: "white"
            font.pixelSize: root.size * 0.4
            font.weight: Font.DemiBold
        }
    }
    Image {
        id: img
        anchors.fill: parent
        source: root.user.avatar ? "file://" + root.user.avatar : ""
        sourceSize: Qt.size(root.size * 2, root.size * 2)
        fillMode: Image.PreserveAspectCrop
        visible: false
    }
    MultiEffect {
        anchors.fill: img
        source: img
        visible: img.status === Image.Ready
        maskEnabled: true
        maskSource: ShaderEffectSource {
            sourceItem: Rectangle { width: root.size; height: root.size; radius: root.size / 2 }
            hideSource: true
        }
    }
}
