import QtQuick
import QtQuick.Layouts

PageBase {
    id: page
    readonly property var st: hub.state
    readonly property var adbDevs: st.adbDevices || []
    readonly property bool hasAuthorized: adbDevs.some(d => d.authorized)
    readonly property bool hasUnauthorized: adbDevs.some(d => d.state === "unauthorized")
    readonly property bool ready: !!st.scrcpyAvailable && !!st.adbAvailable && hasAuthorized

    PageHeader { title: "Зеркалирование экрана"; subtitle: "scrcpy показывает экран телефона на компьютере" }

    Card {
        Layout.fillWidth: true
        padding: 24
        ColumnLayout {
            anchors.fill: parent
            spacing: 16
            Text {
                text: "Проверка готовности"
                color: Theme.text
                font.family: Theme.font; font.pixelSize: 17; font.weight: Font.DemiBold
            }
            CheckRow { ok: !!st.scrcpyAvailable; text: "scrcpy установлен"
                       hint: st.scrcpyAvailable ? "" : "Установите: sudo pacman -S scrcpy" }
            CheckRow { ok: !!st.adbAvailable; text: "ADB (android-tools) установлен"
                       hint: st.adbAvailable ? "" : "Установите: sudo pacman -S android-tools" }
            CheckRow {
                ok: page.hasAuthorized
                text: page.hasAuthorized ? "Телефон авторизован по ADB"
                      : (page.hasUnauthorized ? "Телефон найден, но отладка не подтверждена" : "Телефон по ADB не найден")
                hint: page.hasAuthorized ? (adbDevs.filter(d => d.authorized).map(d => d.model || d.serial).join(", "))
                      : (page.hasUnauthorized ? "Разблокируйте телефон и подтвердите запрос «Разрешить отладку по USB» (RSA-ключ)."
                                              : "Подключите телефон по USB и включите отладку (инструкция ниже).")
            }
            ActionButton {
                primary: true
                text: "Запустить scrcpy"
                iconName: "mirror"
                enabled: page.ready
                onClicked: hub.launchScrcpy()
            }
        }
    }

    Card {
        Layout.fillWidth: true
        padding: 24
        ColumnLayout {
            anchors.fill: parent
            spacing: 10
            Text {
                text: "Как включить USB-отладку самостоятельно"
                color: Theme.text
                font.family: Theme.font; font.pixelSize: 17; font.weight: Font.DemiBold
            }
            Repeater {
                model: [
                    "Настройки → О телефоне → Сведения о ПО → 7 раз коснитесь «Номер сборки».",
                    "Настройки → Параметры разработчика → включите «Отладка по USB».",
                    "Подключите телефон кабелем и подтвердите запрос на доверие этому компьютеру.",
                    "Нажмите «Обновить» на главной вкладке — статус изменится на «авторизован»."
                ]
                Text {
                    required property string modelData
                    required property int index
                    text: (index + 1) + ".  " + modelData
                    color: Theme.textDim
                    font.family: Theme.font; font.pixelSize: 13
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
            Text {
                text: "Приложение само ничего не включает на телефоне и не хранит ADB-ключи — ими управляет сам adb в ~/.android."
                color: Theme.textDim; opacity: 0.85
                font.family: Theme.font; font.pixelSize: 12
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.topMargin: 6
            }
        }
    }
}
