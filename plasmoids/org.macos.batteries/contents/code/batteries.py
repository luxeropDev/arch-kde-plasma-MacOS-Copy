#!/usr/bin/env python3
"""Печатает JSON с зарядом устройств: ноутбук (UPower), телефон (KDE Connect), Bluetooth (BlueZ)."""
import json
import re
import shutil
import subprocess


def run(args, timeout=4):
    if not shutil.which(args[0]):
        return ""
    try:
        return subprocess.run(args, capture_output=True, text=True, timeout=timeout).stdout
    except (subprocess.TimeoutExpired, OSError):
        return ""


def laptop():
    bat = next((d for d in run(["upower", "-e"]).split() if "battery_BAT" in d), "")
    if not bat:
        return None
    info = run(["upower", "-i", bat])
    pct = re.search(r"percentage:\s*([\d.,]+)", info)
    state = re.search(r"state:\s*(\S+)", info)
    if not pct:
        return None
    return {"kind": "laptop", "name": "Ноутбук", "level": int(float(pct.group(1).replace(",", "."))),
            "charging": bool(state and state.group(1) in ("charging", "fully-charged", "pending-charge"))}


def phones():
    out = []
    for line in run(["kdeconnect-cli", "-a", "--id-name-only"], 8).splitlines():
        parts = line.strip().split(" ", 1)
        if len(parts) != 2 or not re.match(r"^[0-9A-Za-z_]{8,64}$", parts[0]):
            continue
        path = f"/modules/kdeconnect/devices/{parts[0]}/battery"
        iface = "org.kde.kdeconnect.device.battery"
        def prop(name):
            raw = run(["busctl", "--user", "--json=short", "get-property", "org.kde.kdeconnect", path, iface, name])
            try:
                return json.loads(raw)["data"]
            except (ValueError, KeyError):
                return None
        level = prop("charge")
        if isinstance(level, int) and level >= 0:
            out.append({"kind": "phone", "name": parts[1], "level": level, "charging": bool(prop("isCharging"))})
    return out


def bluetooth():
    raw = run(["busctl", "--system", "--json=short", "call", "org.bluez", "/",
               "org.freedesktop.DBus.ObjectManager", "GetManagedObjects"])
    try:
        objects = json.loads(raw)["data"][0]
    except (ValueError, KeyError, IndexError):
        return []
    val = lambda d, k: (d.get(k) or {}).get("data")
    out = []
    for ifaces in objects.values():
        dev, bat = ifaces.get("org.bluez.Device1"), ifaces.get("org.bluez.Battery1")
        if not dev or not bat or not val(dev, "Connected"):
            continue
        icon = val(dev, "Icon") or ""
        kind = "headphones" if "audio" in icon else ("mouse" if "mouse" in icon else
               "keyboard" if "keyboard" in icon else "watch" if "watch" in (val(dev, "Alias") or "").lower() else "device")
        out.append({"kind": kind, "name": val(dev, "Alias") or val(dev, "Name") or "Устройство",
                    "level": int(val(bat, "Percentage")), "charging": False})
    return out


devices = [d for d in [laptop()] if d] + phones() + bluetooth()
print(json.dumps(devices, ensure_ascii=False))
