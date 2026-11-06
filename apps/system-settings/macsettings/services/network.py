"""Wi‑Fi (NetworkManager) и Bluetooth (BlueZ)."""

from __future__ import annotations

import json
import re

from ..runner import run


def split_nmcli(line: str) -> list[str]:
    """Разбивает строку `nmcli -t` по «:», учитывая экранирование «\\:»."""
    parts, cur, esc = [], [], False
    for ch in line:
        if esc:
            cur.append(ch)
            esc = False
        elif ch == "\\":
            esc = True
        elif ch == ":":
            parts.append("".join(cur))
            cur = []
        else:
            cur.append(ch)
    parts.append("".join(cur))
    return parts


def parse_wifi_list(text: str) -> list[dict]:
    """Одна запись на SSID: активна, если активна любая её точка доступа; сигнал — лучший."""
    by_ssid: dict[str, dict] = {}
    for line in text.splitlines():
        f = split_nmcli(line)
        if len(f) < 4 or not f[1]:
            continue
        signal = int(f[2]) if f[2].isdigit() else 0
        net = by_ssid.setdefault(f[1], {"active": False, "ssid": f[1], "signal": 0, "secure": False})
        net["active"] |= f[0] in ("*", "yes")
        net["signal"] = max(net["signal"], signal)
        net["secure"] |= f[3] not in ("", "--")
    return sorted(by_ssid.values(), key=lambda n: (not n["active"], -n["signal"]))


def wifi_state() -> dict:
    radio = run(["nmcli", "radio", "wifi"], timeout=4).out.strip() == "enabled"
    nets = []
    if radio:
        res = run(["nmcli", "-t", "-f", "ACTIVE,SSID,SIGNAL,SECURITY", "device", "wifi", "list", "--rescan", "no"], timeout=8)
        nets = parse_wifi_list(res.out) if res.ok else []
    known = run(["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"], timeout=4).out
    saved = {split_nmcli(l)[0] for l in known.splitlines() if l.endswith(":802-11-wireless")}
    for n in nets:
        n["known"] = n["ssid"] in saved
    current = next((n["ssid"] for n in nets if n["active"]), "")
    return {"enabled": radio, "current": current, "networks": nets[:15]}


def set_wifi(on: bool):
    return run(["nmcli", "radio", "wifi", "on" if on else "off"], timeout=8)


def connect_known(ssid: str):
    """Подключение только к сохранённой сети (пароль уже хранится в NetworkManager)."""
    return run(["nmcli", "connection", "up", "id", ssid], timeout=30)


def active_connections() -> list[dict]:
    res = run(["nmcli", "-t", "-f", "NAME,TYPE,DEVICE", "connection", "show", "--active"], timeout=4)
    out = []
    for line in res.out.splitlines():
        f = split_nmcli(line)
        if len(f) >= 3 and f[1] != "loopback":
            kind = {"802-11-wireless": "Wi‑Fi", "802-3-ethernet": "Ethernet", "vpn": "VPN",
                    "wireguard": "WireGuard", "bluetooth": "Bluetooth"}.get(f[1], f[1])
            out.append({"name": f[0], "type": kind, "device": f[2]})
    return out


# ----------------------------------------------------------------- Bluetooth
def _val(props: dict, key: str, default=None):
    item = props.get(key)
    return item["data"] if isinstance(item, dict) and "data" in item else default


def parse_bluez(json_text: str) -> tuple[bool | None, list[dict]]:
    try:
        objects = json.loads(json_text)["data"][0]
    except (ValueError, KeyError, IndexError, TypeError):
        return None, []
    powered, devices = None, []
    for path, ifaces in objects.items():
        adapter = ifaces.get("org.bluez.Adapter1")
        if adapter is not None and powered is None:
            powered = bool(_val(adapter, "Powered", False))
        dev = ifaces.get("org.bluez.Device1")
        if dev is None or not _val(dev, "Paired", False):
            continue
        battery = ifaces.get("org.bluez.Battery1") or {}
        devices.append({
            "address": _val(dev, "Address", ""),
            "name": _val(dev, "Alias") or _val(dev, "Name") or _val(dev, "Address", ""),
            "connected": bool(_val(dev, "Connected", False)),
            "icon": _val(dev, "Icon", "") or "",
            "battery": int(_val(battery, "Percentage", -1)),
        })
    devices.sort(key=lambda d: (not d["connected"], d["name"].casefold()))
    return powered, devices


def bluetooth_state() -> dict:
    res = run(["busctl", "--system", "--json=short", "call", "org.bluez", "/",
               "org.freedesktop.DBus.ObjectManager", "GetManagedObjects"], timeout=5)
    powered, devices = parse_bluez(res.out) if res.ok else (None, [])
    return {"available": powered is not None, "enabled": bool(powered), "devices": devices}


_MAC = re.compile(r"^[0-9A-F]{2}(:[0-9A-F]{2}){5}$", re.I)


def set_bluetooth(on: bool):
    if on:
        run(["rfkill", "unblock", "bluetooth"], timeout=4)
    return run(["bluetoothctl", "power", "on" if on else "off"], timeout=8)


def bt_connect(address: str, connect: bool):
    if not _MAC.match(address or ""):
        return None
    return run(["bluetoothctl", "connect" if connect else "disconnect", address], timeout=20)
