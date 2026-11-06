"""KDE Connect: kdeconnect-cli для действий, D-Bus (busctl) для батареи."""

from __future__ import annotations

import json
import re

from ..models.device import KcDevice
from ..services.runner import CmdResult, have, run

# «- Имя: id (статус)» или новый формат «- Имя: id on 192.168.1.5 via LAN (статус)»
_LINE = re.compile(r"^-\s+(?P<name>.+?):\s+(?P<id>[0-9A-Za-z_]{8,64})\b.*\((?P<status>[^)]*)\)\s*$")
_ID = re.compile(r"^[0-9A-Za-z_]{8,64}$")


def available() -> bool:
    return have("kdeconnect-cli")


def valid_id(device_id: str) -> bool:
    """Защита от подстановки в аргументы: id KDE Connect — только буквы, цифры и «_»."""
    return bool(_ID.match(device_id or ""))


def parse_list(text: str) -> list[KcDevice]:
    """Разбирает вывод `kdeconnect-cli -l`: «- Имя: id (paired and reachable)»."""
    devices = []
    for line in text.splitlines():
        m = _LINE.match(line.strip())
        if not m:
            continue
        status = m.group("status").lower()
        devices.append(KcDevice(
            device_id=m.group("id"),
            name=m.group("name"),
            paired="paired" in status and "unpaired" not in status and "not paired" not in status,
            reachable="reachable" in status and "unreachable" not in status,
        ))
    return devices


def parse_busctl_value(text: str):
    try:
        return json.loads(text)["data"]
    except (ValueError, KeyError, TypeError):
        return None


def battery(device_id: str) -> tuple[int | None, bool | None]:
    """Заряд телефона из KDE Connect (плагин battery на обоих устройствах должен быть включён)."""
    if not valid_id(device_id):
        return None, None
    path = f"/modules/kdeconnect/devices/{device_id}/battery"
    iface = "org.kde.kdeconnect.device.battery"
    charge = run(["busctl", "--user", "--json=short", "get-property", "org.kde.kdeconnect", path, iface, "charge"], timeout=4)
    if not charge.ok:
        return None, None
    level = parse_busctl_value(charge.out)
    if not isinstance(level, int) or level < 0:
        return None, None
    charging = run(["busctl", "--user", "--json=short", "get-property", "org.kde.kdeconnect", path, iface, "isCharging"], timeout=4)
    return level, (parse_busctl_value(charging.out) if charging.ok else None)


def list_devices() -> tuple[list[KcDevice], CmdResult]:
    res = run(["kdeconnect-cli", "-l"], timeout=10)
    if not res.ok:
        return [], res
    devices = parse_list(res.out)
    for dev in devices:
        if dev.paired and dev.reachable:
            dev.battery, dev.charging = battery(dev.device_id)
    return devices, res


def _cmd(device_id: str, *flags: str) -> CmdResult:
    if not valid_id(device_id):
        return CmdResult(False, 2, err="некорректный id устройства")
    return run(["kdeconnect-cli", "-d", device_id, *flags], timeout=15)


def pair(device_id: str) -> CmdResult:
    return _cmd(device_id, "--pair")


def unpair(device_id: str) -> CmdResult:
    return _cmd(device_id, "--unpair")


def ping(device_id: str) -> CmdResult:
    return _cmd(device_id, "--ping")


def ring(device_id: str) -> CmdResult:
    return _cmd(device_id, "--ring")


def send_clipboard(device_id: str) -> CmdResult:
    return _cmd(device_id, "--send-clipboard")


def share_file(device_id: str, path: str) -> CmdResult:
    return _cmd(device_id, "--share", path)


def share_text(device_id: str, text: str) -> CmdResult:
    return _cmd(device_id, "--share-text", text)


def list_notifications(device_id: str) -> CmdResult:
    return _cmd(device_id, "--list-notifications")
