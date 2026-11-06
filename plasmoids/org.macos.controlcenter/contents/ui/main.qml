import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PC3
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.private.mpris as Mpris
import org.kde.notificationmanager as NotificationManager
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    // ---------- состояние ----------
    property bool wifiOn: false
    property string ssid: ""
    property string ethernet: ""
    property bool btAvailable: false
    property bool btOn: false
    property string btDevice: ""
    property real volume: 0
    property bool muted: false
    property string display: ""
    property real brightness: 0
    property int brightnessMax: 0
    property real kbdLevel: 0
    property int kbdMax: 0
    property bool darkMode: true
    property bool nightLight: false
    property string phone: ""
    property bool volumeDragging: false
    property bool brightnessDragging: false
    property bool kbdDragging: false
    readonly property bool airplane: !wifiOn && !btOn
    readonly property bool dnd: notifSettings.notificationsInhibitedUntil > now
    property date now: new Date()

    readonly property string statusScript: Qt.resolvedUrl("../code/status.sh").toString().replace("file://", "")
    readonly property string appearanceCmd: "sh -c '[ -x \"$HOME/.local/bin/macos-appearance\" ] && \"$HOME/.local/bin/macos-appearance\" toggle || "
        + "{ s=$(kreadconfig6 --group General --key ColorScheme); case \"$s\" in *Dark*) plasma-apply-colorscheme \"${s%Dark}Light\";; *Light*) plasma-apply-colorscheme \"${s%Light}Dark\";; esac; }'"
    readonly property string kbdCmd: "qdbus6 org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement/Actions/KeyboardBrightnessControl "
        + "org.kde.Solid.PowerManagement.Actions.KeyboardBrightnessControl.setKeyboardBrightness "

    preferredRepresentation: compactRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    toolTipMainText: "Пункт управления"
    toolTipSubText: ""

    // Запуск в отдельной systemd-scope: программа не зависит от процесса панели
    // и не закрывается, если Plasma перезапустится.
    function detached(cmd) {
        return "systemd-run --user --scope --quiet --collect --slice=app.slice sh -c '" + cmd.replace(/'/g, "'\\''") + "'"
    }
    function run(cmd) { exec.connectSource(detached(cmd)) }
    function refresh() { now = new Date(); exec.connectSource("sh " + statusScript) }
    function act(cmd) { run(cmd); refreshSoon.restart() }

    function parseStatus(text) {
        const s = {}
        text.split("\n").forEach(l => {
            const i = l.indexOf("=")
            if (i > 0) s[l.slice(0, i)] = l.slice(i + 1).trim()
        })
        wifiOn = s.wifi === "enabled"
        ssid = s.ssid || ""
        ethernet = s.eth || ""
        btAvailable = s.bt !== undefined && s.bt !== ""
        btOn = s.bt === "yes"
        btDevice = s.btdev || ""
        if (!volumeDragging && s.vol) {
            const m = s.vol.match(/([0-9.]+)/)
            if (m) volume = Math.min(1, parseFloat(m[1]))
            muted = s.vol.indexOf("MUTED") >= 0
        }
        display = s.disp || ""
        brightnessMax = parseInt(s.brimax || "0")
        if (!brightnessDragging && s.bri && brightnessMax > 0)
            brightness = parseInt(s.bri) / brightnessMax
        kbdMax = parseInt(s.kbdmax || "0")
        if (!kbdDragging && s.kbd && kbdMax > 0)
            kbdLevel = parseInt(s.kbd) / kbdMax
        darkMode = (s.scheme || "").toLowerCase().indexOf("dark") >= 0
        nightLight = s.night === "true"
        phone = s.phone || ""
    }

    P5Support.DataSource {
        id: exec
        engine: "executable"
        onNewData: (source, data) => {
            if (source.indexOf(root.statusScript) >= 0) root.parseStatus(data["stdout"] || "")
            disconnectSource(source)
        }
    }

    NotificationManager.Settings {
        id: notifSettings
        live: true
    }

    Timer {
        interval: 2000
        repeat: true
        running: root.expanded
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
    Timer { id: refreshSoon; interval: 700; onTriggered: root.refresh() }

    // Плавная отправка значений слайдеров (не чаще ~15 раз/с)
    Timer {
        id: volumeApply
        interval: 60
        onTriggered: root.run("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ " + root.volume.toFixed(2)
                              + (root.muted ? " && wpctl set-mute @DEFAULT_AUDIO_SINK@ 0" : ""))
    }
    Timer {
        id: brightnessApply
        interval: 60
        onTriggered: if (root.display && root.brightnessMax > 0)
            root.run("qdbus6 org.kde.ScreenBrightness " + root.display + " org.kde.ScreenBrightness.Display.SetBrightness "
                     + Math.max(1, Math.round(root.brightness * root.brightnessMax)) + " 1")
    }
    Timer {
        id: kbdApply
        interval: 60
        onTriggered: if (root.kbdMax > 0)
            root.run(root.kbdCmd + Math.round(root.kbdLevel * root.kbdMax))
    }

    // ---------- значок в строке меню ----------
    compactRepresentation: MouseArea {
        id: button
        Layout.minimumWidth: Kirigami.Units.gridUnit * 1.8
        Layout.preferredWidth: Kirigami.Units.gridUnit * 1.8
        hoverEnabled: true
        onClicked: root.expanded = !root.expanded

        Rectangle {
            anchors.centerIn: parent
            width: parent.width - 2
            height: Math.min(parent.height - 4, Kirigami.Units.gridUnit * 1.4)
            radius: 5
            color: Kirigami.Theme.textColor
            opacity: root.expanded ? 0.18 : 0
            Behavior on opacity { NumberAnimation { duration: 90 } }
        }
        Kirigami.Icon {
            anchors.centerIn: parent
            width: Math.round(Math.min(parent.height * 0.62, Kirigami.Units.iconSizes.smallMedium))
            height: width
            source: Qt.resolvedUrl("../images/controlcenter.svg")
            isMask: true
            color: Kirigami.Theme.textColor
        }
    }

    // ---------- панель ----------
    fullRepresentation: Item {
        id: panel
        readonly property int pad: Kirigami.Units.gridUnit * 0.7
        readonly property int gap: Kirigami.Units.gridUnit * 0.6

        Layout.preferredWidth: Kirigami.Units.gridUnit * 21.5
        Layout.minimumWidth: Layout.preferredWidth
        Layout.maximumWidth: Layout.preferredWidth
        Layout.preferredHeight: content.implicitHeight + pad * 2
        Layout.minimumHeight: Layout.preferredHeight
        Layout.maximumHeight: Layout.preferredHeight

        ColumnLayout {
            id: content
            anchors.fill: parent
            anchors.margins: panel.pad
            spacing: panel.gap

            // ---- ряд 1: сеть  |  медиа ----
            RowLayout {
                Layout.fillWidth: true
                spacing: panel.gap

                Tile {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 6.9
                    glass: 0.09

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Kirigami.Units.smallSpacing * 1.5
                        spacing: Kirigami.Units.smallSpacing * 1.5

                        PillToggle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            title: "Wi‑Fi"
                            subtitle: !root.wifiOn ? "Выкл." : (root.ssid || (root.ethernet ? "Ethernet" : "Не подключено"))
                            iconName: root.wifiOn ? "network-wireless-symbolic" : "network-wireless-disconnected-symbolic"
                            fallbackIcon: "network-wireless"
                            checked: root.wifiOn
                            onToggled: root.act("nmcli radio wifi " + (root.wifiOn ? "off" : "on"))
                            onOpen: root.run("sh -c '[ -x \"$HOME/.local/bin/mac-system-settings\" ] && exec \"$HOME/.local/bin/mac-system-settings\" wifi || exec systemsettings kcm_networkmanagement'")
                        }
                        PillToggle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            title: "Bluetooth"
                            subtitle: !root.btAvailable ? "Нет адаптера" : (!root.btOn ? "Выкл." : (root.btDevice || "Вкл."))
                            iconName: "network-bluetooth-symbolic"
                            fallbackIcon: "preferences-system-bluetooth"
                            checked: root.btOn
                            onToggled: root.act(root.btOn
                                ? "bluetoothctl power off"
                                : "sh -c 'rfkill unblock bluetooth; sleep 1; bluetoothctl power on'")
                            onOpen: root.run("sh -c '[ -x \"$HOME/.local/bin/mac-system-settings\" ] && exec \"$HOME/.local/bin/mac-system-settings\" bluetooth || exec systemsettings kcm_bluetooth'")
                        }
                    }
                }

                Tile {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 6.9
                    glass: 0.09

                    Repeater {
                        id: players
                        model: Mpris.MultiplexerModel { }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Kirigami.Units.gridUnit * 0.7
                            spacing: Kirigami.Units.smallSpacing

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Kirigami.Units.smallSpacing * 2
                                Rectangle {
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 2.4
                                    Layout.preferredHeight: Layout.preferredWidth
                                    radius: 9
                                    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12)
                                    clip: true
                                    Kirigami.Icon {
                                        anchors.centerIn: parent
                                        width: parent.width * 0.55
                                        height: width
                                        visible: art.status !== Image.Ready
                                        source: model.iconName || "multimedia-player"
                                        fallback: "audio-x-generic"
                                    }
                                    Image {
                                        id: art
                                        anchors.fill: parent
                                        source: model.artUrl
                                        asynchronous: true
                                        fillMode: Image.PreserveAspectCrop
                                        sourceSize.width: width * 2
                                    }
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0
                                    PC3.Label {
                                        Layout.fillWidth: true
                                        text: model.track || "Не воспроизводится"
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                        textFormat: Text.PlainText
                                    }
                                    PC3.Label {
                                        Layout.fillWidth: true
                                        text: model.artist || model.identity || ""
                                        opacity: 0.62
                                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                                        elide: Text.ElideRight
                                        textFormat: Text.PlainText
                                    }
                                }
                            }
                            Item { Layout.fillHeight: true }
                            RowLayout {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: Kirigami.Units.gridUnit * 0.4
                                PC3.ToolButton {
                                    icon.name: "media-skip-backward"
                                    enabled: model.canGoPrevious
                                    onClicked: model.container.Previous()
                                }
                                PC3.ToolButton {
                                    icon.name: model.playbackStatus === Mpris.PlaybackStatus.Playing ? "media-playback-pause" : "media-playback-start"
                                    onClicked: model.container.PlayPause()
                                }
                                PC3.ToolButton {
                                    icon.name: "media-skip-forward"
                                    enabled: model.canGoNext
                                    onClicked: model.container.Next()
                                }
                            }
                        }
                    }

                    // Когда ни один плеер не запущен — как «Не исполняется» в macOS
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Kirigami.Units.gridUnit * 0.7
                        visible: players.count === 0
                        spacing: Kirigami.Units.smallSpacing
                        Item { Layout.fillHeight: true }
                        PC3.Label {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: "Не воспроизводится"
                            font.weight: Font.DemiBold
                            opacity: 0.8
                        }
                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: Kirigami.Units.gridUnit * 0.4
                            Repeater {
                                model: ["media-skip-backward", "media-playback-start", "media-skip-forward"]
                                PC3.ToolButton { icon.name: modelData; enabled: false }
                            }
                        }
                        Item { Layout.fillHeight: true }
                    }
                }
            }

            // ---- ряд 2: быстрые круглые кнопки ----
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing
                Layout.bottomMargin: Kirigami.Units.smallSpacing
                spacing: 0

                Item { Layout.fillWidth: true }
                RoundToggle {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 2.7
                    Layout.preferredHeight: Layout.preferredWidth
                    checked: root.darkMode
                    accent: "#f2f2f7"
                    checkedIconColor: "#222"
                    iconScale: 1.15
                    iconName: "contrast"
                    fallbackIcon: "color-management"
                    onClicked: root.act(root.appearanceCmd)
                }
                Item { Layout.fillWidth: true }
                RoundToggle {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 2.7
                    Layout.preferredHeight: Layout.preferredWidth
                    checked: root.nightLight
                    accent: "#ff9f0a"
                    iconScale: 1.15
                    iconName: "redshift-status-on"
                    fallbackIcon: "weather-clear-night"
                    onClicked: root.act("sh -c 'kwriteconfig6 --file kwinrc --group NightColor --key Active "
                                        + (!root.nightLight) + " && qdbus6 org.kde.KWin /KWin reconfigure'")
                }
                Item { Layout.fillWidth: true }
                RoundToggle {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 2.7
                    Layout.preferredHeight: Layout.preferredWidth
                    iconScale: 1.15
                    iconName: "camera-photo-symbolic"
                    fallbackIcon: "spectacle"
                    onClicked: { root.run("spectacle"); root.expanded = false }
                }
                Item { Layout.fillWidth: true }
                RoundToggle {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 2.7
                    Layout.preferredHeight: Layout.preferredWidth
                    iconScale: 1.15
                    iconName: "system-lock-screen-symbolic"
                    fallbackIcon: "system-lock-screen"
                    onClicked: { root.expanded = false; root.run("loginctl lock-session") }
                }
                Item { Layout.fillWidth: true }
            }

            // ---- ряд 3: телефон  |  фокус + дисплей ----
            RowLayout {
                Layout.fillWidth: true
                spacing: panel.gap

                Tile {
                    id: phoneTile
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.fillHeight: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 6.2
                    glass: 0.09

                    RoundToggle {
                        x: Kirigami.Units.gridUnit * 0.7
                        y: Kirigami.Units.gridUnit * 0.7
                        checked: root.phone !== ""
                        iconName: "smartphone-symbolic"
                        fallbackIcon: "phone"
                        onClicked: phoneTile.openHub()
                    }
                    ColumnLayout {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: Kirigami.Units.gridUnit * 0.8
                        spacing: 0
                        PC3.Label {
                            Layout.fillWidth: true
                            text: "Телефон"
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }
                        PC3.Label {
                            Layout.fillWidth: true
                            text: root.phone || "Не подключён"
                            opacity: 0.62
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            elide: Text.ElideRight
                        }
                    }
                    function openHub() {
                        root.expanded = false
                        root.run("sh -c 'command -v samsung-ecosystem-hub >/dev/null && exec samsung-ecosystem-hub || exec systemsettings kcm_kdeconnect'")
                    }
                    TapHandler { onTapped: phoneTile.openHub() }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.fillHeight: true
                    spacing: panel.gap

                    PillToggle {
                        Layout.fillWidth: true
                        title: "Фокусирование"
                        subtitle: root.dnd ? "Не беспокоить" : "Выкл."
                        iconName: "weather-clear-night-symbolic"
                        fallbackIcon: "notifications-disabled"
                        checked: root.dnd
                        accent: "#5e5ce6"
                        onToggled: {
                            if (root.dnd) {
                                notifSettings.notificationsInhibitedUntil = undefined
                            } else {
                                const d = new Date()
                                d.setFullYear(d.getFullYear() + 1)
                                notifSettings.notificationsInhibitedUntil = d
                            }
                            notifSettings.save()
                            root.now = new Date()
                        }
                        onOpen: root.run("sh -c '[ -x \"$HOME/.local/bin/mac-system-settings\" ] && exec \"$HOME/.local/bin/mac-system-settings\" focus || exec systemsettings kcm_notifications'")
                    }

                    Tile {
                        visible: root.display !== "" && root.brightnessMax > 0
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumHeight: Kirigami.Units.gridUnit * 3
                        glass: 0.09
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Kirigami.Units.smallSpacing * 2
                            spacing: Kirigami.Units.smallSpacing
                            PC3.Label { text: "Дисплей"; font.weight: Font.DemiBold; font.pointSize: Kirigami.Theme.smallFont.pointSize + 1 }
                            MacSlider {
                                Layout.fillWidth: true
                                iconName: "brightness-high-symbolic"
                                fallbackIcon: "high-brightness"
                                value: root.brightness
                                onDraggingChanged: root.brightnessDragging = dragging
                                onMoved: (v) => { root.brightness = v; brightnessApply.restart() }
                                onIconClicked: root.run("sh -c '[ -x \"$HOME/.local/bin/mac-system-settings\" ] && exec \"$HOME/.local/bin/mac-system-settings\" displays || exec systemsettings kcm_kscreen'")
                            }
                        }
                    }
                }
            }

            // ---- ряд 4: звук  |  подсветка клавиатуры ----
            RowLayout {
                Layout.fillWidth: true
                spacing: panel.gap

                Tile {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 3.6
                    glass: 0.09
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Kirigami.Units.smallSpacing * 2
                        spacing: Kirigami.Units.smallSpacing
                        PC3.Label { text: "Звук"; font.weight: Font.DemiBold; font.pointSize: Kirigami.Theme.smallFont.pointSize + 1 }
                        MacSlider {
                            Layout.fillWidth: true
                            dimmed: root.muted
                            iconName: root.muted || root.volume === 0 ? "audio-volume-muted-symbolic"
                                    : root.volume < 0.34 ? "audio-volume-low-symbolic"
                                    : root.volume < 0.67 ? "audio-volume-medium-symbolic" : "audio-volume-high-symbolic"
                            fallbackIcon: "audio-volume-high"
                            value: root.volume
                            onDraggingChanged: root.volumeDragging = dragging
                            onMoved: (v) => { root.volume = v; root.muted = false; volumeApply.restart() }
                            onIconClicked: root.act("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")
                        }
                    }
                }

                Tile {
                    visible: root.kbdMax > 0
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 3.6
                    glass: 0.09
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Kirigami.Units.smallSpacing * 2
                        spacing: Kirigami.Units.smallSpacing
                        PC3.Label { text: "Клавиатура"; font.weight: Font.DemiBold; font.pointSize: Kirigami.Theme.smallFont.pointSize + 1 }
                        MacSlider {
                            Layout.fillWidth: true
                            iconName: "input-keyboard-symbolic"
                            fallbackIcon: "input-keyboard"
                            value: root.kbdLevel
                            onDraggingChanged: root.kbdDragging = dragging
                            onMoved: (v) => { root.kbdLevel = v; kbdApply.restart() }
                            onIconClicked: root.act(root.kbdCmd + (root.kbdLevel > 0 ? 0 : root.kbdMax))
                        }
                    }
                }
            }

            // ---- подпись внизу, как «Изменить настройки…» ----
            PC3.Label {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Kirigami.Units.smallSpacing
                text: "Параметры системы…"
                opacity: linkHover.hovered ? 1 : 0.7
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                HoverHandler { id: linkHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: { root.expanded = false; root.run("sh -c '[ -x \"$HOME/.local/bin/mac-system-settings\" ] && exec \"$HOME/.local/bin/mac-system-settings\" general || exec systemsettings'") } }
            }
        }
    }
}
