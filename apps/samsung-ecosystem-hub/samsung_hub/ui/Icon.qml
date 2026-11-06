import QtQuick
import QtQuick.Effects

// Однотонная SVG-иконка из assets, окрашивается в нужный цвет
Item {
    id: root
    property string name
    property color color: Theme.text
    property int size: 20

    implicitWidth: size
    implicitHeight: size

    Image {
        id: img
        anchors.fill: parent
        source: root.name ? assetsUrl + root.name + ".svg" : ""
        sourceSize: Qt.size(root.size * 3, root.size * 3)
        fillMode: Image.PreserveAspectFit
        visible: false
        smooth: true
    }
    MultiEffect {
        anchors.fill: img
        source: img
        colorization: 1.0
        colorizationColor: root.color
    }
}
