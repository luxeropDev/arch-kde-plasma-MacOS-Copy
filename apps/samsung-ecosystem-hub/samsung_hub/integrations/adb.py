"""ADB и scrcpy. USB-отладку приложение не включает — только проверяет, авторизовал ли её пользователь."""

from __future__ import annotations

import re

from ..models.device import AdbDevice
from ..services.runner import CmdResult, have, run, spawn_detached

_SERIAL = re.compile(r"^[0-9A-Za-z._:\-]{3,64}$")


def adb_available() -> bool:
    return have("adb")


def scrcpy_available() -> bool:
    return have("scrcpy")


def valid_serial(serial: str) -> bool:
    return bool(_SERIAL.match(serial or ""))


def parse_devices(text: str) -> list[AdbDevice]:
    """Разбирает `adb devices -l`."""
    devices = []
    for line in text.splitlines()[1:]:
        line = line.strip()
        if not line or line.startswith("*"):
            continue
        parts = line.split()
        if len(parts) < 2:
            continue
        model = ""
        for token in parts[2:]:
            if token.startswith("model:"):
                model = token.split(":", 1)[1].replace("_", " ")
        devices.append(AdbDevice(serial=parts[0], state=parts[1], model=model))
    return devices


def parse_battery(text: str) -> int | None:
    m = re.search(r"^\s*level:\s*(\d+)\s*$", text, re.M)
    return int(m.group(1)) if m else None


def list_devices() -> tuple[list[AdbDevice], CmdResult]:
    res = run(["adb", "devices", "-l"], timeout=10)
    if not res.ok:
        return [], res
    devices = parse_devices(res.out)
    for dev in devices:
        if dev.authorized:
            info = run(["adb", "-s", dev.serial, "shell", "dumpsys", "battery"], timeout=6)
            if info.ok:
                dev.battery = parse_battery(info.out)
    return devices, res


def launch_scrcpy(serial: str) -> tuple[bool, str]:
    if not valid_serial(serial):
        return False, "некорректный серийный номер"
    return spawn_detached(["scrcpy", "-s", serial, "--window-title", "Galaxy — Samsung Ecosystem Hub"])
