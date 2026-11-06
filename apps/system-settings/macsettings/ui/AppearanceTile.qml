import QtQuick
import QtQuick.Layouts

// Миниатюра окна для выбора «Авто / Светлое / Тёмное»
ColumnLayout {
    id: root
    property string mode
    property string label
    property bool selected
    signal clicked()
    spacing: 6

    Rectangle {
        Layout.preferredWidth: 96; Layout.preferredHeight: 64
        radius: 8
        border.width: root.selected ? 3 : 0.5
        border.color: root.selected ? Theme.accent : Theme.groupBorder
        clip: true
        Row {
            anchors.fill: parent; anchors.margins: root.selected ? 3 : 1
            Rectangle { width: root.mode === "auto" ? parent.width / 2 : parent.width; height: parent.height
                        color: root.mode === "dark" ? "#1c1c1e" : "#e9e9ee"; radius: 5
                        Rectangle { x: 8; y: 8; width: 34; height: 22; radius: 3; color: root.mode === "dark" ? "#3a3a3c" : "white" }
                        Rectangle { x: 8; y: 34; width: 24; height: 4; radius: 2; color: Theme.accent } }
            Rectangle { visible: root.mode === "auto"; width: parent.width / 2; height: parent.height; color: "#1c1c1e"; radius: 5
                        Rectangle { x: 4; y: 8; width: 34; height: 22; radius: 3; color: "#3a3a3c" } }
        }
        TapHandler { onTapped: root.clicked() }
        HoverHandler { cursorShape: Qt.PointingHandCursor }
    }
    Txt { Layout.alignment: Qt.AlignHCenter; text: root.label; font.weight: root.selected ? Font.DemiBold : Font.Normal }
}
