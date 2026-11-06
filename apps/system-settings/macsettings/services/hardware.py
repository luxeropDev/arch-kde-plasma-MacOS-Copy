"""Звук (PipeWire), дисплей, клавиатура, мышь и трекпад."""

from __future__ import annotations

import re

from ..runner import run
from . import kconfig

# ------------------------------------------------------------------ звук
_SINK = re.compile(r"^\s*│?\s*(\*)?\s*(\d+)\.\s+(.+?)\s*(?:\[vol:\s*([\d.]+)(\s+MUTED)?\])?\s*$")


def parse_wpctl_status(text: str) -> dict:
    """Достаёт устройства вывода и ввода из `wpctl status` (раздел Audio)."""
    result = {"sinks": [], "sources": []}
    section, in_audio = None, False
    for raw in text.splitlines():
        line = raw.replace("├─", "").replace("└─", "").replace("│", " ")
        if raw.startswith("Audio"):
            in_audio = True
            continue
        if raw and not raw[0].isspace() and not raw.startswith("Audio") and not raw.startswith(" "):
            in_audio = raw.startswith("Audio")
        if not in_audio:
            continue
        stripped = line.strip()
        if stripped.startswith("Sinks:"):
            section = "sinks"
            continue
        if stripped.startswith("Sources:"):
            section = "sources"
            continue
        if stripped.endswith(":"):
            section = None
            continue
        if section and stripped:
            m = _SINK.match(stripped)
            if m:
                result[section].append({
                    "id": int(m.group(2)), "default": bool(m.group(1)),
                    "name": m.group(3).strip(),
                })
    return result


def parse_volume(text: str) -> tuple[float, bool]:
    m = re.search(r"Volume:\s*([\d.]+)", text)
    return (float(m.group(1)) if m else 0.0), ("MUTED" in text)


def audio_state() -> dict:
    status = parse_wpctl_status(run(["wpctl", "status"], timeout=5).out)
    out_vol, out_muted = parse_volume(run(["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"], timeout=4).out)
    in_vol, in_muted = parse_volume(run(["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"], timeout=4).out)
    return {"outputs": status["sinks"], "inputs": status["sources"],
            "volume": min(1.0, out_vol), "muted": out_muted,
            "inputVolume": min(1.0, in_vol), "inputMuted": in_muted}


def set_volume(value: float, source: bool = False):
    target = "@DEFAULT_AUDIO_SOURCE@" if source else "@DEFAULT_AUDIO_SINK@"
    return run(["wpctl", "set-volume", "-l", "1.0", target, f"{max(0.0, min(1.0, value)):.2f}"], timeout=4)


def set_mute(muted: bool, source: bool = False):
    target = "@DEFAULT_AUDIO_SOURCE@" if source else "@DEFAULT_AUDIO_SINK@"
    return run(["wpctl", "set-mute", target, "1" if muted else "0"], timeout=4)


def set_default_device(node_id: int):
    return run(["wpctl", "set-default", str(int(node_id))], timeout=4)


# ------------------------------------------------------------------ дисплей
def _display_path() -> str:
    res = run(["qdbus6", "org.kde.ScreenBrightness"], timeout=4)
    return next((l for l in res.out.splitlines() if l.startswith("/org/kde/ScreenBrightness/display")), "")


def display_state() -> dict:
    path = _display_path()
    data = {"hasBrightness": False, "brightness": 0.0}
    if path:
        def get(prop):
            r = run(["qdbus6", "org.kde.ScreenBrightness", path, "org.freedesktop.DBus.Properties.Get",
                     "org.kde.ScreenBrightness.Display", prop], timeout=4)
            return int(r.out.strip()) if r.ok and r.out.strip().isdigit() else 0
        cur, mx = get("Brightness"), get("MaxBrightness")
        if mx > 0:
            data.update(hasBrightness=True, brightness=cur / mx, path=path, max=mx)
    data["nightShift"] = kconfig.as_bool(kconfig.read("kwinrc", ["NightColor"], "Active"))
    return data


def set_brightness(value: float):
    path = _display_path()
    if not path:
        return None
    mx_res = run(["qdbus6", "org.kde.ScreenBrightness", path, "org.freedesktop.DBus.Properties.Get",
                  "org.kde.ScreenBrightness.Display", "MaxBrightness"], timeout=4)
    mx = int(mx_res.out.strip() or 0)
    if mx <= 0:
        return None
    level = max(1, round(max(0.0, min(1.0, value)) * mx))
    return run(["qdbus6", "org.kde.ScreenBrightness", path, "org.kde.ScreenBrightness.Display.SetBrightness",
                str(level), "1"], timeout=4)


def set_night_shift(on: bool) -> bool:
    ok = kconfig.write("kwinrc", ["NightColor"], "Active", on)
    kconfig.kwin_reconfigure()
    return ok


# ------------------------------------------------------------------ клавиатура
def keyboard_state() -> dict:
    delay = kconfig.read("kcminputrc", ["Keyboard"], "RepeatDelay", "600")
    rate = kconfig.read("kcminputrc", ["Keyboard"], "RepeatRate", "25")
    layouts = kconfig.read("kxkbrc", ["Layout"], "LayoutList", "")
    return {"repeatDelay": int(float(delay)), "repeatRate": int(float(rate)),
            "layouts": [l for l in layouts.split(",") if l]}


def set_keyboard_repeat(delay: int, rate: int) -> bool:
    delay = max(100, min(2000, int(delay)))
    rate = max(1, min(100, int(rate)))
    ok = kconfig.write("kcminputrc", ["Keyboard"], "RepeatDelay", delay)
    ok &= kconfig.write("kcminputrc", ["Keyboard"], "RepeatRate", rate)
    ok &= kconfig.write("kcminputrc", ["Keyboard"], "KeyRepeat", "repeat")
    # KWin перечитывает параметры клавиатуры по этому сигналу
    run(["dbus-send", "--session", "--type=signal", "/Layouts", "org.kde.keyboard.reloadConfig"], timeout=4)
    kconfig.kwin_reconfigure()
    return ok


# ------------------------------------------------------------------ мышь и трекпад
_IFACE = "org.kde.KWin.InputDevice"


def _prop(dev: str, name: str) -> str:
    r = run(["qdbus6", "org.kde.KWin", f"/org/kde/KWin/InputDevice/{dev}",
             "org.freedesktop.DBus.Properties.Get", _IFACE, name], timeout=3)
    return r.out.strip() if r.ok else ""


def pointer_devices() -> list[dict]:
    res = run(["qdbus6", "org.kde.KWin", "/org/kde/KWin/InputDevice",
               "org.kde.KWin.InputDeviceManager.devicesSysNames"], timeout=4)
    out = []
    for dev in res.out.split():
        if _prop(dev, "pointer") != "true":
            continue
        name = _prop(dev, "name")
        if "Consumer Control" in name or "Keyboard" in name:
            continue
        touchpad = _prop(dev, "touchpad") == "true"
        try:
            accel = float(_prop(dev, "pointerAcceleration") or 0)
        except ValueError:
            accel = 0.0
        out.append({
            "sys": dev, "name": name, "touchpad": touchpad,
            "vendor": _prop(dev, "vendor"), "product": _prop(dev, "product"),
            "acceleration": accel,
            "naturalScroll": _prop(dev, "naturalScroll") == "true",
            "tapToClick": _prop(dev, "tapToClick") == "true",
            "supportsTap": _prop(dev, "tapFingerCount") not in ("", "0"),
        })
    return out


_KEYS = {"naturalScroll": "NaturalScroll", "tapToClick": "TapToClick", "pointerAcceleration": "PointerAcceleration"}


def set_pointer_option(dev: dict, prop: str, value) -> bool:
    """Меняет параметр сразу (D-Bus KWin) и сохраняет его так же, как модуль настроек KDE."""
    if prop not in _KEYS or not re.match(r"^event\d+$", dev.get("sys", "")):
        return False
    if isinstance(value, bool):
        sval = "true" if value else "false"
        variant = ["b", sval]
    else:
        value = max(-1.0, min(1.0, float(value)))
        sval = f"{value:.2f}"
        variant = ["d", sval]
    res = run(["busctl", "--user", "set-property", "org.kde.KWin", f"/org/kde/KWin/InputDevice/{dev['sys']}",
               _IFACE, prop, *variant], timeout=4)
    group = ["Libinput", str(dev.get("vendor", "")), str(dev.get("product", "")), dev.get("name", "")]
    saved = kconfig.write("kcminputrc", group, _KEYS[prop], sval)
    return res.ok and saved
