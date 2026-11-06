import QtQuick

// Индикатор реального состояния связи
Rectangle {
    id: root
    property string state: "unavailable"     // connected | available | unavailable | via_phone

    readonly property color tone: state === "connected" ? Theme.good
                                : state === "available" ? Theme.warn
                                : state === "via_phone" ? Theme.accent : Theme.textDim
    readonly property string label: state === "connected" ? "Подключено"
                                  : state === "available" ? "Не подключено"
                                  : state === "via_phone" ? "Через телефон" : "Не найдено"

    implicitHeight: 26
    implicitWidth: row.implicitWidth + 20
    radius: height / 2
    color: Qt.rgba(tone.r, tone.g, tone.b, 0.16)

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 7
        Rectangle {
            width: 8; height: 8; radius: 4
            anchors.verticalCenter: parent.verticalCenter
            color: root.tone
            SequentialAnimation on opacity {
                running: root.state === "connected"
                loops: Animation.Infinite
                NumberAnimation { to: 0.35; duration: 900; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0; duration: 900; easing.type: Easing.InOutSine }
            }
        }
        Text {
            text: root.label
            color: root.tone
            font.family: Theme.font
            font.pixelSize: 12
            font.weight: Font.DemiBold
        }
    }
}
