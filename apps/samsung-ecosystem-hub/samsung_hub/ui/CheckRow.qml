import QtQuick
import QtQuick.Layouts

// Строка чек-листа: зелёная галочка / красный крестик и пояснение
RowLayout {
    id: root
    property bool ok: false
    property string text
    property string hint
    spacing: 12
    Rectangle {
        Layout.preferredWidth: 22; Layout.preferredHeight: 22
        Layout.alignment: Qt.AlignTop
        radius: 11
        color: Qt.rgba(root.ok ? Theme.good.r : Theme.bad.r, root.ok ? Theme.good.g : Theme.bad.g, root.ok ? Theme.good.b : Theme.bad.b, 0.2)
        Text {
            anchors.centerIn: parent
            text: root.ok ? "✓" : "✕"
            color: root.ok ? Theme.good : Theme.bad
            font.pixelSize: 12
            font.bold: true
        }
    }
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2
        Text {
            text: root.text
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: 14
            font.weight: Font.Medium
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }
        Text {
            visible: root.hint !== ""
            text: root.hint
            color: Theme.textDim
            font.family: Theme.font
            font.pixelSize: 12
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }
    }
}
