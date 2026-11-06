import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Effects
import QtQuick.Layouts
import Qt.labs.platform as Platform

ApplicationWindow {
    id: window
    width: 1120
    height: 740
    minimumWidth: 760
    minimumHeight: 560
    visible: !startHidden
    title: "Samsung Ecosystem Hub"
    color: Theme.bgTop

    property int page: startPage
    readonly property bool compact: width < 940

    Binding { target: Theme; property: "mode"; value: hub.theme }

    readonly property var navItems: [
        { icon: "overview", name: "Overview" },
        { icon: "phone", name: "Phone" },
        { icon: "buds", name: "Galaxy Buds" },
        { icon: "watch", name: "Galaxy Watch" },
        { icon: "transfer", name: "File Transfer" },
        { icon: "mirror", name: "Screen Mirroring" },
        { icon: "settings", name: "Settings" }
    ]

    // ---- фон: градиент и размытые цветные пятна (имитация матового стекла) ----
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.bgTop }
            GradientStop { position: 1.0; color: Theme.bgBottom }
        }
        Item {
            id: orbs
            anchors.fill: parent
            layer.enabled: true
            layer.effect: MultiEffect { blurEnabled: true; blur: 1.0; blurMax: 64 }
            Rectangle { x: parent.width * 0.55; y: -120; width: 420; height: 420; radius: 210
                        color: Theme.accent; opacity: Theme.dark ? 0.28 : 0.20 }
            Rectangle { x: -100; y: parent.height * 0.55; width: 380; height: 380; radius: 190
                        color: Theme.accent2; opacity: Theme.dark ? 0.26 : 0.16 }
            Rectangle { x: parent.width * 0.72; y: parent.height * 0.65; width: 300; height: 300; radius: 150
                        color: "#ff7a45"; opacity: Theme.dark ? 0.14 : 0.12 }
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ---- боковая навигация ----
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: window.compact ? 76 : 240
            color: Theme.sidebar
            Behavior on Layout.preferredWidth { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

            Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: Theme.hairline }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 6
                    Layout.bottomMargin: 18
                    spacing: 10
                    Image {
                        source: assetsUrl + "app-icon.svg"
                        sourceSize: Qt.size(76, 76)
                        Layout.preferredWidth: 38; Layout.preferredHeight: 38
                        Layout.leftMargin: window.compact ? 4 : 0
                    }
                    Text {
                        visible: !window.compact
                        text: "Samsung\nEcosystem"
                        color: Theme.text
                        font.family: Theme.font; font.pixelSize: 15; font.weight: Font.Bold
                        lineHeight: 0.95
                    }
                }

                Repeater {
                    model: window.navItems
                    SidebarItem {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        iconName: modelData.icon
                        text: modelData.name
                        compact: window.compact
                        selected: window.page === index
                        onClicked: window.page = index
                    }
                }

                Item { Layout.fillHeight: true }

                RowLayout {
                    visible: !window.compact
                    Layout.fillWidth: true
                    Layout.leftMargin: 6
                    spacing: 8
                    Rectangle {
                        width: 8; height: 8; radius: 4
                        color: hub.busy ? Theme.warn : Theme.good
                    }
                    Text {
                        text: hub.busy ? "Выполняется…" : "Готово · " + (hub.state.updatedAt || "—")
                        color: Theme.textDim
                        font.family: Theme.font; font.pixelSize: 11
                    }
                }
            }
        }

        // ---- страницы ----
        StackLayout {
            id: stack
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: window.page

            OverviewPage { onNavigate: (i) => window.page = i }
            PhonePage { onNavigate: (i) => window.page = i }
            BudsPage { onNavigate: (i) => window.page = i }
            WatchPage { }
            TransferPage { }
            MirrorPage { }
            SettingsPage { }
        }
    }

    Toast { id: toast }
    Connections {
        target: hub
        function onToast(kind, text) { toast.show(kind, text) }
    }

    // ---- трей ----
    Platform.SystemTrayIcon {
        id: tray
        visible: available && hub.keepInTray
        icon.source: assetsUrl + "app-icon.svg"
        tooltip: "Samsung Ecosystem Hub"
        onActivated: { window.show(); window.raise(); window.requestActivate() }
        menu: Platform.Menu {
            Platform.MenuItem { text: "Открыть"; onTriggered: { window.show(); window.raise(); window.requestActivate() } }
            Platform.MenuItem { text: "Обновить"; onTriggered: hub.refresh() }
            Platform.MenuSeparator { }
            Platform.MenuItem { text: "Выход"; onTriggered: Qt.quit() }
        }
    }

    onClosing: (close) => {
        if (hub.keepInTray && tray.available) {
            close.accepted = false
            window.hide()
        }
    }

    Shortcut { sequence: "Ctrl+Q"; onActivated: Qt.quit() }
    Shortcut { sequence: "F5"; onActivated: hub.refresh() }
    Shortcut { sequence: "Ctrl+Tab"; onActivated: window.page = (window.page + 1) % window.navItems.length }
}
