import QtQuick
import QtQuick.Layouts

PaneBase {
    id: root
    paneId: "lock"
    signal navigate(string pane)
    readonly property var d: settings.data.lock || ({})

    Group {
        SettingRow {
            text: "Блокировать экран автоматически"
            MacSwitch { checked: !!root.d.autolock; onToggled: (v) => settings.call("lock.autolock", v) }
        }
        SettingRow {
            text: "Блокировать после простоя"
            MacPopup {
                enabled: !!root.d.autolock
                options: [1, 2, 5, 10, 15, 30, 60].map(m => ({ value: m, text: m === 60 ? "1 час" : m + " мин" }))
                current: root.d.timeout
                onPicked: (v) => settings.call("lock.timeout", v)
            }
        }
        SettingRow {
            text: "Требовать пароль после выхода из сна"
            MacSwitch { checked: !!root.d.lockOnResume; onToggled: (v) => settings.call("lock.lockOnResume", v) }
        }
        SettingRow {
            text: "Требовать пароль после блокировки через"
            MacPopup {
                options: [0, 5, 15, 30, 60].map(s => ({ value: s, text: s === 0 ? "Сразу" : s + " с" }))
                current: root.d.grace
                onPicked: (v) => settings.call("lock.grace", v)
            }
        }
    }
    Group {
        SettingRow { text: "Внешний вид экрана блокировки…"; chevron: true; onClicked: settings.openKcm("kcm_screenlocker") }
        SettingRow { text: "Экран входа и автовход…"; chevron: true; onClicked: settings.openKcm("kcm_plasmalogin") }
    }
}
