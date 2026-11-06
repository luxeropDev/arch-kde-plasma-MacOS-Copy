import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

PaneBase {
    id: root
    paneId: "sound"
    signal navigate(string pane)
    readonly property var d: settings.data.sound || ({})

    Group {
        title: "Выход"
        Repeater {
            model: root.d.outputs || []
            SettingRow {
                required property var modelData
                text: modelData.name
                icon: "audio-speakers-symbolic"; tint: "#ff2d55"
                chevron: !modelData.default
                Txt { visible: modelData.default; text: "✓"; color: Theme.accent; font.weight: Font.Bold }
                onClicked: settings.call("sound.default", modelData.id)
            }
        }
        SettingRow {
            text: "Громкость выхода"
            Kirigami.Icon { width: 16; height: 16; source: "audio-volume-low-symbolic"; isMask: true; color: Theme.secondary }
            MacSlider { id: out; width: 200; value: root.d.volume || 0; live: true; onMoved: outTimer.restart() }
            Kirigami.Icon { width: 16; height: 16; source: "audio-volume-high-symbolic"; isMask: true; color: Theme.secondary }
            Timer { id: outTimer; interval: 60; onTriggered: settings.call("sound.volume", out.value) }
        }
        SettingRow {
            text: "Выключить звук"
            MacSwitch { checked: !!root.d.muted; onToggled: (v) => settings.call("sound.mute", v) }
        }
    }
    Group {
        title: "Вход"
        Repeater {
            model: root.d.inputs || []
            SettingRow {
                required property var modelData
                text: modelData.name
                icon: "audio-input-microphone-symbolic"; tint: "#8e8e93"
                Txt { visible: modelData.default; text: "✓"; color: Theme.accent; font.weight: Font.Bold }
            }
        }
        SettingRow {
            text: "Громкость входа"
            MacSlider { id: inp; width: 220; value: root.d.inputVolume || 0; live: true; onMoved: inTimer.restart() }
            Timer { id: inTimer; interval: 60; onTriggered: settings.call("sound.inputVolume", inp.value) }
        }
    }
    Group {
        SettingRow { text: "Устройства, профили и звуки приложений…"; chevron: true; onClicked: settings.openKcm("kcm_pulseaudio") }
        SettingRow { text: "Звуковые эффекты…"; chevron: true; onClicked: settings.openKcm("kcm_soundtheme") }
    }
}
