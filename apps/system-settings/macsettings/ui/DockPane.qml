import QtQuick
import QtQuick.Layouts

PaneBase {
    id: root
    paneId: "dock"
    signal navigate(string pane)
    readonly property var d: settings.data.dock || ({})

    Group {
        title: "Dock"
        visible: root.d.available !== false
        footer: "Изменения применяются сразу: Dock перезапускается за секунду."
        SettingRow {
            text: "Размер"
            Txt { text: "Маленький"; secondary: true; font.pixelSize: 11 }
            MacSlider { width: 170; from: 24; to: 96; stepSize: 2; value: root.d.size || 48
                        onReleased: (v) => settings.call("dock.size", Math.round(v)) }
            Txt { text: "Большой"; secondary: true; font.pixelSize: 11 }
        }
        SettingRow {
            text: "Увеличение"
            MacSwitch { checked: (root.d.magnification || 1) > 1.0
                        onToggled: (v) => settings.call("dock.magnification", v ? 1.6 : 1.0) }
            MacSlider { width: 150; enabled: (root.d.magnification || 1) > 1.0; opacity: enabled ? 1 : 0.4
                        from: 1.1; to: 2.0; stepSize: 0.05; value: Math.max(1.1, root.d.magnification || 1.6)
                        onReleased: (v) => settings.call("dock.magnification", v) }
        }
        SettingRow {
            text: "Положение на экране"
            MacPopup { options: [{ value: "left", text: "Слева" }, { value: "bottom", text: "Снизу" }, { value: "right", text: "Справа" }, { value: "top", text: "Сверху" }]
                       current: root.d.position; onPicked: (v) => settings.call("dock.position", v) }
        }
        SettingRow {
            text: "Убирать в Dock с эффектом"
            MacPopup { options: [{ value: "genie", text: "Джинн" }, { value: "scale", text: "Масштаб" }]
                       current: root.d.minimize; onPicked: (v) => settings.call("dock.minimize", v) }
        }
        SettingRow {
            text: "Автоматически скрывать и показывать Dock"
            MacSwitch { checked: root.d.visibility === 1; onToggled: (v) => settings.call("dock.visibility", v ? 1 : 2) }
        }
    }
    Group {
        visible: root.d.available === false
        SettingRow { text: "Dock Krema не установлен"; subtitle: "Установите его скриптом ~/macos-kde/install.sh" }
    }
    Group {
        title: "Рабочий стол и окна"
        SettingRow { text: "Активные углы…"; chevron: true; onClicked: settings.openKcm("kcm_kwinscreenedges") }
        SettingRow { text: "Рабочие столы (Spaces)…"; chevron: true; onClicked: settings.openKcm("kcm_kwin_virtualdesktops") }
        SettingRow { text: "Поведение окон…"; chevron: true; onClicked: settings.openKcm("kcm_kwinoptions") }
        SettingRow { text: "Переключение окон…"; chevron: true; onClicked: settings.openKcm("kcm_kwintabbox") }
    }
}
