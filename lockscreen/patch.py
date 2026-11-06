#!/usr/bin/env python3
"""Накладывает стиль macOS на экран блокировки Plasma.

Правит LockScreenUi.qml и MainBlock.qml в указанной папке lockscreen.
Каждая замена обязана сработать ровно один раз — иначе выходим с ошибкой,
и вызывающий скрипт оставляет стандартный экран блокировки KDE.
"""
import re
import sys
from pathlib import Path


def sub_once(text, pattern, repl, name, flags=0):
    new, n = re.subn(pattern, repl, text, count=0, flags=flags)
    if n != 1:
        raise SystemExit(f"патч «{name}» не применился (совпадений: {n})")
    return new


def main(lockdir):
    d = Path(lockdir)

    ui = (d / "LockScreenUi.qml").read_text()
    # Часы: крупные, по центру сверху
    ui = sub_once(ui, r"\n        Clock \{\n            id: clock\n.*?\n        \}\n",
                  "\n        MacClock {\n"
                  "            id: clock\n"
                  "            property Item shadow: clockShadow\n"
                  "            anchors.horizontalCenter: parent.horizontalCenter\n"
                  "            anchors.top: parent.top\n"
                  "            anchors.topMargin: Math.round(parent.height * 0.07)\n"
                  "        }\n",
                  "часы", re.S)
    # Верхняя строка: раскладка, батарея, кнопка питания с меню
    ui = sub_once(ui, r"(\n        Loader \{\n            z: 2\n            active: root\.viewVisible)",
                  "\n        MacTopBar {\n"
                  "            z: 3\n"
                  "            session: sessionManagement\n"
                  "            anchors.top: parent.top\n"
                  "            anchors.right: parent.right\n"
                  "            anchors.topMargin: Kirigami.Units.smallSpacing * 2\n"
                  "            anchors.rightMargin: Kirigami.Units.gridUnit\n"
                  "        }\n"
                  r"\1",
                  "верхняя строка")
    # Раскладку и батарею из нижней панели убираем — они теперь сверху
    ui = sub_once(ui, r"visible: keyboardLayoutSwitcher\.hasMultipleKeyboardLayouts\n",
                  "visible: false\n", "кнопка раскладки внизу")
    ui = sub_once(ui, r"\n            Battery \{\}", "\n            Battery { visible: false }",
                  "батарея внизу")
    # Аватар и пароль — внизу экрана
    ui = sub_once(ui, r"(\n            id: mainStack\n)",
                  r"\1            y: Math.round(lockScreenRoot.height * 0.27)\n",
                  "положение блока входа")
    # Без кнопок «Сон» / «Сменить пользователя» под полем пароля
    ui = sub_once(ui, r"(\n                lockScreenUiVisible: lockScreenRoot\.uiVisible\n)",
                  r"\1                actionItemsVisible: false\n",
                  "скрыть кнопки")
    (d / "LockScreenUi.qml").write_text(ui)

    mb = (d / "MainBlock.qml").read_text()
    # Узкое поле пароля по центру
    mb = sub_once(mb, r"(\n        id: passwordLayout\n        Layout\.fillWidth: true\n)",
                  r"\1        Layout.maximumWidth: Kirigami.Units.gridUnit * 12\n"
                  r"        Layout.alignment: Qt.AlignHCenter\n",
                  "ширина поля")
    # Полупрозрачное поле-«пилюля»
    mb = sub_once(mb, r"(\n            id: passwordBox\n)",
                  r"\1"
                  '            color: "white"\n'
                  r"            placeholderTextColor: Qt.rgba(1, 1, 1, 0.65)\n"
                  r"            cursorDelegate: Rectangle {\n"
                  r"                width: 2\n"
                  r"                radius: 1\n"
                  '                color: "white"\n'
                  r"                visible: passwordBox.activeFocus\n"
                  r"                SequentialAnimation on opacity {\n"
                  r"                    running: passwordBox.activeFocus\n"
                  r"                    loops: Animation.Infinite\n"
                  r"                    NumberAnimation { to: 0; duration: 500; easing.type: Easing.InOutQuad }\n"
                  r"                    NumberAnimation { to: 1; duration: 500; easing.type: Easing.InOutQuad }\n"
                  r"                }\n"
                  r"            }\n"
                  r"            leftPadding: height / 2\n"
                  r"            topPadding: Kirigami.Units.smallSpacing * 2\n"
                  r"            bottomPadding: Kirigami.Units.smallSpacing * 2\n"
                  r"            background: Rectangle {\n"
                  r"                implicitWidth: Kirigami.Units.gridUnit * 10\n"
                  r"                implicitHeight: Kirigami.Units.gridUnit * 1.9\n"
                  r"                radius: height / 2\n"
                  r"                color: Qt.rgba(1, 1, 1, passwordBox.activeFocus ? 0.24 : 0.18)\n"
                  r"                border.width: 1\n"
                  r"                border.color: Qt.rgba(1, 1, 1, 0.22)\n"
                  r"            }\n",
                  "стиль поля")
    mb = sub_once(mb, r"placeholderText: i18ndc\([^\n]*\"Password\"\)",
                  "placeholderText: \"Введите пароль\"", "подсказка")
    # Круглая кнопка входа со стрелкой
    mb = sub_once(mb, r"(\n            id: loginButton\n)",
                  r"\1            flat: true\n"
                  r"            background: Rectangle {\n"
                  r"                implicitWidth: Kirigami.Units.gridUnit * 1.9\n"
                  r"                implicitHeight: Kirigami.Units.gridUnit * 1.9\n"
                  r"                radius: width / 2\n"
                  r"                color: Qt.rgba(1, 1, 1, loginButton.hovered ? 0.3 : 0.18)\n"
                  r"                border.width: 1\n"
                  r"                border.color: Qt.rgba(1, 1, 1, 0.22)\n"
                  r"            }\n",
                  "кнопка входа")
    (d / "MainBlock.qml").write_text(mb)


if __name__ == "__main__":
    main(sys.argv[1])
