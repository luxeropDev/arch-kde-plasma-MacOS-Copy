import QtQuick
import QtQuick.Layouts

// Всплывающее уведомление внизу окна
Item {
    id: root
    property string kind: "info"
    property string message: ""

    function show(k, text) {
        kind = k
        message = text
        hideTimer.restart()
        pill.opacity = 1
        pill.y = 0
    }

    width: parent ? parent.width : 400
    height: 60
    anchors.bottom: parent ? parent.bottom : undefined
    anchors.bottomMargin: 20
    z: 100

    Rectangle {
        id: pill
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(root.width - 48, row.implicitWidth + 36)
        height: 46
        radius: 23
        opacity: 0
        y: 14
        color: Theme.dark ? "#2b2d3a" : "#ffffff"
        border.width: 1
        border.color: Theme.hairline
        Behavior on opacity { NumberAnimation { duration: 180 } }
        Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 10
            Rectangle {
                width: 10; height: 10; radius: 5
                anchors.verticalCenter: parent.verticalCenter
                color: root.kind === "ok" ? Theme.good : (root.kind === "error" ? Theme.bad : Theme.accent)
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.message
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: 13
                font.weight: Font.Medium
                elide: Text.ElideRight
                width: Math.min(implicitWidth, root.width - 120)
            }
        }
    }
    Timer {
        id: hideTimer
        interval: 4200
        onTriggered: { pill.opacity = 0; pill.y = 14 }
    }
}
