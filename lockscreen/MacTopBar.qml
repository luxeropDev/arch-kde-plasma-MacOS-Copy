/*
    Верхняя строка экрана блокировки в стиле macOS:
    раскладка, батарея и кнопка питания с «стеклянным» меню (сон / перезагрузка / выключение).
*/

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.workspace.components as PW
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami
import org.kde.breeze.components

Item {
    id: bar

    // SessionManagement из LockScreenUi
    property var session
    property bool menuOpen: false

    implicitHeight: Kirigami.Units.gridUnit * 2
    implicitWidth: row.implicitWidth

    P5Support.DataSource {
        id: exec
        engine: "executable"
        onNewData: (source) => disconnectSource(source)
    }

    RowLayout {
        id: row
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Kirigami.Units.gridUnit * 0.9

        PW.KeyboardLayoutSwitcher {
            id: layoutSwitcher
            visible: hasMultipleKeyboardLayouts
            Layout.preferredWidth: layoutLabel.implicitWidth
            Layout.preferredHeight: layoutLabel.implicitHeight
            acceptedButtons: Qt.LeftButton
            onClicked: keyboardLayout.switchToNextLayout()

            PlasmaComponents3.Label {
                id: layoutLabel
                text: layoutSwitcher.layoutNames.shortName.toUpperCase()
                color: Qt.rgba(1, 1, 1, 0.92)
                font.weight: Font.DemiBold
                textFormat: Text.PlainText
            }
        }

        Battery {
            id: battery
            fontSize: Kirigami.Theme.defaultFont.pointSize
        }

        Item {
            id: powerButton
            Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
            Layout.preferredHeight: Layout.preferredWidth

            Kirigami.Icon {
                anchors.fill: parent
                source: "system-shutdown-symbolic"
                fallback: "system-shutdown"
                isMask: true
                color: Qt.rgba(1, 1, 1, 0.92)
            }
            MouseArea {
                anchors.fill: parent
                anchors.margins: -Kirigami.Units.smallSpacing
                cursorShape: Qt.PointingHandCursor
                onClicked: bar.menuOpen = !bar.menuOpen
            }
        }
    }

    // ---- стеклянное меню питания ----
    Rectangle {
        id: menu
        visible: opacity > 0
        opacity: bar.menuOpen ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }

        anchors.top: row.bottom
        anchors.topMargin: Kirigami.Units.smallSpacing * 2
        anchors.right: row.right
        width: Kirigami.Units.gridUnit * 10
        height: items.implicitHeight + Kirigami.Units.smallSpacing * 3
        radius: Kirigami.Units.gridUnit * 0.8
        color: Qt.rgba(0.97, 0.97, 0.98, 0.78)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.55)

        ColumnLayout {
            id: items
            anchors.fill: parent
            anchors.margins: Kirigami.Units.smallSpacing * 1.5
            spacing: 0

            Repeater {
                model: [
                    { text: "Перезагрузить…", cmd: "systemctl reboot" },
                    { text: "Выключить…",     cmd: "systemctl poweroff" },
                    { text: "Режим сна",      cmd: "" }
                ]

                Rectangle {
                    id: entry
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 1.7
                    radius: 6
                    color: hover.hovered ? "#0a84ff" : "transparent"

                    PlasmaComponents3.Label {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: Kirigami.Units.smallSpacing * 2
                        text: entry.modelData.text
                        color: hover.hovered ? "white" : "#1d1d1f"
                        textFormat: Text.PlainText
                    }
                    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
                    TapHandler {
                        onTapped: {
                            bar.menuOpen = false
                            if (entry.modelData.cmd === "") {
                                if (bar.session) bar.session.suspend()
                            } else {
                                exec.connectSource(entry.modelData.cmd)
                            }
                        }
                    }
                }
            }
        }
    }

    // Клик вне меню закрывает его
    MouseArea {
        z: -1
        enabled: bar.menuOpen
        parent: bar.parent
        anchors.fill: parent
        onClicked: bar.menuOpen = false
    }
}
