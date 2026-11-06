import QtQuick

Rectangle {
    id: root
    property string kind: "info"
    function show(k, t) { kind = k; label.text = t; opacity = 1; timer.restart() }
    anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
    anchors.bottom: parent ? parent.bottom : undefined
    anchors.bottomMargin: 18
    width: Math.min(label.implicitWidth + 32, 560); height: 34; radius: 17
    color: Theme.dark ? "#3a3a3c" : "#ffffff"
    border.width: 0.5; border.color: Theme.groupBorder
    opacity: 0
    z: 100
    Behavior on opacity { NumberAnimation { duration: 160 } }
    Txt { id: label; anchors.centerIn: parent; width: Math.min(implicitWidth, 530)
            color: root.kind === "error" ? Theme.bad : Theme.text }
    Timer { id: timer; interval: 3500; onTriggered: root.opacity = 0 }
}
