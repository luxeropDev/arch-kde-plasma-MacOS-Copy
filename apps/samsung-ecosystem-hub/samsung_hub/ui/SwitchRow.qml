import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

RowLayout {
    id: root
    property string title
    property string subtitle
    property alias checked: sw.checked
    signal toggledByUser(bool value)
    spacing: 16
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2
        Text { text: root.title; color: Theme.text; font.family: Theme.font; font.pixelSize: 15; font.weight: Font.Medium }
        Text {
            visible: root.subtitle !== ""
            text: root.subtitle
            color: Theme.textDim
            font.family: Theme.font
            font.pixelSize: 12
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }
    Switch {
        id: sw
        onToggled: root.toggledByUser(checked)
        indicator: Rectangle {
            implicitWidth: 50; implicitHeight: 30
            x: sw.leftPadding; y: (sw.height - height) / 2
            radius: height / 2
            color: sw.checked ? Theme.good : Theme.fillHover
            Behavior on color { ColorAnimation { duration: Theme.anim } }
            Rectangle {
                width: 26; height: 26; radius: 13
                y: 2
                x: sw.checked ? parent.width - width - 2 : 2
                color: "white"
                Behavior on x { NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic } }
            }
        }
    }
}
