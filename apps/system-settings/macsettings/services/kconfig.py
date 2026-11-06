"""Чтение и запись настроек KDE через kreadconfig6/kwriteconfig6 (с уведомлением программ)."""

from __future__ import annotations

from ..runner import run


def read(file: str, groups: list[str], key: str, default: str = "") -> str:
    args = ["kreadconfig6", "--file", file]
    for g in groups:
        args += ["--group", g]
    res = run(args + ["--key", key], timeout=4)
    value = res.out.strip() if res.ok else ""
    return value if value else default


def write(file: str, groups: list[str], key: str, value, notify: bool = True) -> bool:
    if isinstance(value, bool):
        value = "true" if value else "false"
    args = ["kwriteconfig6", "--file", file]
    if notify:
        args.append("--notify")
    for g in groups:
        args += ["--group", g]
    return run(args + ["--key", key, str(value)], timeout=4).ok


def as_bool(value: str, default: bool = False) -> bool:
    if value == "":
        return default
    return value.strip().lower() in ("true", "1", "yes")


def kwin_reconfigure() -> None:
    run(["qdbus6", "org.kde.KWin", "/KWin", "reconfigure"], timeout=4)
