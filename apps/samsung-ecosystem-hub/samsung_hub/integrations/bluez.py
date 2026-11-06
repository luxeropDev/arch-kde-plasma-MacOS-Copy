"""BlueZ через D-Bus (busctl --json) и bluetoothctl для действий."""

from __future__ import annotations

import json
import re

from ..models.device import BtDevice
from ..services.runner import CmdResult, run

_BUDS = re.compile(r"galaxy\s*buds|\bbuds\s?(?:pro|live|fe|core|2|3)\b", re.I)
_WATCH = re.compile(r"galaxy\s*watch|\bgear\s?(?:s\d|fit)", re.I)


def classify(name: str) -> str:
    """'buds' | 'watch' | 'other' — по имени, которое устройство само сообщает по Bluetooth."""
    if _BUDS.search(name):
        return "buds"
    if _WATCH.search(name):
        return "watch"
    return "other"


def _val(props: dict, key: str, default=None):
    item = props.get(key)
    return item["data"] if isinstance(item, dict) and "data" in item else default


def parse_managed_objects(json_text: str) -> tuple[bool | None, list[BtDevice]]:
    """Разбирает ответ GetManagedObjects → (адаптер включён?, список известных устройств)."""
    try:
        objects = json.loads(json_text)["data"][0]
    except (ValueError, KeyError, IndexError, TypeError):
        return None, []

    powered: bool | None = None
    devices: list[BtDevice] = []
    for path, ifaces in objects.items():
        adapter = ifaces.get("org.bluez.Adapter1")
        if adapter is not None and powered is None:
            powered = bool(_val(adapter, "Powered", False))
        dev = ifaces.get("org.bluez.Device1")
        if dev is None:
            continue
        battery = ifaces.get("org.bluez.Battery1")
        name = _val(dev, "Alias") or _val(dev, "Name") or _val(dev, "Address", "")
        devices.append(BtDevice(
            path=path,
            address=_val(dev, "Address", ""),
            name=name,
            paired=bool(_val(dev, "Paired", False)),
            connected=bool(_val(dev, "Connected", False)),
            trusted=bool(_val(dev, "Trusted", False)),
            battery=int(_val(battery, "Percentage")) if battery and _val(battery, "Percentage") is not None else None,
            icon=_val(dev, "Icon", ""),
        ))
    return powered, devices


def snapshot() -> tuple[bool | None, list[BtDevice], CmdResult]:
    res = run(["busctl", "--system", "--json=short", "call", "org.bluez", "/",
               "org.freedesktop.DBus.ObjectManager", "GetManagedObjects"], timeout=5)
    if not res.ok:
        return None, [], res
    powered, devices = parse_managed_objects(res.out)
    return powered, devices, res


def set_power(on: bool) -> CmdResult:
    """Включает/выключает адаптер. Снимает программную блокировку rfkill, если она есть."""
    if on:
        run(["rfkill", "unblock", "bluetooth"], timeout=4)
    return run(["bluetoothctl", "power", "on" if on else "off"], timeout=8)


def connect(address: str) -> CmdResult:
    return run(["bluetoothctl", "connect", address], timeout=20)


def disconnect(address: str) -> CmdResult:
    return run(["bluetoothctl", "disconnect", address], timeout=10)
