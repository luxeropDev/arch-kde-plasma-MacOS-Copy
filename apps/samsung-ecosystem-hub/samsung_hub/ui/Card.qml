import QtQuick
import QtQuick.Effects

// Полупрозрачная карточка с кромкой, бликом и мягкой тенью
Item {
    id: root
    property bool hoverable: false
    property alias contentItem: surface
    property real padding: 20
    default property alias content: inner.data
    readonly property bool hovered: hover.hovered

    implicitHeight: inner.implicitHeight + padding * 2
    implicitWidth: inner.implicitWidth + padding * 2

    Rectangle {
        id: surface
        anchors.fill: parent
        radius: Theme.radius
        color: root.hoverable && hover.hovered ? Theme.cardHover : Theme.card
        border.width: 1
        border.color: Theme.border
        Behavior on color { ColorAnimation { duration: Theme.anim } }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Theme.shadowSoft
            shadowBlur: 0.9
            shadowVerticalOffset: 6
            shadowOpacity: Theme.dark ? 0.6 : 0.5
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: parent.radius - 1
            gradient: Gradient {
                GradientStop { position: 0.0; color: Theme.dark ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(1, 1, 1, 0.5) }
                GradientStop { position: 0.45; color: "transparent" }
            }
        }
    }

    Item {
        id: inner
        anchors.fill: parent
        anchors.margins: root.padding
        implicitWidth: children.length ? children[0].implicitWidth : 0
        implicitHeight: children.length ? children[0].implicitHeight : 0
    }

    HoverHandler { id: hover }
}
