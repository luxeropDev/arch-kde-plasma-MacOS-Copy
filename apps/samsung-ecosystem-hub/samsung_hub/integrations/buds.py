"""GalaxyBudsClient (Flatpak). Функции наушников выполняет сам клиент — мы только запускаем его."""

from __future__ import annotations

from .. import BUDS_FLATPAK_ID
from ..services.runner import have, run, spawn_detached


def flatpak_installed() -> bool:
    if not have("flatpak"):
        return False
    return run(["flatpak", "info", BUDS_FLATPAK_ID], timeout=6).ok


def launch() -> tuple[bool, str]:
    if not flatpak_installed():
        return False, (f"GalaxyBudsClient не установлен. Выполни: "
                       f"flatpak install flathub {BUDS_FLATPAK_ID}")
    return spawn_detached(["flatpak", "run", BUDS_FLATPAK_ID])
