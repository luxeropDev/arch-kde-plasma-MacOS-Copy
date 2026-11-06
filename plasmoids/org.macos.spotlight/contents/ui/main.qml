import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

// Значок лупы: открывает KRunner по центру экрана, как Spotlight
PlasmoidItem {
    id: root

    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    toolTipMainText: "Spotlight"
    toolTipSubText: "Meta+Пробел"

    P5Support.DataSource {
        id: exec
        engine: "executable"
        onNewData: (source) => disconnectSource(source)
    }

    fullRepresentation: MouseArea {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 1.6
        Layout.preferredWidth: Layout.minimumWidth
        Layout.maximumWidth: Layout.minimumWidth
        Layout.fillHeight: true
        hoverEnabled: true
        onClicked: exec.connectSource("qdbus6 org.kde.krunner /App org.kde.krunner.App.toggleDisplay")

        Rectangle {
            anchors.centerIn: parent
            width: parent.width - 2
            height: Math.min(parent.height - 4, Kirigami.Units.gridUnit * 1.4)
            radius: 5
            color: Kirigami.Theme.textColor
            opacity: parent.pressed ? 0.18 : 0
        }
        Kirigami.Icon {
            anchors.centerIn: parent
            width: Math.round(Math.min(parent.height * 0.6, Kirigami.Units.iconSizes.small))
            height: width
            source: "search"
            fallback: "edit-find"
            isMask: true
            color: Kirigami.Theme.textColor
        }
    }
}
