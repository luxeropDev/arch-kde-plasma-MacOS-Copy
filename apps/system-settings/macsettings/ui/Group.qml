import QtQuick
import QtQuick.Layouts

// Скруглённая группа строк — основной блок настроек macOS. У последней строки разделитель скрывается сам.
ColumnLayout {
    id: root
    default property alias rows: column.data
    property string title
    property string footer

    Layout.fillWidth: true
    spacing: 6

    function updateSeparators() {
        let visibleRows = []
        for (let i = 0; i < column.children.length; i++) {
            const c = column.children[i]
            if (c.visible && c.separator !== undefined) visibleRows.push(c)
        }
        visibleRows.forEach((c, i) => c.separator = i < visibleRows.length - 1)
    }

    Txt {
        visible: root.title !== ""
        text: root.title
        font.weight: Font.DemiBold
        Layout.leftMargin: 2
    }
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: column.implicitHeight
        radius: Theme.radius
        color: Theme.group
        border.width: 0.5
        border.color: Theme.groupBorder
        ColumnLayout {
            id: column
            width: parent.width
            spacing: 0
            onChildrenChanged: Qt.callLater(root.updateSeparators)
        }
    }
    Txt {
        visible: root.footer !== ""
        text: root.footer
        secondary: true
        font.pixelSize: 11
        wrapMode: Text.WordWrap
        elide: Text.ElideNone
        Layout.fillWidth: true
        Layout.leftMargin: 2
    }
}
