"""Безопасный запуск внешних команд: только список аргументов, без shell, с таймаутом."""

from __future__ import annotations

import logging
import shutil
import subprocess
from dataclasses import dataclass

log = logging.getLogger("samsung_hub.runner")


@dataclass
class CmdResult:
    ok: bool
    code: int
    out: str = ""
    err: str = ""
    missing: bool = False           # команда не найдена в PATH
    timed_out: bool = False

    @property
    def text(self) -> str:
        return (self.out or self.err).strip()


def have(command: str) -> bool:
    return shutil.which(command) is not None


def run(args: list[str], timeout: float = 8.0, input_text: str | None = None) -> CmdResult:
    """Запускает команду и ждёт результат. Вызывать только из рабочего потока."""
    if not args or not have(args[0]):
        return CmdResult(False, 127, err=f"{args[0] if args else '?'}: команда не найдена", missing=True)
    try:
        proc = subprocess.run(
            args, capture_output=True, text=True, timeout=timeout,
            input=input_text, shell=False, check=False,
        )
    except subprocess.TimeoutExpired:
        log.warning("таймаут %.0f с: %s", timeout, args[:3])
        return CmdResult(False, 124, err="превышено время ожидания", timed_out=True)
    except OSError as exc:
        log.warning("не удалось запустить %s: %s", args[0], exc)
        return CmdResult(False, 126, err=str(exc))
    return CmdResult(proc.returncode == 0, proc.returncode, proc.stdout, proc.stderr)


def spawn_detached(args: list[str]) -> tuple[bool, str]:
    """Запускает программу отдельным процессом (scrcpy, GalaxyBudsClient) и не ждёт её завершения."""
    if not args or not have(args[0]):
        return False, f"{args[0] if args else '?'}: команда не найдена"
    try:
        subprocess.Popen(
            args, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
            start_new_session=True, shell=False,
        )
    except OSError as exc:
        log.warning("не удалось запустить %s: %s", args[0], exc)
        return False, str(exc)
    return True, ""
