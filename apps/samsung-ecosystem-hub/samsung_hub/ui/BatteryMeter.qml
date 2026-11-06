import QtQuick

// Заряд показывается только если он реально получен (level >= 0)
Item {
    id: root
    property int level: -1
    property bool charging: false
    property string unavailableText: "Заряд недоступен"

    implicitHeight: 22
    implicitWidth: has ? 130 : label.implicitWidth

    readonly property bool has: level >= 0
    readonly property color tone: level <= 15 ? Theme.bad : (level <= 30 ? Theme.warn : Theme.good)

    Row {
        visible: root.has
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10
        Rectangle {
            width: 70; height: 10; radius: 5
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.fill
            Rectangle {
                width: Math.max(10, parent.width * root.level / 100)
                height: parent.height; radius: 5
                color: root.tone
                Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
            }
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.level + "%" + (root.charging ? " ⚡" : "")
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: 13
            font.weight: Font.DemiBold
        }
    }
    Text {
        id: label
        visible: !root.has
        anchors.verticalCenter: parent.verticalCenter
        text: root.unavailableText
        color: Theme.textDim
        font.family: Theme.font
        font.pixelSize: 12
    }
}
