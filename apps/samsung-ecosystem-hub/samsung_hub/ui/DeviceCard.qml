import QtQuick
import QtQuick.Layouts

// Карточка устройства на главном экране
Card {
    id: root
    property var device: ({})
    property string iconName
    property color tint: Theme.accent
    property string primaryText
    property string primaryIcon
    property bool primaryEnabled: true
    property bool showBattery: true
    signal primaryClicked()
    signal openClicked()

    hoverable: true
    padding: 22

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            spacing: 14
            Rectangle {
                Layout.preferredWidth: 52; Layout.preferredHeight: 52
                radius: 17
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0; color: Qt.lighter(root.tint, 1.25) }
                    GradientStop { position: 1; color: root.tint }
                }
                Icon { anchors.centerIn: parent; name: root.iconName; size: 28; color: "white" }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Text {
                    text: root.device.title || ""
                    color: Theme.text
                    font.family: Theme.font; font.pixelSize: 18; font.weight: Font.DemiBold
                }
                Text {
                    text: root.device.name ? root.device.name : "Не определено"
                    color: Theme.textDim
                    font.family: Theme.font; font.pixelSize: 13
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
        }

        StatusBadge { state: root.device.state || "unavailable" }

        BatteryMeter {
            visible: root.showBattery
            level: root.device.battery === undefined ? -1 : root.device.battery
            charging: !!root.device.charging
        }

        Text {
            text: root.device.message || ""
            color: Theme.textDim
            font.family: Theme.font; font.pixelSize: 12
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.minimumHeight: 48
            maximumLineCount: 4
            elide: Text.ElideRight
        }

        Text {
            text: root.device.source ? "Источник: " + root.device.source : ""
            visible: text !== ""
            color: Theme.textDim; opacity: 0.8
            font.family: Theme.font; font.pixelSize: 11
        }

        Flow {
            Layout.fillWidth: true
            spacing: 10
            ActionButton {
                visible: root.primaryText !== ""
                enabled: root.primaryEnabled
                primary: true
                text: root.primaryText
                iconName: root.primaryIcon
                onClicked: root.primaryClicked()
            }
            ActionButton {
                text: "Подробнее"
                onClicked: root.openClicked()
            }
        }
    }
}
