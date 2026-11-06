import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root
    property string title
    property string subtitle
    spacing: 4
    Text {
        text: root.title
        color: Theme.text
        font.family: Theme.font
        font.pixelSize: 34
        font.weight: Font.Bold
        font.letterSpacing: -0.6
    }
    Text {
        visible: root.subtitle !== ""
        text: root.subtitle
        color: Theme.textDim
        font.family: Theme.font
        font.pixelSize: 15
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }
}
