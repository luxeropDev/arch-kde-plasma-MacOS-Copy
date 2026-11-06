import QtQuick
import org.kde.kirigami as Kirigami

// Толстый слайдер со значком внутри, белая ручка — как в macOS
Item {
    id: slider

    property real value: 0          // 0..1
    property string iconName
    property string fallbackIcon: "configure"
    property bool dimmed: false
    readonly property bool dragging: mouse.pressed
    signal moved(real value)
    signal iconClicked()

    implicitHeight: Kirigami.Units.gridUnit * 1.55

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.14)
        border.width: 1
        border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08)
        clip: true

        Rectangle {
            height: parent.height
            radius: height / 2
            width: Math.max(height, parent.width * Math.max(0, Math.min(1, slider.value)))
            color: Qt.rgba(1, 1, 1, slider.dimmed ? 0.35 : 0.95)
            Behavior on width { enabled: !slider.dragging; NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        function update(x) {
            const v = Math.max(0, Math.min(1, (x - height / 2) / (width - height)))
            slider.value = v
            slider.moved(v)
        }
        onPressed: (ev) => {
            if (ev.x < icon.x + icon.width + 4) { slider.iconClicked(); ev.accepted = false; return }
            update(ev.x)
        }
        onPositionChanged: (ev) => { if (pressed) update(ev.x) }
        onWheel: (ev) => {
            const v = Math.max(0, Math.min(1, slider.value + (ev.angleDelta.y > 0 ? 0.05 : -0.05)))
            slider.value = v
            slider.moved(v)
        }
    }

    Kirigami.Icon {
        id: icon
        anchors.left: parent.left
        anchors.leftMargin: (slider.height - width) / 2 + 1
        anchors.verticalCenter: parent.verticalCenter
        width: Kirigami.Units.iconSizes.small
        height: width
        source: slider.iconName
        fallback: slider.fallbackIcon
        isMask: true
        color: slider.value > 0.08 && !slider.dimmed ? "#2b2b2b" : Kirigami.Theme.textColor
        MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            cursorShape: Qt.PointingHandCursor
            onClicked: slider.iconClicked()
        }
    }
}
