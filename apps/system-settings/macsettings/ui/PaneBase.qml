import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

Flickable {
    id: root
    default property alias content: col.data
    property string paneId
    contentWidth: width
    contentHeight: col.implicitHeight + 48
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    ScrollBar.vertical: ScrollBar { }

    Component.onCompleted: if (paneId) settings.load(paneId)

    ColumnLayout {
        id: col
        y: 16
        x: Math.max(20, (root.width - width) / 2)
        width: Math.min(root.width - 40, 620)
        spacing: 18
    }
}
