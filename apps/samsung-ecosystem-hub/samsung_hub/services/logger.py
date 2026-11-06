"""Логирование в файл с маскированием личных данных (MAC-адреса, id устройств KDE Connect)."""

from __future__ import annotations

import logging
import re
from logging.handlers import RotatingFileHandler
from pathlib import Path

from .. import APP_ID

_MAC = re.compile(r"\b([0-9A-Fa-f]{2}(?::[0-9A-Fa-f]{2}){4}):([0-9A-Fa-f]{2})\b")
_KC_ID = re.compile(r"\b([0-9a-f]{6})[0-9a-f_]{10,}\b")
_HOME = re.compile(re.escape(str(Path.home())))


def redact(text: str) -> str:
    """Скрывает MAC (оставляя последний октет), длинные id и домашнюю папку."""
    text = _MAC.sub(lambda m: "XX:XX:XX:XX:XX:" + m.group(2), text)
    text = _KC_ID.sub(lambda m: m.group(1) + "…", text)
    return _HOME.sub("~", text)


class _RedactFilter(logging.Filter):
    def filter(self, record: logging.LogRecord) -> bool:
        record.msg = redact(record.getMessage())
        record.args = ()
        return True


def log_path() -> Path:
    base = Path.home() / ".local" / "state" / APP_ID
    base.mkdir(parents=True, exist_ok=True)
    return base / "hub.log"


def setup_logging(verbose: bool = False) -> logging.Logger:
    logger = logging.getLogger("samsung_hub")
    if logger.handlers:
        return logger
    logger.setLevel(logging.DEBUG if verbose else logging.INFO)
    handler = RotatingFileHandler(log_path(), maxBytes=512_000, backupCount=2, encoding="utf-8")
    handler.setFormatter(logging.Formatter("%(asctime)s %(levelname)s %(name)s: %(message)s"))
    handler.addFilter(_RedactFilter())
    logger.addHandler(handler)
    return logger


def read_log_tail(max_lines: int = 200) -> str:
    try:
        lines = log_path().read_text(encoding="utf-8", errors="replace").splitlines()
    except FileNotFoundError:
        return ""
    return "\n".join(lines[-max_lines:])
