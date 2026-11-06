"""Мост QML ↔ сервисы. Чтение и действия выполняются в фоне, интерфейс не замирает."""

from __future__ import annotations

import logging
from typing import Callable

from PySide6.QtCore import Property, QObject, QRunnable, QThreadPool, Signal, Slot

from . import APP_NAME, __version__
from .runner import CmdResult
from .services import desktop, hardware, network, system

log = logging.getLogger("macsettings.backend")


class _Bridge(QObject):
    finished = Signal(object, object)

    def __init__(self) -> None:
        super().__init__()
        self.finished.connect(lambda cb, res: cb(res))


class _Job(QRunnable):
    def __init__(self, fn: Callable, cb: Callable, bridge: _Bridge) -> None:
        super().__init__()
        self.fn, self.cb, self.bridge = fn, cb, bridge

    def run(self) -> None:
        try:
            res = self.fn()
        except Exception as exc:  # noqa: BLE001
            log.exception("ошибка фоновой задачи")
            res = exc
        self.bridge.finished.emit(self.cb, res)


def _pointer_state() -> dict:
    devs = hardware.pointer_devices()
    return {"touchpads": [d for d in devs if d["touchpad"]], "mice": [d for d in devs if not d["touchpad"]]}


LOADERS: dict[str, Callable[[], object]] = {
    "user": system.user_info,
    "wifi": network.wifi_state,
    "bluetooth": network.bluetooth_state,
    "network": lambda: {"connections": network.active_connections()},
    "battery": system.battery,
    "about": system.about,
    "appearance": desktop.appearance_state,
    "dock": desktop.dock_state,
    "displays": hardware.display_state,
    "sound": hardware.audio_state,
    "lock": desktop.lock_state,
    "keyboard": hardware.keyboard_state,
    "pointer": _pointer_state,
    "wallpaper": lambda: {"items": desktop.wallpapers(), "current": desktop.current_wallpaper()},
}


class Backend(QObject):
    dataChanged = Signal()
    toast = Signal(str, str)

    def __init__(self) -> None:
        super().__init__()
        self._pool = QThreadPool(self)
        self._pool.setMaxThreadCount(4)
        self._bridge = _Bridge()
        self._data: dict = {}
        self._loading: set[str] = set()
        self._devices: dict[str, dict] = {}
        self._actions: dict[str, tuple[Callable[[object], object], tuple[str, ...]]] = {
            "wifi.power": (lambda v: network.set_wifi(bool(v)), ("wifi", "network")),
            "wifi.connect": (lambda v: network.connect_known(str(v)), ("wifi", "network")),
            "bt.power": (lambda v: network.set_bluetooth(bool(v)), ("bluetooth",)),
            "bt.connect": (lambda v: network.bt_connect(str(v), True), ("bluetooth",)),
            "bt.disconnect": (lambda v: network.bt_connect(str(v), False), ("bluetooth",)),
            "battery.profile": (lambda v: system.set_power_profile(str(v)), ("battery",)),
            "appearance.mode": (lambda v: desktop.set_appearance(str(v)), ("appearance",)),
            "appearance.accent": (lambda v: desktop.set_accent(str(v)), ("appearance",)),
            "appearance.glass": (lambda v: desktop.set_glass(int(v)), ("appearance",)),
            "dock.size": (lambda v: desktop.set_dock("size", v), ("dock",)),
            "dock.magnification": (lambda v: desktop.set_dock("magnification", v), ("dock",)),
            "dock.position": (lambda v: desktop.set_dock("position", v), ("dock",)),
            "dock.visibility": (lambda v: desktop.set_dock("visibility", v), ("dock",)),
            "dock.minimize": (lambda v: desktop.set_dock("minimize", v), ("dock",)),
            "display.brightness": (lambda v: hardware.set_brightness(float(v)), ()),
            "display.night": (lambda v: hardware.set_night_shift(bool(v)), ("displays",)),
            "sound.volume": (lambda v: hardware.set_volume(float(v)), ()),
            "sound.inputVolume": (lambda v: hardware.set_volume(float(v), source=True), ()),
            "sound.mute": (lambda v: hardware.set_mute(bool(v)), ("sound",)),
            "sound.default": (lambda v: hardware.set_default_device(int(v)), ("sound",)),
            "lock.autolock": (lambda v: desktop.set_lock("autolock", bool(v)), ("lock",)),
            "lock.timeout": (lambda v: desktop.set_lock("timeout", int(v)), ("lock",)),
            "lock.lockOnResume": (lambda v: desktop.set_lock("lockOnResume", bool(v)), ("lock",)),
            "lock.grace": (lambda v: desktop.set_lock("grace", int(v)), ("lock",)),
            "keyboard.repeat": (lambda v: hardware.set_keyboard_repeat(int(v["delay"]), int(v["rate"])), ("keyboard",)),
            "wallpaper.set": (lambda v: desktop.set_wallpaper(str(v)), ("wallpaper",)),
        }

    # ------------------------------------------------------------ данные
    @Property("QVariantMap", notify=dataChanged)
    def data(self) -> dict:                         # type: ignore[override]
        return self._data

    @Property(str, constant=True)
    def version(self) -> str:
        return __version__

    @Property(str, constant=True)
    def appName(self) -> str:
        return APP_NAME

    def _start(self, fn: Callable, cb: Callable) -> None:
        self._pool.start(_Job(fn, cb, self._bridge))

    @Slot(str)
    def load(self, pane: str) -> None:
        loader = LOADERS.get(pane)
        if loader is None or pane in self._loading:
            return
        self._loading.add(pane)

        def done(res: object) -> None:
            self._loading.discard(pane)
            if isinstance(res, Exception):
                self.toast.emit("error", f"Не удалось прочитать «{pane}»: {res}")
                return
            if pane == "pointer":
                self._devices = {d["sys"]: d for d in res["touchpads"] + res["mice"]}
            self._data = {**self._data, pane: res}
            self.dataChanged.emit()

        self._start(loader, done)

    # ------------------------------------------------------------ действия
    @Slot(str, "QVariant")
    def call(self, action: str, value: object = None) -> None:
        entry = self._actions.get(action)
        if entry is None:
            log.warning("неизвестное действие %s", action)
            return
        fn, reload = entry

        def done(res: object) -> None:
            ok = (res.ok if isinstance(res, CmdResult) else bool(res)) and not isinstance(res, Exception)
            if not ok:
                reason = res.text if isinstance(res, CmdResult) else str(res) if isinstance(res, Exception) else ""
                self.toast.emit("error", "Не удалось применить" + (f": {reason}" if reason else ""))
                log.warning("%s: ошибка %s", action, reason)
            for pane in reload:
                self.load(pane)

        self._start(lambda: fn(value), done)

    @Slot(str, str, "QVariant")
    def setPointer(self, sys_name: str, prop: str, value: object) -> None:
        dev = self._devices.get(sys_name)
        if dev is None:
            return
        self._start(lambda: hardware.set_pointer_option(dev, prop, value),
                    lambda ok: (None if ok is True else self.toast.emit("error", "Не удалось изменить устройство"),
                                self.load("pointer")))

    @Slot(str)
    def openKcm(self, name: str) -> None:
        ok, msg = desktop.open_kcm(name)
        if not ok:
            self.toast.emit("error", msg or "Модуль недоступен")

    @Slot(str)
    def openApp(self, desktop_id: str) -> None:
        ok, msg = desktop.open_app(desktop_id)
        if not ok:
            self.toast.emit("error", msg or "Не удалось открыть")

    def shutdown(self) -> None:
        self._pool.waitForDone(3000)
