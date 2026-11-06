"""Оформление, Dock (Krema), экран блокировки, обои, уведомления и модули настроек KDE."""

from __future__ import annotations

import os
import re
import shutil
from pathlib import Path

from ..runner import have, run, spawn_detached
from . import kconfig

# macOS-акценты → цвет KDE (R,G,B)
ACCENTS = {
    "multicolor": "",
    "blue": "0,122,255", "purple": "175,82,222", "pink": "255,45,85", "red": "255,59,48",
    "orange": "255,149,0", "yellow": "255,204,0", "green": "52,199,89", "graphite": "142,142,147",
}


# ------------------------------------------------------------------ оформление
def appearance_state() -> dict:
    scheme = kconfig.read("kdeglobals", ["General"], "ColorScheme")
    auto = kconfig.as_bool(kconfig.read("kdeglobals", ["KDE"], "AutomaticLookAndFeel"))
    accent_raw = kconfig.read("kdeglobals", ["General"], "AccentColor")
    accent = next((k for k, v in ACCENTS.items() if v and v == accent_raw.replace(" ", "")), "multicolor")
    if accent_raw and accent == "multicolor":
        accent = "custom"
    blur = int(kconfig.read("kwinrc", ["Effect-blur"], "BlurStrength", "10") or 10)
    return {
        "mode": "auto" if auto else ("dark" if "dark" in scheme.lower() else "light"),
        "accent": accent,
        "glass": max(1, min(15, blur)),
        "theme": scheme.replace("Dark", "").replace("Light", "") or "MacTahoe",
    }


def _family() -> str:
    lnf = kconfig.read("kdeglobals", ["KDE"], "LookAndFeelPackage", "com.github.vinceliuice.MacTahoe-Dark")
    return re.sub(r"-(Dark|Light)$", "", lnf)


def set_appearance(mode: str) -> bool:
    """light | dark | auto. Авто — как в macOS: днём светлая, ночью тёмная (служба KDE)."""
    family = _family()
    if mode == "auto":
        ok = kconfig.write("kdeglobals", ["KDE"], "DefaultLightLookAndFeel", family + "-Light")
        ok &= kconfig.write("kdeglobals", ["KDE"], "DefaultDarkLookAndFeel", family + "-Dark")
        ok &= kconfig.write("kdeglobals", ["KDE"], "AutomaticLookAndFeel", True)
        return ok
    if mode not in ("light", "dark"):
        return False
    kconfig.write("kdeglobals", ["KDE"], "AutomaticLookAndFeel", False)
    helper = Path.home() / ".local/bin/macos-appearance"
    if helper.exists():
        return run([str(helper), mode], timeout=30).ok
    variant = "Dark" if mode == "dark" else "Light"
    return run(["plasma-apply-colorscheme", f"MacTahoe{variant}"], timeout=15).ok


def set_accent(name: str) -> bool:
    if name not in ACCENTS:
        return False
    value = ACCENTS[name]
    if value:
        return run(["plasma-apply-colorscheme", "--accent-color", "#%02x%02x%02x" % tuple(map(int, value.split(",")))],
                   timeout=15).ok
    # «Разноцветный» в macOS = акцент из темы: убираем свой цвет и переприменяем схему
    run(["kwriteconfig6", "--file", "kdeglobals", "--group", "General", "--key", "AccentColor", "--delete"], timeout=4)
    scheme = kconfig.read("kdeglobals", ["General"], "ColorScheme")
    return run(["plasma-apply-colorscheme", scheme], timeout=15).ok if scheme else True


def set_glass(level: int) -> bool:
    """«Стекло» (аналог ползунка Liquid Glass): сила размытия под прозрачными панелями и окнами."""
    level = max(1, min(15, int(level)))
    ok = kconfig.write("kwinrc", ["Effect-blur"], "BlurStrength", level)
    ok &= kconfig.write("kwinrc", ["Plugins"], "blurEnabled", True)
    kconfig.kwin_reconfigure()
    return ok


# ------------------------------------------------------------------ Dock (Krema)
def dock_state() -> dict:
    if not have("krema"):
        return {"available": False}
    rd = lambda k, d: kconfig.read("kremarc", ["General"], k, d)
    minimize = "genie" if kconfig.as_bool(kconfig.read("kwinrc", ["Plugins"], "magiclampEnabled"), False) else "scale"
    return {
        "available": True,
        "size": int(float(rd("IconSize", "48"))),
        "magnification": float(rd("MaxZoomFactor", "1.6")),
        "magnify": float(rd("MaxZoomFactor", "1.6")) > 1.0,
        "position": {"0": "top", "1": "bottom", "2": "left", "3": "right"}.get(rd("Edge", "1"), "bottom"),
        "autohide": rd("VisibilityMode", "0") == "1",
        "visibility": int(rd("VisibilityMode", "0")),
        "minimize": minimize,
        "running": run(["pgrep", "-x", "krema"], timeout=3).ok,
    }


def _restart_krema() -> None:
    run(["pkill", "-x", "krema"], timeout=3)
    spawn_detached(["krema"])


def set_dock(key: str, value) -> bool:
    mapping = {
        "size": ("IconSize", lambda v: max(24, min(96, int(v)))),
        "magnification": ("MaxZoomFactor", lambda v: f"{max(1.0, min(2.0, float(v))):.2f}"),
        "position": ("Edge", lambda v: {"top": 0, "bottom": 1, "left": 2, "right": 3}[v]),
        "visibility": ("VisibilityMode", lambda v: max(0, min(2, int(v)))),
    }
    if key == "minimize":
        genie = value == "genie"
        ok = kconfig.write("kwinrc", ["Plugins"], "magiclampEnabled", genie)
        ok &= kconfig.write("kwinrc", ["Plugins"], "squashEnabled", False)
        ok &= kconfig.write("kwinrc", ["Plugins"], "minimizeanimationEnabled", not genie)
        kconfig.kwin_reconfigure()
        return ok
    if key not in mapping:
        return False
    cfg_key, conv = mapping[key]
    try:
        ok = kconfig.write("kremarc", ["General"], cfg_key, conv(value), notify=False)
    except (KeyError, ValueError):
        return False
    _restart_krema()
    return ok


# ------------------------------------------------------------------ экран блокировки
def lock_state() -> dict:
    rd = lambda k, d: kconfig.read("kscreenlockerrc", ["Daemon"], k, d)
    return {
        "autolock": kconfig.as_bool(rd("Autolock", "true"), True),
        "timeout": int(rd("Timeout", "5")),
        "lockOnResume": kconfig.as_bool(rd("LockOnResume", "true"), True),
        "grace": int(rd("LockGrace", "5")),
    }


def set_lock(key: str, value) -> bool:
    keys = {"autolock": "Autolock", "timeout": "Timeout", "lockOnResume": "LockOnResume", "grace": "LockGrace"}
    if key not in keys:
        return False
    if key in ("timeout", "grace"):
        value = max(0, min(600, int(value)))
    return kconfig.write("kscreenlockerrc", ["Daemon"], keys[key], value)


# ------------------------------------------------------------------ обои
def _image_of(pkg: Path) -> Path | None:
    imgs = sorted((pkg / "contents" / "images").glob("*.*"))
    imgs = [p for p in imgs if p.suffix.lower() in (".jpg", ".jpeg", ".png", ".webp", ".avif")]
    return imgs[-1] if imgs else None


def wallpapers() -> list[dict]:
    roots = [Path.home() / ".local/share/wallpapers", Path("/usr/share/wallpapers")]
    out, seen = [], set()
    for root in roots:
        if not root.is_dir():
            continue
        for entry in sorted(root.iterdir()):
            if entry.name in seen:
                continue
            if entry.is_dir():
                img = _image_of(entry)
                if img:
                    seen.add(entry.name)
                    out.append({"name": entry.name, "path": str(entry), "preview": str(img)})
            elif entry.suffix.lower() in (".jpg", ".jpeg", ".png", ".webp"):
                seen.add(entry.name)
                out.append({"name": entry.stem, "path": str(entry), "preview": str(entry)})
    return out


def current_wallpaper() -> str:
    cfg = Path.home() / ".config/plasma-org.kde.plasma.desktop-appletsrc"
    try:
        m = re.search(r"^Image=(?:file://)?(.+)$", cfg.read_text(errors="replace"), re.M)
    except OSError:
        return ""
    return m.group(1).strip() if m else ""


def set_wallpaper(path: str, lock_screen: bool = True) -> bool:
    p = Path(path)
    allowed = (Path.home() / ".local/share/wallpapers", Path("/usr/share/wallpapers"))
    if not p.exists() or not any(str(p).startswith(str(a)) for a in allowed):
        return False
    ok = run(["plasma-apply-wallpaperimage", str(p)], timeout=15).ok
    if lock_screen:
        kconfig.write("kscreenlockerrc", ["Greeter", "Wallpaper", "org.kde.image", "General"], "Image", "file://" + str(p))
    return ok


# ------------------------------------------------------------------ модули KDE
def kcm_available(name: str) -> bool:
    if not re.match(r"^kcm_[a-z0-9_\-]+$", name):
        return False
    return any(Path(d, name + ".so").exists() for d in (
        "/usr/lib/qt6/plugins/plasma/kcms/systemsettings",
        "/usr/lib/qt6/plugins/plasma/kcms/systemsettings_qwidgets",
        "/usr/lib/qt6/plugins/plasma/kcms",
    )) or run(["kcmshell6", "--list"], timeout=6).out.find(name) >= 0


def open_kcm(name: str) -> tuple[bool, str]:
    if not re.match(r"^kcm_[a-z0-9_\-]+$", name):
        return False, "неизвестный модуль"
    return spawn_detached(["kcmshell6", name])


def open_app(desktop_id: str) -> tuple[bool, str]:
    if not re.match(r"^[\w.\-]+$", desktop_id):
        return False, "неизвестное приложение"
    return spawn_detached(["gtk-launch", desktop_id])
