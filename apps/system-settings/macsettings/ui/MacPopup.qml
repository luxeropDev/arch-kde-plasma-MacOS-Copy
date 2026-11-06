import QtQuick
import QtQuick.Controls.Basic

// Всплывающее меню macOS («попап» с двойной стрелкой)
ComboBox {
    id: root
    property var options: []            // [{ value, text }]
    property var current
    signal picked(var value)

    model: options
    textRole: "text"
    valueRole: "value"
    currentIndex: Math.max(0, options.findIndex(o => o.value === current))
    onActivated: (i) => root.picked(options[i].value)
    implicitHeight: 24
    implicitWidth: Math.max(140, contentItem.implicitWidth + 40)
    font.family: Theme.font
    font.pixelSize: Theme.fontSize

    contentItem: Txt {
        leftPadding: 10
        rightPadding: 24
        verticalAlignment: Text.AlignVCenter
        text: root.displayText
    }
    indicator: Txt {
        x: root.width - width - 8
        anchors.verticalCenter: parent.verticalCenter
        text: "⌃⌄"
        font.pixelSize: 9
        secondary: true
        lineHeight: 0.6
    }
    background: Rectangle {
        radius: 6
        color: root.hovered ? Theme.fillStrong : Theme.fill
        border.width: 0.5
        border.color: Theme.groupBorder
    }
    popup: Popup {
        y: root.height + 2
        width: Math.max(root.width, 180)
        padding: 5
        implicitHeight: Math.min(list.contentHeight + 10, 320)
        background: Rectangle {
            radius: 10
            color: Theme.dark ? "#323234" : "#f7f7f9"
            border.width: 0.5
            border.color: Theme.groupBorder
        }
        contentItem: ListView {
            id: list
            clip: true
            model: root.popup.visible ? root.delegateModel : null
            currentIndex: root.highlightedIndex
        }
    }
    delegate: ItemDelegate {
        required property var modelData
        required property int index
        width: ListView.view ? ListView.view.width : 180
        height: 26
        highlighted: root.highlightedIndex === index
        contentItem: Txt {
            text: (root.currentIndex === index ? "✓  " : "    ") + modelData.text
            color: highlighted ? "white" : Theme.text
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle { radius: 5; color: highlighted ? Theme.accent : "transparent" }
    }
}
