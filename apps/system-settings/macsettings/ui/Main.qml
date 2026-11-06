import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

ApplicationWindow {
    id: win
    width: 900
    height: 680
    minimumWidth: 620
    minimumHeight: 460
    visible: true
    title: "Системные настройки"
    color: Theme.content

    property string pane: startPane
    property var history: [startPane]
    property int historyPos: 0
    property string query: ""

    function go(id) {
        if (id === pane) return
        history = history.slice(0, historyPos + 1).concat([id])
        historyPos = history.length - 1
        pane = id
    }
    function back() { if (historyPos > 0) { historyPos--; pane = history[historyPos] } }
    function forward() { if (historyPos < history.length - 1) { historyPos++; pane = history[historyPos] } }

    // ---- разделы бокового меню (порядок и группы как в macOS 27) ----
    readonly property var sections: [
        [ { id: "wifi", name: "Wi‑Fi", icon: "network-wireless-symbolic", tint: "#0a84ff" },
          { id: "bluetooth", name: "Bluetooth", icon: "network-bluetooth-symbolic", tint: "#0a84ff" },
          { id: "network", name: "Сеть", icon: "network-wired-symbolic", tint: "#0a84ff" },
          { id: "battery", name: "Аккумулятор", icon: "battery-full-symbolic", tint: "#30c75a" } ],
        [ { id: "general", name: "Основные", icon: "preferences-system-symbolic", tint: "#8e8e93" },
          { id: "accessibility", name: "Универсальный доступ", icon: "preferences-desktop-accessibility-symbolic", tint: "#0a84ff" },
          { id: "appearance", name: "Оформление", icon: "contrast", tint: "#3a3a3c" },
          { id: "spotlight", name: "Spotlight", icon: "search", tint: "#8e8e93" },
          { id: "dock", name: "Рабочий стол и Dock", icon: "user-desktop-symbolic", tint: "#3a3a3c" },
          { id: "displays", name: "Дисплеи", icon: "video-display-symbolic", tint: "#0a84ff" },
          { id: "screensaver", name: "Заставка", icon: "preferences-desktop-screensaver-symbolic", tint: "#40b8e8" },
          { id: "wallpaper", name: "Обои", icon: "preferences-desktop-wallpaper-symbolic", tint: "#2fa8e0" } ],
        [ { id: "notifications", name: "Уведомления", icon: "notifications-symbolic", tint: "#ff3b30" },
          { id: "sound", name: "Звук", icon: "audio-volume-high-symbolic", tint: "#ff2d55" },
          { id: "focus", name: "Фокусирование", icon: "weather-clear-night-symbolic", tint: "#5e5ce6" } ],
        [ { id: "lock", name: "Экран блокировки", icon: "system-lock-screen-symbolic", tint: "#3a3a3c" },
          { id: "privacy", name: "Конфиденциальность и безопасность", icon: "security-high-symbolic", tint: "#0a84ff" },
          { id: "users", name: "Пользователи и группы", icon: "system-users-symbolic", tint: "#8e8e93" } ],
        [ { id: "keyboard", name: "Клавиатура", icon: "input-keyboard-symbolic", tint: "#8e8e93" },
          { id: "mouse", name: "Мышь", icon: "input-mouse-symbolic", tint: "#8e8e93" },
          { id: "trackpad", name: "Трекпад", icon: "input-touchpad-symbolic", tint: "#8e8e93" },
          { id: "printers", name: "Принтеры и сканеры", icon: "printer-symbolic", tint: "#8e8e93" } ]
    ]
    readonly property var allItems: [].concat.apply([], sections).concat([
        { id: "about", name: "Об этом компьютере", icon: "computer-symbolic", tint: "#8e8e93", hidden: true }])
    function info(id) { return allItems.find(i => i.id === id) || allItems[0] }

    readonly property var panes: ({
        wifi: "WifiPane.qml", bluetooth: "BluetoothPane.qml", network: "NetworkPane.qml", battery: "BatteryPane.qml",
        about: "AboutPane.qml", appearance: "AppearancePane.qml", dock: "DockPane.qml", displays: "DisplaysPane.qml",
        wallpaper: "WallpaperPane.qml", sound: "SoundPane.qml", lock: "LockPane.qml", keyboard: "KeyboardPane.qml",
        mouse: "PointerPane.qml", trackpad: "PointerPane.qml"
    })

    // ---- разделы, которые открывают модули KDE (там больше параметров, чем можно повторить здесь) ----
    readonly property var linkPanes: ({
        general: { description: "Обновления, язык, дата и время, автозапуск и другие общие параметры компьютера.",
            rows: [ { text: "Об этом компьютере", icon: "computer-symbolic", tint: "#8e8e93", pane: "about" },
                    { text: "Обновление ПО", icon: "system-software-update-symbolic", tint: "#8e8e93", kcm: "kcm_updates" },
                    { text: "Хранилище", icon: "drive-harddisk-symbolic", tint: "#8e8e93", pane: "about" },
                    { text: "Дата и время", icon: "preferences-system-time-symbolic", tint: "#0a84ff", kcm: "kcm_clock" },
                    { text: "Язык и регион", icon: "preferences-desktop-locale-symbolic", tint: "#0a84ff", kcm: "kcm_regionandlang" },
                    { text: "Объекты входа и расширения", icon: "system-run-symbolic", tint: "#8e8e93", kcm: "kcm_autostart" },
                    { text: "Приложения по умолчанию", icon: "preferences-desktop-default-applications-symbolic", tint: "#8e8e93", kcm: "kcm_componentchooser" },
                    { text: "Шрифты", icon: "preferences-desktop-font-symbolic", tint: "#8e8e93", kcm: "kcm_fonts" },
                    { text: "Общий доступ", icon: "folder-remote-symbolic", tint: "#0a84ff", kcm: "kcm_samba" } ] },
        accessibility: { description: "Параметры для зрения, слуха и управления компьютером.",
            rows: [ { text: "Универсальный доступ", subtitle: "Звуковые сигналы, залипание клавиш, мышь с клавиатуры", icon: "preferences-desktop-accessibility-symbolic", tint: "#0a84ff", kcm: "kcm_access" },
                    { text: "Экранная клавиатура", icon: "input-keyboard-virtual-symbolic", tint: "#8e8e93", kcm: "kcm_virtualkeyboard" },
                    { text: "Анимации", subtitle: "Скорость и уменьшение движения", icon: "applications-system-symbolic", tint: "#8e8e93", kcm: "kcm_animations" } ] },
        spotlight: { description: "Spotlight (KRunner) открывается по Meta+Пробел и ищет приложения, файлы и настройки.",
            rows: [ { text: "Поиск и источники результатов", icon: "search", tint: "#8e8e93", kcm: "kcm_plasmasearch" },
                    { text: "Веб-ярлыки", icon: "globe-symbolic", tint: "#0a84ff", kcm: "kcm_webshortcuts" },
                    { text: "Индексация файлов", icon: "search", tint: "#8e8e93", kcm: "kcm_baloofile" } ] },
        screensaver: { description: "В KDE вместо заставки — экран блокировки с часами в стиле macOS.",
            rows: [ { text: "Внешний вид экрана блокировки", icon: "preferences-desktop-screensaver-symbolic", tint: "#40b8e8", kcm: "kcm_screenlocker" },
                    { text: "Экран загрузки", icon: "preferences-desktop-theme-global-symbolic", tint: "#8e8e93", kcm: "kcm_splashscreen" } ] },
        notifications: { description: "Какие приложения могут показывать уведомления и как они выглядят.",
            rows: [ { text: "Уведомления приложений", icon: "notifications-symbolic", tint: "#ff3b30", kcm: "kcm_notifications" },
                    { text: "Звуки системы", icon: "audio-speakers-symbolic", tint: "#ff2d55", kcm: "kcm_soundtheme" } ] },
        focus: { description: "Режим «Не беспокоить» быстро включается в Пункте управления в строке меню.",
            rows: [ { text: "Расписание и исключения «Не беспокоить»", icon: "weather-clear-night-symbolic", tint: "#5e5ce6", kcm: "kcm_notifications" } ] },
        privacy: { description: "Разрешения приложений, брандмауэр и защита прошивки.",
            rows: [ { text: "Разрешения приложений", icon: "security-high-symbolic", tint: "#0a84ff", kcm: "kcm_app-permissions" },
                    { text: "Брандмауэр", icon: "security-medium-symbolic", tint: "#30c75a", kcm: "kcm_firewall" },
                    { text: "Безопасность прошивки", icon: "cpu-symbolic", tint: "#8e8e93", kcm: "kcm_firmware_security" },
                    { text: "История файлов", icon: "document-open-recent-symbolic", tint: "#8e8e93", kcm: "kcm_recentFiles" },
                    { text: "Отзывы и диагностика", icon: "help-about-symbolic", tint: "#8e8e93", kcm: "kcm_feedback" } ] },
        users: { description: "", user: true,
            rows: [ { text: "Пользователи, пароль и аватар", icon: "system-users-symbolic", tint: "#8e8e93", kcm: "kcm_users" },
                    { text: "Экран входа", subtitle: "Автовход и оформление экрана входа", icon: "system-lock-screen-symbolic", tint: "#3a3a3c", kcm: "kcm_plasmalogin" },
                    { text: "Учётные записи в интернете", icon: "applications-internet-symbolic", tint: "#0a84ff", kcm: "kcm_kaccounts" } ] },
        printers: { description: "Добавление и настройка принтеров (CUPS).",
            rows: [ { text: "Принтеры", icon: "printer-symbolic", tint: "#8e8e93", kcm: "kcm_printer_manager" } ] }
    })

    Shortcut { sequence: StandardKey.Find; onActivated: search.forceActiveFocus() }
    Shortcut { sequence: "Ctrl+Q"; onActivated: Qt.quit() }
    Shortcut { sequence: "Alt+Left"; onActivated: win.back() }
    Shortcut { sequence: "Alt+Right"; onActivated: win.forward() }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ---------------- боковая панель: от края до края, с цветными значками ----------------
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 250
            color: Theme.sidebar

            Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: Theme.separator }

            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: 12
                spacing: 8

                // поиск
                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: 12; Layout.rightMargin: 12
                    implicitHeight: 28
                    radius: 7
                    color: Theme.fill
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8; anchors.rightMargin: 8
                        spacing: 6
                        Kirigami.Icon { Layout.preferredWidth: 14; Layout.preferredHeight: 14; source: "search"; isMask: true; color: Theme.secondary }
                        TextInput {
                            id: search
                            Layout.fillWidth: true
                            color: Theme.text
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize
                            clip: true
                            onTextChanged: win.query = text
                            Keys.onEscapePressed: text = ""
                            Txt { anchors.fill: parent; visible: !search.text; text: "Поиск"; secondary: true }
                        }
                    }
                }

                // карточка пользователя (как «Apple Account»)
                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: 8; Layout.rightMargin: 8
                    implicitHeight: 56
                    radius: 8
                    color: win.pane === "users" ? Theme.selection : (userHover.hovered ? Theme.fill : "transparent")
                    readonly property var user: settings.data.user || ({})
                    Component.onCompleted: settings.load("user")
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 6; anchors.rightMargin: 6
                        spacing: 10
                        Avatar { size: 40; user: parent.parent.user }
                        ColumnLayout {
                            spacing: 0
                            Layout.fillWidth: true
                            Txt { text: parent.parent.parent.user.name || ""; font.weight: Font.DemiBold
                                    color: win.pane === "users" ? "white" : Theme.text; Layout.fillWidth: true }
                            Txt { text: "Учётная запись"; font.pixelSize: 11; Layout.fillWidth: true
                                    color: win.pane === "users" ? Qt.rgba(1, 1, 1, 0.8) : Theme.secondary }
                        }
                    }
                    HoverHandler { id: userHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: win.go("users") }
                }

                // список разделов
                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentHeight: sideCol.implicitHeight + 12
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar { }

                    Column {
                        id: sideCol
                        width: parent.width
                        spacing: 10
                        Repeater {
                            model: win.sections
                            Column {
                                id: sectionCol
                                required property var modelData
                                width: sideCol.width
                                readonly property var items: modelData.filter(i =>
                                    win.query === "" || i.name.toLowerCase().indexOf(win.query.toLowerCase()) >= 0)
                                visible: items.length > 0
                                Repeater {
                                    model: sectionCol.items
                                    SidebarRow {
                                        required property var modelData
                                        width: sideCol.width
                                        item: modelData
                                        selected: win.pane === modelData.id || (win.pane === "about" && modelData.id === "general")
                                        onClicked: win.go(modelData.id)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ---------------- содержимое ----------------
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // панель инструментов: назад/вперёд и название
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 52
                color: Theme.content
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14; anchors.rightMargin: 14
                    spacing: 4
                    NavButton { text: "‹"; enabled: win.historyPos > 0; onClicked: win.back() }
                    NavButton { text: "›"; enabled: win.historyPos < win.history.length - 1; onClicked: win.forward() }
                    Txt {
                        Layout.leftMargin: 8
                        Layout.fillWidth: true
                        text: win.info(win.pane).name
                        font.pixelSize: 15
                        font.weight: Font.Bold
                    }
                }
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.separator; opacity: 0.6 }
            }

            Loader {
                id: loader
                Layout.fillWidth: true
                Layout.fillHeight: true
                source: win.panes[win.pane] ? win.panes[win.pane] : "LinksPane.qml"
                onLoaded: {
                    if (item.hasOwnProperty("spec")) item.spec = win.linkPanes[win.pane] || ({ rows: [] })
                    if (item.hasOwnProperty("info")) item.info = win.info(win.pane)
                    if (item.hasOwnProperty("touchpad")) item.touchpad = (win.pane === "trackpad")
                    if (item.hasOwnProperty("navigate")) item.navigate.connect(win.go)
                }
                // при смене Mouse ↔ Trackpad файл тот же — перезагружаем вручную
                Connections {
                    target: win
                    function onPaneChanged() {
                        loader.active = false
                        loader.active = true
                    }
                }
            }
        }
    }

    Toast { id: toast }
    Connections {
        target: settings
        function onToast(kind, text) { toast.show(kind, text) }
    }
}
