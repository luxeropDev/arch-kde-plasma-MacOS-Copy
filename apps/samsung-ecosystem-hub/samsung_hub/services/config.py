"""Настройки приложения (JSON в ~/.config) и автозапуск через XDG autostart."""

from __future__ import annotations

import json
import os
from pathlib import Path

from .. import APP_ID, APP_NAME

DEFAULTS = {
    "theme": "system",          # system | light | dark
    "refresh_seconds": 8,
    "autostart": False,
}


def _config_dir() -> Path:
    return Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))


def config_file() -> Path:
    return _config_dir() / APP_ID / "config.json"


def autostart_file() -> Path:
    return _config_dir() / "autostart" / f"{APP_ID}.desktop"


def load() -> dict:
    data = dict(DEFAULTS)
    try:
        loaded = json.loads(config_file().read_text(encoding="utf-8"))
        if isinstance(loaded, dict):
            data.update({k: loaded[k] for k in DEFAULTS if k in loaded})
    except (FileNotFoundError, json.JSONDecodeError):
        pass
    if data["theme"] not in ("system", "light", "dark"):
        data["theme"] = DEFAULTS["theme"]
    return data


def save(data: dict) -> None:
    path = config_file()
    path.parent.mkdir(parents=True, exist_ok=True)
    clean = {k: data.get(k, v) for k, v in DEFAULTS.items()}
    tmp = path.with_suffix(".tmp")
    tmp.write_text(json.dumps(clean, indent=2, ensure_ascii=False), encoding="utf-8")
    tmp.replace(path)


def set_autostart(enabled: bool, exec_path: str) -> None:
    target = autostart_file()
    if not enabled:
        target.unlink(missing_ok=True)
        return
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(
        "[Desktop Entry]\nType=Application\n"
        f"Name={APP_NAME}\nExec={exec_path} --background\n"
        "Icon=samsung-ecosystem-hub\nX-KDE-autostart-after=panel\nTerminal=false\n",
        encoding="utf-8",
    )


def is_autostart() -> bool:
    return autostart_file().exists()
