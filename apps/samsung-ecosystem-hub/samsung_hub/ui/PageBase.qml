import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

// Прокручиваемая страница с центрированной колонкой контента
Flickable {
    id: root
    default property alias content: col.data
    property int maxContentWidth: 980

    contentWidth: width
    contentHeight: col.implicitHeight + 80
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    flickableDirection: Flickable.VerticalFlick

    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
        contentItem: Rectangle {
            implicitWidth: 6
            radius: 3
            color: Theme.textDim
            opacity: parent.active ? 0.5 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
    }

    ColumnLayout {
        id: col
        y: 40
        x: Math.max(32, (root.width - width) / 2)
        width: Math.min(root.width - 64, root.maxContentWidth)
        spacing: 22
    }
}
