import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

// Виджет «Батареи» как в macOS: кольца заряда для ноутбука, телефона и Bluetooth-устройств
PlasmoidItem {
    id: root

    property var devices: []
    readonly property string script: Qt.resolvedUrl("../code/batteries.py").toString().replace("file://", "")
    readonly property int slots: 4

    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    P5Support.DataSource {
        id: exec
        engine: "executable"
        onNewData: (source, data) => {
            try { root.devices = JSON.parse(data["stdout"] || "[]") } catch (e) { }
            disconnectSource(source)
        }
    }
    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: exec.connectSource("python3 " + root.script)
    }

    function iconFor(kind) {
        return { laptop: "computer-laptop-symbolic", phone: "smartphone-symbolic", headphones: "audio-headphones-symbolic",
                 mouse: "input-mouse-symbolic", keyboard: "input-keyboard-symbolic", watch: "smartwatch-symbolic" }[kind]
               || "battery-symbolic"
    }
    function tone(d) {
        if (!d) return "transparent"
        if (d.charging) return "#30d158"
        return d.level <= 20 ? "#ff453a" : "#30d158"
    }

    fullRepresentation: Item {
        Layout.preferredWidth: 340
        Layout.preferredHeight: 168
        Layout.minimumWidth: 300
        Layout.minimumHeight: 150

        // стеклянная подложка в стиле виджетов macOS
        Rectangle {
            anchors.fill: parent
            radius: 24
            color: Qt.rgba(0.11, 0.11, 0.13, 0.62)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.12)
            Rectangle {
                anchors.fill: parent; anchors.margins: 1
                radius: 23
                gradient: Gradient {
                    GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.08) }
                    GradientStop { position: 0.5; color: "transparent" }
                }
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 0

            Repeater {
                model: root.slots
                ColumnLayout {
                    id: slot
                    required property int index
                    readonly property var dev: root.devices[index]
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 8

                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 64; Layout.preferredHeight: 64

                        // дорожка кольца
                        Shape {
                            anchors.fill: parent
                            layer.enabled: true; layer.samples: 4
                            ShapePath {
                                strokeColor: Qt.rgba(1, 1, 1, slot.dev ? 0.16 : 0.08)
                                strokeWidth: 6; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                                PathAngleArc { centerX: 32; centerY: 32; radiusX: 28; radiusY: 28; startAngle: 0; sweepAngle: 360 }
                            }
                        }
                        // заряд
                        Shape {
                            anchors.fill: parent
                            visible: !!slot.dev
                            layer.enabled: true; layer.samples: 4
                            ShapePath {
                                strokeColor: root.tone(slot.dev)
                                strokeWidth: 6; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                                PathAngleArc {
                                    centerX: 32; centerY: 32; radiusX: 28; radiusY: 28; startAngle: -90
                                    sweepAngle: slot.dev ? 360 * Math.max(0.01, Math.min(1, slot.dev.level / 100)) : 0
                                    Behavior on sweepAngle { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                                }
                            }
                        }
                        Kirigami.Icon {
                            anchors.centerIn: parent
                            width: 26; height: 26
                            visible: !!slot.dev
                            source: slot.dev ? root.iconFor(slot.dev.kind) : ""
                            fallback: "battery-symbolic"
                            isMask: true
                            color: "white"
                        }
                        // значок зарядки — молния на кольце, как в macOS
                        Rectangle {
                            visible: !!slot.dev && slot.dev.charging
                            x: 42; y: 2
                            width: 18; height: 18; radius: 9
                            color: "#1c1c1e"
                            Text { anchors.centerIn: parent; text: "⚡"; color: "#30d158"; font.pixelSize: 11 }
                        }
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: slot.dev ? slot.dev.level + "%" : ""
                        color: "white"
                        font.pixelSize: 17
                        font.weight: Font.DemiBold
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.maximumWidth: 72
                        text: slot.dev ? slot.dev.name : ""
                        color: Qt.rgba(1, 1, 1, 0.6)
                        font.pixelSize: 10
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
