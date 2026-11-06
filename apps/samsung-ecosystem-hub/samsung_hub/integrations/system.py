"""Диагностика окружения: что установлено, какая сессия, что с брандмауэром."""

from __future__ import annotations

import os

from ..services.runner import have, run

TOOLS = [
    ("kdeconnect-cli", "kdeconnect", "связь с телефоном, файлы, уведомления"),
    ("adb", "android-tools", "ADB для зеркалирования экрана"),
    ("scrcpy", "scrcpy", "зеркалирование экрана телефона"),
    ("bluetoothctl", "bluez-utils", "управление Bluetooth"),
    ("busctl", "systemd", "чтение D-Bus (BlueZ, KDE Connect)"),
    ("flatpak", "flatpak", "установка GalaxyBudsClient"),
    ("wpctl", "wireplumber", "аудио PipeWire"),
]


def tool_report() -> list[dict]:
    return [{"command": cmd, "package": pkg, "purpose": why, "present": have(cmd)} for cmd, pkg, why in TOOLS]


def missing_packages() -> list[str]:
    seen: list[str] = []
    for item in tool_report():
        if not item["present"] and item["package"] not in seen and item["package"] != "systemd":
            seen.append(item["package"])
    return seen


def firewall_hint() -> str:
    """KDE Connect использует порты 1714–1764 (TCP и UDP). Показываем статус, ничего не меняем."""
    for service in ("ufw", "firewalld"):
        if run(["systemctl", "is-active", service], timeout=3).out.strip() == "active":
            if service == "ufw":
                return ("Брандмауэр ufw включён. Для KDE Connect откройте порты (один раз, в терминале): "
                        "sudo ufw allow 1714:1764/tcp && sudo ufw allow 1714:1764/udp")
            return ("Брандмауэр firewalld включён. Для KDE Connect выполните: "
                    "sudo firewall-cmd --permanent --add-service=kdeconnect && sudo firewall-cmd --reload")
    return "Активный брандмауэр не обнаружен."


def session_info() -> dict:
    return {
        "session": os.environ.get("XDG_SESSION_TYPE", "?"),
        "desktop": os.environ.get("XDG_CURRENT_DESKTOP", "?"),
    }
