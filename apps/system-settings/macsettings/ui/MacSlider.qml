import QtQuick

// Тонкий слайдер macOS: акцентная заливка и белая круглая ручка
Item {
    id: root
    property real value: 0
    property real from: 0
    property real to: 1
    property real stepSize: 0
    property bool live: false              // отправлять значения во время перетаскивания
    readonly property bool pressed: mouse.pressed
    signal moved(real value)
    signal released(real value)

    implicitWidth: 220; implicitHeight: 22
    readonly property real pos: (value - from) / (to - from)

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        x: knob.width / 2; width: parent.width - knob.width
        height: 4; radius: 2
        color: Theme.fillStrong
        Rectangle { width: parent.width * Math.max(0, Math.min(1, root.pos)); height: parent.height; radius: 2; color: Theme.accent }
    }
    Rectangle {
        id: knob
        width: 20; height: 20; radius: 10
        anchors.verticalCenter: parent.verticalCenter
        x: (root.width - width) * Math.max(0, Math.min(1, root.pos))
        color: "white"
        border.width: 0.5
        border.color: Qt.rgba(0, 0, 0, 0.18)
        scale: mouse.pressed ? 1.08 : 1
        Behavior on scale { NumberAnimation { duration: 90 } }
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        function apply(x) {
            let p = Math.max(0, Math.min(1, (x - knob.width / 2) / (root.width - knob.width)))
            let v = root.from + p * (root.to - root.from)
            if (root.stepSize > 0) v = Math.round(v / root.stepSize) * root.stepSize
            root.value = v
            if (root.live) root.moved(v)
        }
        onPressed: (e) => apply(e.x)
        onPositionChanged: (e) => { if (pressed) apply(e.x) }
        onReleased: { root.moved(root.value); root.released(root.value) }
    }
}
