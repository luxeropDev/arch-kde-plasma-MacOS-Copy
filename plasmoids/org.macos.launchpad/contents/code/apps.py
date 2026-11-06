#!/usr/bin/env python3
"""Печатает JSON со списком приложений для Launchpad: имя, иконка, id, категория.

Читает .desktop-файлы из XDG-каталогов и Flatpak (только чтение, ничего не меняет).
"""
import json
import locale
import os
import subprocess
import sys
import time
from pathlib import Path

HIDE_IDS = {"macos-launchpad.desktop", "org.macos.launchpad.desktop", "mac-system-settings.desktop"}
RECENT = Path.home() / ".local/share/macos-kde/launchpad-recent.json"


def load_recent():
    try:
        data = json.loads(RECENT.read_text())
        return [x for x in data if isinstance(x, str)]
    except (OSError, ValueError):
        return []


def launch(app_id):
    """Запоминает запуск (для «Предложений») и открывает приложение."""
    if not app_id.endswith(".desktop") or "/" in app_id:
        return 2
    recent = [app_id] + [x for x in load_recent() if x != app_id]
    RECENT.parent.mkdir(parents=True, exist_ok=True)
    RECENT.write_text(json.dumps(recent[:16]))
    return subprocess.call(["gtk-launch", app_id[:-len(".desktop")]])

# Категории окна «Приложения» в macOS 26–27. Порядок важен: первое совпадение определяет группу
GROUPS = [
    ("Креативность", {"Graphics", "2DGraphics", "3DGraphics", "Photography", "Publishing", "AudioVideoEditing",
                      "Recorder", "Development", "IDE", "Electronics", "Engineering"}),
    ("Развлечения", {"Game", "AudioVideo", "Audio", "Video", "Player", "Music", "Amusement", "TV"}),
    ("Общение", {"Chat", "InstantMessaging", "Email", "VideoConference", "Telephony", "IRCClient", "Network",
                 "WebBrowser", "P2P", "Feed"}),
    ("Информация и чтение", {"Education", "Dictionary", "Documentation", "Science", "Literature", "News",
                             "Viewer", "Geography", "Maps"}),
    ("Продуктивность и финансы", {"Office", "Finance", "Calendar", "ContactManagement", "TextEditor",
                                  "ProjectManagement", "WordProcessor", "Spreadsheet", "Presentation"}),
    ("Утилиты", {"Utility", "System", "Settings", "Monitor", "TerminalEmulator", "FileManager", "Archiving",
                 "Calculator", "Security", "PackageManager", "HardwareSettings"}),
]
OTHER = "Другое"


def data_dirs():
    home = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share"))
    dirs = [home]
    dirs += [Path(p) for p in os.environ.get("XDG_DATA_DIRS", "/usr/local/share:/usr/share").split(":") if p]
    dirs += [Path("/var/lib/flatpak/exports/share"), Path.home() / ".local/share/flatpak/exports/share"]
    seen, out = set(), []
    for d in dirs:
        if d not in seen:
            seen.add(d)
            out.append(d)
    return out


def parse(path):
    entry, in_entry = {}, False
    try:
        for raw in path.read_text(encoding="utf-8", errors="replace").splitlines():
            line = raw.strip()
            if line.startswith("["):
                if in_entry:
                    break
                in_entry = line == "[Desktop Entry]"
                continue
            if in_entry and "=" in line and not line.startswith("#"):
                k, v = line.split("=", 1)
                entry[k.strip()] = v.strip()
    except OSError:
        return None
    return entry


def group_of(categories):
    cats = {c for c in categories.split(";") if c}
    for name, keys in GROUPS:
        if cats & keys:
            return name
    return OTHER


def main():
    lang = (locale.getlocale()[0] or os.environ.get("LANG", "en")).split(".")[0]
    short = lang.split("_")[0]
    apps, seen = {}, set()
    for base in data_dirs():
        for path in sorted((base / "applications").glob("**/*.desktop")):
            app_id = str(path.relative_to(base / "applications")).replace("/", "-")
            if app_id in seen or app_id in HIDE_IDS:
                continue
            e = parse(path)
            if not e or e.get("Type") != "Application":
                continue
            if e.get("NoDisplay") == "true" or e.get("Hidden") == "true":
                continue
            only = e.get("OnlyShowIn")
            if only and "KDE" not in only.split(";"):
                continue
            if "KDE" in e.get("NotShowIn", "").split(";"):
                continue
            seen.add(app_id)
            name = e.get(f"Name[{lang}]") or e.get(f"Name[{short}]") or e.get("Name") or app_id
            apps[app_id] = {
                "id": app_id, "name": name, "icon": e.get("Icon", "application-x-executable"),
                "group": group_of(e.get("Categories", "")),
            }
    ordered = sorted(apps.values(), key=lambda a: a["name"].casefold())
    recent = [i for i in load_recent() if i in apps][:8]
    print(json.dumps({"apps": ordered, "recent": recent}, ensure_ascii=False))


if __name__ == "__main__":
    if len(sys.argv) == 3 and sys.argv[1] == "launch":
        sys.exit(launch(sys.argv[2]))
    main()
