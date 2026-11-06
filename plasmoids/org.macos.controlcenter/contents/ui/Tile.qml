import QtQuick
import org.kde.kirigami as Kirigami

// Стеклянная плитка: полупрозрачная заливка, светлая кромка и верхний блик
Rectangle {
    id: tile

    property real glass: 0.10
    property bool pill: false

    radius: pill ? height / 2 : Kirigami.Units.gridUnit * 1.05
    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, glass)
    border.width: 1
    border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.16)

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: parent.radius - 1
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.07) }
            GradientStop { position: 0.5; color: "transparent" }
        }
    }
}
