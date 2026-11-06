import QtQuick
import org.kde.kirigami as Kirigami

// Цветной скруглённый квадрат с белым символом — как значки разделов macOS
Rectangle {
    id: root
    property string icon
    property string fallback: "preferences-system"
    property color tint: "#8e8e93"
    property int size: 22

    width: size; height: size
    radius: size * 0.27
    gradient: Gradient {
        GradientStop { position: 0; color: Qt.lighter(root.tint, 1.18) }
        GradientStop { position: 1; color: root.tint }
    }
    Kirigami.Icon {
        anchors.centerIn: parent
        width: root.size * 0.68; height: width
        source: root.icon
        fallback: root.fallback
        isMask: true
        color: "white"
    }
}
