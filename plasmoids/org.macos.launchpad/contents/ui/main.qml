import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PC3
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

// Launchpad в стиле macOS: «стеклянное» окно по центру экрана с вкладками категорий и сеткой иконок
PlasmoidItem {
    id: root

    property bool launchpadOpen: false
    property var allApps: []
    property var recentIds: []
    property string category: "Все"
    property string query: ""

    readonly property string appsScript: Qt.resolvedUrl("../code/apps.py").toString().replace("file://", "")
    // Категории как в окне «Приложения» macOS 26–27
    readonly property var categories: ["Все", "Продуктивность и финансы", "Утилиты", "Креативность", "Общение",
                                       "Информация и чтение", "Развлечения", "Другое"]
    readonly property var recentApps: recentIds.map(id => allApps.find(a => a.id === id)).filter(a => !!a)
    readonly property bool showSuggestions: category === "Все" && query === "" && recentApps.length > 0
    readonly property var visibleApps: allApps.filter(a =>
        (category === "Все" || a.group === category)
        && (query === "" || a.name.toLowerCase().indexOf(query.toLowerCase()) >= 0))

    preferredRepresentation: compactRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    // Встроенный всплывающий блок не нужен: показываем собственное окно
    onExpandedChanged: { if (root.expanded) root.expanded = false }
    toolTipMainText: "Launchpad"
    toolTipSubText: ""

    function toggle() {
        if (launchpadOpen) { launchpadOpen = false; return }
        query = ""
        category = "Все"
        exec.connectSource("python3 " + appsScript)
        launchpadOpen = true
    }

    Connections {
        target: Plasmoid
        function onActivated() { root.toggle() }
    }

    P5Support.DataSource {
        id: exec
        engine: "executable"
        onNewData: (source, data) => {
            if (source === "python3 " + root.appsScript) {
                try {
                    const d = JSON.parse(data["stdout"] || "{}")
                    root.allApps = d.apps || []
                    root.recentIds = d.recent || []
                } catch (e) { root.allApps = [] }
            }
            disconnectSource(source)
        }
    }

    // Запуск в отдельной systemd-scope: программа не зависит от процесса панели
    // и не закрывается, если Plasma перезапустится.
    function detached(cmd) {
        return "systemd-run --user --scope --quiet --collect --slice=app.slice sh -c '" + cmd.replace(/'/g, "'\\''") + "'"
    }
    function launch(appId) {
        launchpadOpen = false
        // apps.py запоминает запуск для строки «Предложения» и открывает приложение
        exec.connectSource(detached("python3 " + appsScript + " launch " + appId))
    }

    // ---------- значок в строке меню ----------
    compactRepresentation: MouseArea {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 1.8
        Layout.preferredWidth: Layout.minimumWidth
        Layout.fillHeight: true
        hoverEnabled: true
        onClicked: root.toggle()

        Rectangle {
            anchors.centerIn: parent
            width: parent.width - 2
            height: Math.min(parent.height - 4, Kirigami.Units.gridUnit * 1.4)
            radius: 5
            color: Kirigami.Theme.textColor
            opacity: root.launchpadOpen ? 0.18 : 0
            Behavior on opacity { NumberAnimation { duration: 90 } }
        }
        Kirigami.Icon {
            anchors.centerIn: parent
            width: Math.round(Math.min(parent.height * 0.62, Kirigami.Units.iconSizes.smallMedium))
            height: width
            source: "view-app-grid-symbolic"
            fallback: "view-app-grid"
            isMask: true
            color: Kirigami.Theme.textColor
        }
    }
    fullRepresentation: Item { implicitWidth: 1; implicitHeight: 1 }

    // ---------- окно Launchpad ----------
    PlasmaCore.Dialog {
        id: dialog
        visible: root.launchpadOpen
        location: PlasmaCore.Types.Floating
        type: PlasmaCore.Dialog.Normal
        hideOnWindowDeactivate: true
        backgroundHints: PlasmaCore.Types.StandardBackground
        flags: Qt.WindowStaysOnTopHint

        // по центру экрана, чуть выше середины — как Launchpad в macOS
        x: root.Screen.virtualX + Math.round((root.Screen.width - width) / 2)
        y: root.Screen.virtualY + Math.round((root.Screen.height - height) / 2.3)

        onVisibleChanged: {
            if (!visible) root.launchpadOpen = false
            else search.forceActiveFocus()
        }

        mainItem: Item {
            id: content
            implicitWidth: Kirigami.Units.gridUnit * 44
            implicitHeight: Kirigami.Units.gridUnit * 27

            Keys.onEscapePressed: root.launchpadOpen = false

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Kirigami.Units.gridUnit * 0.4
                spacing: Kirigami.Units.gridUnit * 0.7

                // ---- заголовок: «Приложения», вкладки, поиск ----
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.gridUnit * 0.6

                    Kirigami.Icon {
                        Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                        Layout.preferredHeight: Layout.preferredWidth
                        source: "view-app-grid-symbolic"
                        fallback: "view-app-grid"
                        isMask: true
                        color: Kirigami.Theme.textColor
                    }
                    PC3.Label {
                        text: "Приложения"
                        font.pixelSize: Kirigami.Units.gridUnit * 1.2
                        font.weight: Font.DemiBold
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 13
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 1.9
                        radius: height / 2
                        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.10)
                        border.width: 1
                        border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.16)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Kirigami.Units.gridUnit * 0.7
                            anchors.rightMargin: Kirigami.Units.gridUnit * 0.7
                            spacing: Kirigami.Units.smallSpacing
                            Kirigami.Icon {
                                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                                Layout.preferredHeight: Layout.preferredWidth
                                source: "search"
                                isMask: true
                                color: Kirigami.Theme.textColor
                                opacity: 0.6
                            }
                            TextInput {
                                id: search
                                Layout.fillWidth: true
                                color: Kirigami.Theme.textColor
                                font.pointSize: Kirigami.Theme.defaultFont.pointSize
                                clip: true
                                text: root.query
                                onTextChanged: root.query = text
                                Keys.onEscapePressed: root.launchpadOpen = false
                                Keys.onReturnPressed: if (root.visibleApps.length > 0) root.launch(root.visibleApps[0].id)
                                Text {
                                    anchors.fill: parent
                                    visible: search.text === ""
                                    text: "Поиск"
                                    color: Kirigami.Theme.textColor
                                    opacity: 0.5
                                    font: search.font
                                }
                            }
                        }
                    }
                }

                // ---- вкладки категорий ----
                Flickable {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                    contentWidth: tabs.implicitWidth
                    clip: true
                    interactive: contentWidth > width

                    Row {
                        id: tabs
                        spacing: Kirigami.Units.gridUnit * 0.5
                        anchors.verticalCenter: parent.verticalCenter
                        Repeater {
                            model: root.categories
                            Rectangle {
                                required property string modelData
                                readonly property bool active: root.category === modelData
                                height: Kirigami.Units.gridUnit * 1.7
                                width: tabLabel.implicitWidth + Kirigami.Units.gridUnit * 1.6
                                radius: height / 2
                                color: active ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.22)
                                              : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, tabHover.hovered ? 0.14 : 0.07)
                                border.width: 1
                                border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, active ? 0.3 : 0.12)
                                Behavior on color { ColorAnimation { duration: 120 } }
                                PC3.Label {
                                    id: tabLabel
                                    anchors.centerIn: parent
                                    text: modelData
                                    font.weight: parent.active ? Font.DemiBold : Font.Normal
                                }
                                HoverHandler { id: tabHover; cursorShape: Qt.PointingHandCursor }
                                TapHandler { onTapped: root.category = modelData }
                            }
                        }
                    }
                }

                // ---- «Предложения»: недавно открытые приложения, как в macOS ----
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: root.showSuggestions
                    spacing: Kirigami.Units.smallSpacing
                    PC3.Label {
                        text: "Предложения"
                        font.weight: Font.DemiBold
                        opacity: 0.75
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 6.2
                        radius: Kirigami.Units.gridUnit * 0.8
                        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.06)
                        border.width: 1
                        border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.10)
                        Row {
                            anchors.centerIn: parent
                            spacing: Kirigami.Units.gridUnit * 0.4
                            Repeater {
                                model: root.recentApps.slice(0, 7)
                                Item {
                                    id: sug
                                    required property var modelData
                                    width: (grid.width - Kirigami.Units.gridUnit) / 7 - Kirigami.Units.gridUnit * 0.4
                                    height: Kirigami.Units.gridUnit * 5.6
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: Kirigami.Units.gridUnit * 0.6
                                        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, sugHover.hovered ? 0.12 : 0)
                                    }
                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        width: parent.width - 6
                                        spacing: 2
                                        Kirigami.Icon {
                                            Layout.alignment: Qt.AlignHCenter
                                            Layout.preferredWidth: Kirigami.Units.iconSizes.large
                                            Layout.preferredHeight: Layout.preferredWidth
                                            source: sug.modelData.icon
                                            fallback: "application-x-executable"
                                        }
                                        PC3.Label {
                                            Layout.fillWidth: true
                                            text: sug.modelData.name
                                            horizontalAlignment: Text.AlignHCenter
                                            elide: Text.ElideRight
                                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                                            textFormat: Text.PlainText
                                        }
                                    }
                                    HoverHandler { id: sugHover; cursorShape: Qt.PointingHandCursor }
                                    TapHandler { onTapped: root.launch(sug.modelData.id) }
                                }
                            }
                        }
                    }
                    PC3.Label {
                        Layout.topMargin: Kirigami.Units.smallSpacing
                        text: "Все приложения"
                        font.weight: Font.DemiBold
                        opacity: 0.75
                    }
                }

                // ---- сетка приложений ----
                GridView {
                    id: grid
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: root.visibleApps
                    cellWidth: Math.floor((width - Kirigami.Units.gridUnit) / 7)
                    cellHeight: Kirigami.Units.gridUnit * 6.6
                    boundsBehavior: Flickable.StopAtBounds

                    PC3.ScrollBar.vertical: PC3.ScrollBar { }

                    delegate: Item {
                        id: cell
                        required property var modelData
                        width: grid.cellWidth
                        height: grid.cellHeight

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 2
                            radius: Kirigami.Units.gridUnit * 0.7
                            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, cellHover.hovered ? 0.12 : 0)
                            Behavior on color { ColorAnimation { duration: 100 } }
                        }
                        ColumnLayout {
                            anchors.centerIn: parent
                            width: parent.width - 8
                            spacing: Kirigami.Units.smallSpacing
                            scale: cellHover.hovered ? 1.06 : 1
                            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }

                            Kirigami.Icon {
                                Layout.alignment: Qt.AlignHCenter
                                Layout.preferredWidth: Kirigami.Units.iconSizes.huge
                                Layout.preferredHeight: Layout.preferredWidth
                                source: cell.modelData.icon
                                fallback: "application-x-executable"
                            }
                            PC3.Label {
                                Layout.fillWidth: true
                                text: cell.modelData.name
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                maximumLineCount: 2
                                wrapMode: Text.Wrap
                                font.pointSize: Kirigami.Theme.smallFont.pointSize + 1
                                textFormat: Text.PlainText
                            }
                        }
                        HoverHandler { id: cellHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: root.launch(cell.modelData.id) }
                    }

                    PC3.Label {
                        anchors.centerIn: parent
                        visible: grid.count === 0
                        text: root.allApps.length === 0 ? "Загрузка…" : "Ничего не найдено"
                        opacity: 0.6
                    }
                }
            }
        }
    }
}
