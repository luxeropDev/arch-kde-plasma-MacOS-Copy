import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root
    property string label
    property string value
    property color valueColor: Theme.text
    spacing: 12
    Text {
        text: root.label
        color: Theme.textDim
        font.family: Theme.font
        font.pixelSize: 13
        Layout.preferredWidth: 150
    }
    Text {
        text: root.value
        color: root.valueColor
        font.family: Theme.font
        font.pixelSize: 13
        font.weight: Font.Medium
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }
}
