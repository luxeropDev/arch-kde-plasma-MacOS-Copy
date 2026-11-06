import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    Plasmoid.status: menu.status === PlasmaExtras.Menu.Open
        ? PlasmaCore.Types.RequiresAttentionStatus : PlasmaCore.Types.ActiveStatus

    readonly property string userName: {
        const full = execSource.fullName.trim()
        return full.length > 0 ? full : execSource.login.trim()
    }

    // Запуск в отдельной systemd-scope: программа не зависит от процесса панели
    // и не закрывается, если Plasma перезапустится.
    function detached(cmd) {
        return "systemd-run --user --scope --quiet --collect --slice=app.slice sh -c '" + cmd.replace(/'/g, "'\\''") + "'"
    }
    function run(cmd) {
        execSource.connectSource(detached(cmd))
    }

    P5Support.DataSource {
        id: execSource
        engine: "executable"
        property string fullName: ""
        property string login: ""
        onNewData: (source, data) => {
            if (source === "getent passwd \"$USER\" | cut -d: -f5 | cut -d, -f1") {
                fullName = data["stdout"] || ""
            } else if (source === "echo \"$USER\"") {
                login = data["stdout"] || ""
            }
            disconnectSource(source)
        }
        Component.onCompleted: {
            connectSource("getent passwd \"$USER\" | cut -d: -f5 | cut -d, -f1")
            connectSource("echo \"$USER\"")
        }
    }

    fullRepresentation: MouseArea {
        id: button

        Layout.minimumWidth: Kirigami.Units.gridUnit * 2
        Layout.preferredWidth: Kirigami.Units.gridUnit * 2
        Layout.maximumWidth: Kirigami.Units.gridUnit * 2
        Layout.fillHeight: true

        hoverEnabled: true
        onPressed: {
            menu.visualParent = button
            menu.openRelative()
        }

        Rectangle {
            anchors.centerIn: parent
            width: parent.width - 4
            height: Math.min(parent.height - 4, Kirigami.Units.gridUnit * 1.4)
            radius: 5
            color: Kirigami.Theme.textColor
            opacity: menu.status === PlasmaExtras.Menu.Open ? 0.18 : 0
            Behavior on opacity { NumberAnimation { duration: 90 } }
        }

        Kirigami.Icon {
            anchors.centerIn: parent
            width: Math.round(Math.min(parent.height * 0.7, Kirigami.Units.iconSizes.smallMedium))
            height: width
            source: Qt.resolvedUrl("../images/apple.svg")
            isMask: true
            color: Kirigami.Theme.textColor
        }
    }

    PlasmaExtras.Menu {
        id: menu
        placement: PlasmaExtras.Menu.BottomPosedLeftAlignedPopup
        minimumWidth: Kirigami.Units.gridUnit * 15

        PlasmaExtras.MenuItem {
            text: "Об этом компьютере"
            onClicked: root.run("kinfocenter")
        }
        PlasmaExtras.MenuItem { separator: true }
        PlasmaExtras.MenuItem {
            text: "Системные настройки…"
            onClicked: root.run("sh -c '[ -x \"$HOME/.local/bin/mac-system-settings\" ] && exec \"$HOME/.local/bin/mac-system-settings\" general || exec systemsettings'")
        }
        PlasmaExtras.MenuItem {
            text: "App Store…"
            onClicked: root.run("plasma-discover")
        }
        PlasmaExtras.MenuItem { separator: true }
        PlasmaExtras.MenuItem {
            text: "Мониторинг системы"
            onClicked: root.run("plasma-systemmonitor")
        }
        PlasmaExtras.MenuItem {
            text: "Завершить принудительно…\tCtrl+Alt+Esc"
            onClicked: root.run("qdbus6 org.kde.KWin /KWin org.kde.KWin.killWindow")
        }
        PlasmaExtras.MenuItem { separator: true }
        PlasmaExtras.MenuItem {
            text: "Режим сна"
            onClicked: root.run("systemctl suspend")
        }
        PlasmaExtras.MenuItem {
            text: "Перезагрузить…"
            onClicked: root.run("qdbus6 org.kde.LogoutPrompt /LogoutPrompt org.kde.LogoutPrompt.promptReboot")
        }
        PlasmaExtras.MenuItem {
            text: "Выключить…"
            onClicked: root.run("qdbus6 org.kde.LogoutPrompt /LogoutPrompt org.kde.LogoutPrompt.promptShutDown")
        }
        PlasmaExtras.MenuItem { separator: true }
        PlasmaExtras.MenuItem {
            text: "Заблокировать экран\tMeta+L"
            onClicked: root.run("loginctl lock-session")
        }
        PlasmaExtras.MenuItem {
            text: "Завершить сеанс «" + root.userName + "»…\tCtrl+Alt+Del"
            onClicked: root.run("qdbus6 org.kde.LogoutPrompt /LogoutPrompt org.kde.LogoutPrompt.promptLogout")
        }
    }
}
