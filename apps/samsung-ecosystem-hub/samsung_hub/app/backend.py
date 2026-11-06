"""Мост между QML и интеграциями. Все тяжёлые операции идут в пуле потоков — интерфейс не зависает."""

from __future__ import annotations

import logging
import os
import sys
from pathlib import Path
from typing import Callable

from PySide6.QtCore import (Property, QObject, QRunnable, QThreadPool, QTimer, QUrl, Signal, Slot)

from .. import APP_NAME, __version__
from ..integrations import adb, bluez, buds, kdeconnect, system
from ..services import config
from ..services.collector import Snapshot, collect
from ..services.logger import log_path, read_log_tail

log = logging.getLogger("samsung_hub.backend")


class _Bridge(QObject):
    """Передаёт результат из рабочего потока обратно в поток Qt."""

    finished = Signal(object, object)       # (callback, result)

    def __init__(self) -> None:
        super().__init__()
        self.finished.connect(self._deliver)

    @Slot(object, object)
    def _deliver(self, callback: Callable | None, result: object) -> None:
        if callback is not None:
            callback(result)


class _Job(QRunnable):
    def __init__(self, fn: Callable, callback: Callable | None, bridge: _Bridge) -> None:
        super().__init__()
        self._fn, self._callback, self._bridge = fn, callback, bridge

    def run(self) -> None:
        try:
            result = self._fn()
        except Exception as exc:  # noqa: BLE001 — в UI показываем ошибку, а не падаем
            log.exception("ошибка в фоновой задаче")
            result = exc
        self._bridge.finished.emit(self._callback, result)


class Backend(QObject):
    stateChanged = Signal()
    busyChanged = Signal()
    settingsChanged = Signal()
    transferChanged = Signal()
    notificationsChanged = Signal()
    diagnosticsChanged = Signal()
    logChanged = Signal()
    toast = Signal(str, str)                # (kind: ok|error|info, text)

    def __init__(self, background: bool = False) -> None:
        super().__init__()
        self._pool = QThreadPool(self)
        self._pool.setMaxThreadCount(4)
        self._bridge = _Bridge()
        self._cfg = config.load()
        self._cfg["autostart"] = config.is_autostart()
        self._state: dict = {}
        self._busy = 0
        self._refreshing = False
        self._transfer = {"status": "idle", "message": "", "files": 0}
        self._notifications = ""
        self._diagnostics: dict = {"tools": [], "firewall": "", "session": {}}
        self._log_text = ""
        self.keep_in_tray = background

        self._timer = QTimer(self)
        self._timer.timeout.connect(self.refresh)
        self._apply_interval()

    # ------------------------------------------------------------------ helpers
    def _run(self, fn: Callable, callback: Callable | None = None, busy: bool = True) -> None:
        if busy:
            self._busy += 1
            self.busyChanged.emit()

        def done(result: object) -> None:
            if busy:
                self._busy -= 1
                self.busyChanged.emit()
            if callback is not None:
                callback(result)

        self._pool.start(_Job(fn, done, self._bridge))

    def _apply_interval(self) -> None:
        self._timer.start(max(3, int(self._cfg["refresh_seconds"])) * 1000)

    def _report(self, label: str, res) -> None:
        """Единый показ результата команды: тост + запись в журнал."""
        if res.ok:
            log.info("%s: успешно", label)
            self.toast.emit("ok", f"{label}: готово")
        else:
            reason = "команда не найдена" if res.missing else (res.text or f"код {res.code}")
            log.warning("%s: %s", label, reason)
            self.toast.emit("error", f"{label}: {reason}")

    def _device_id(self) -> str:
        return (self._state.get("phone", {}).get("details", {}) or {}).get("kdeconnectId", "")

    # ------------------------------------------------------------------ свойства
    @Property("QVariantMap", notify=stateChanged)
    def state(self) -> dict:                        # type: ignore[override]
        return self._state

    @Property(bool, notify=busyChanged)
    def busy(self) -> bool:
        return self._busy > 0

    @Property(str, notify=settingsChanged)
    def theme(self) -> str:
        return self._cfg["theme"]

    @Property(bool, notify=settingsChanged)
    def autostart(self) -> bool:
        return bool(self._cfg["autostart"])

    @Property(int, notify=settingsChanged)
    def refreshSeconds(self) -> int:
        return int(self._cfg["refresh_seconds"])

    @Property("QVariantMap", notify=transferChanged)
    def transfer(self) -> dict:
        return self._transfer

    @Property(str, notify=notificationsChanged)
    def notificationsText(self) -> str:
        return self._notifications

    @Property("QVariantMap", notify=diagnosticsChanged)
    def diagnostics(self) -> dict:
        return self._diagnostics

    @Property(str, notify=logChanged)
    def logText(self) -> str:
        return self._log_text

    @Property(str, constant=True)
    def version(self) -> str:
        return __version__

    @Property(str, constant=True)
    def appName(self) -> str:
        return APP_NAME

    @Property(str, constant=True)
    def logPath(self) -> str:
        return str(log_path())

    @Property(bool, constant=True)
    def keepInTray(self) -> bool:
        return self.keep_in_tray

    # ------------------------------------------------------------------ опрос
    @Slot()
    def refresh(self) -> None:
        if self._refreshing:
            return
        self._refreshing = True

        def done(result: object) -> None:
            self._refreshing = False
            if isinstance(result, Snapshot):
                self._state = result.to_qml()
                self.stateChanged.emit()
            else:
                self.toast.emit("error", f"Не удалось обновить состояние: {result}")

        self._run(collect, done, busy=False)

    # ------------------------------------------------------------------ Bluetooth / Buds
    @Slot()
    def toggleBluetooth(self) -> None:
        want = not self._state.get("btPowered", False)
        self._run(lambda: bluez.set_power(want),
                  lambda r: (self._report("Bluetooth " + ("включён" if want else "выключен"), r), self.refresh()))

    @Slot()
    def connectBuds(self) -> None:
        address = (self._state.get("buds", {}).get("details", {}) or {}).get("address", "")
        if not address:
            self.toast.emit("error", "Наушники не сопряжены с этим компьютером")
            return
        self._run(lambda: bluez.connect(address),
                  lambda r: (self._report("Подключение наушников", r), self.refresh()))

    @Slot()
    def disconnectBuds(self) -> None:
        address = (self._state.get("buds", {}).get("details", {}) or {}).get("address", "")
        if not address:
            return
        self._run(lambda: bluez.disconnect(address),
                  lambda r: (self._report("Отключение наушников", r), self.refresh()))

    @Slot()
    def launchBudsClient(self) -> None:
        def done(result) -> None:
            ok, msg = result if isinstance(result, tuple) else (False, str(result))
            self.toast.emit("ok" if ok else "error", "GalaxyBudsClient запущен" if ok else msg)
            log.info("GalaxyBudsClient: %s", "запущен" if ok else msg)

        self._run(buds.launch, done)

    # ------------------------------------------------------------------ Phone / KDE Connect
    def _kc_action(self, label: str, fn: Callable[[str], object]) -> None:
        device_id = self._device_id()
        if not device_id:
            self.toast.emit("error", "Телефон не найден через KDE Connect")
            return
        self._run(lambda: fn(device_id), lambda r: (self._report(label, r), self.refresh()))

    @Slot()
    def pairPhone(self) -> None:
        self._kc_action("Запрос на сопряжение отправлен — подтвердите его на телефоне", kdeconnect.pair)

    @Slot()
    def unpairPhone(self) -> None:
        self._kc_action("Сопряжение отменено", kdeconnect.unpair)

    @Slot()
    def pingPhone(self) -> None:
        self._kc_action("Пинг отправлен", kdeconnect.ping)

    @Slot()
    def ringPhone(self) -> None:
        self._kc_action("Телефон звонит", kdeconnect.ring)

    @Slot()
    def sendClipboard(self) -> None:
        self._kc_action("Буфер обмена отправлен", kdeconnect.send_clipboard)

    @Slot()
    def loadNotifications(self) -> None:
        device_id = self._device_id()
        if not device_id:
            self._notifications = "Телефон не подключён."
            self.notificationsChanged.emit()
            return

        def done(res) -> None:
            if res.ok:
                self._notifications = res.text or "Активных уведомлений нет."
            elif res.missing:
                self._notifications = "KDE Connect не установлен."
            else:
                self._notifications = ("Не удалось получить уведомления: " + (res.text or "нет ответа") +
                                       "\nВключите плагин «Уведомления» и выдайте доступ в приложении KDE Connect на телефоне.")
            self.notificationsChanged.emit()

        self._run(lambda: kdeconnect.list_notifications(device_id), done)

    # ------------------------------------------------------------------ передача файлов
    @Slot("QVariantList")
    def shareFiles(self, urls: list) -> None:
        device_id = self._device_id()
        files: list[str] = []
        for raw in urls:
            local = QUrl(str(raw)).toLocalFile() or str(raw)
            if os.path.isfile(local):
                files.append(local)
        if not files:
            self._set_transfer("error", "Выберите существующие файлы")
            return
        if not device_id or not self._state.get("phone", {}).get("connected"):
            self._set_transfer("error", "Телефон не подключён через KDE Connect")
            return

        self._set_transfer("sending", f"Передача: {len(files)} файл(ов)…", len(files))

        def work():
            failures = []
            for path in files:
                res = kdeconnect.share_file(device_id, path)
                if not res.ok:
                    failures.append((Path(path).name, res.text))
            return failures

        def done(result) -> None:
            if isinstance(result, Exception):
                self._set_transfer("error", str(result))
            elif result:
                name, why = result[0]
                self._set_transfer("error", f"Не отправлено: {name} — {why or 'ошибка KDE Connect'}")
                log.warning("передача файлов: ошибок %d", len(result))
            else:
                self._set_transfer("done", "Передано в KDE Connect. Ход загрузки показывает уведомление KDE Connect.", len(files))
                log.info("передача файлов: отправлено %d", len(files))

        self._run(work, done)

    def _set_transfer(self, status: str, message: str, files: int = 0) -> None:
        self._transfer = {"status": status, "message": message, "files": files}
        self.transferChanged.emit()

    @Slot()
    def resetTransfer(self) -> None:
        self._set_transfer("idle", "")

    # ------------------------------------------------------------------ зеркалирование
    @Slot()
    def launchScrcpy(self) -> None:
        if not adb.scrcpy_available():
            self.toast.emit("error", "scrcpy не установлен: sudo pacman -S scrcpy android-tools")
            return
        authorized = [d for d in self._state.get("adbDevices", []) if d.get("authorized")]
        if not authorized:
            self.toast.emit("error", "Нет авторизованного ADB-устройства")
            return
        serial = authorized[0]["serial"]

        def done(result) -> None:
            ok, msg = result
            self.toast.emit("ok" if ok else "error", "scrcpy запущен" if ok else msg)
            log.info("scrcpy: %s", "запущен" if ok else msg)

        self._run(lambda: adb.launch_scrcpy(serial), done)

    # ------------------------------------------------------------------ настройки
    @Slot(str)
    def setTheme(self, value: str) -> None:
        if value in ("system", "light", "dark"):
            self._cfg["theme"] = value
            config.save(self._cfg)
            self.settingsChanged.emit()

    @Slot(bool)
    def setAutostart(self, enabled: bool) -> None:
        exe = str(Path(sys.argv[0]).resolve()) if sys.argv and sys.argv[0] else "samsung-ecosystem-hub"
        launcher = Path.home() / ".local" / "bin" / "samsung-ecosystem-hub"
        config.set_autostart(enabled, str(launcher if launcher.exists() else exe))
        self._cfg["autostart"] = enabled
        config.save(self._cfg)
        self.settingsChanged.emit()
        log.info("автозапуск %s", "включён" if enabled else "выключен")

    @Slot(int)
    def setRefreshSeconds(self, seconds: int) -> None:
        self._cfg["refresh_seconds"] = max(3, min(120, int(seconds)))
        config.save(self._cfg)
        self._apply_interval()
        self.settingsChanged.emit()

    # ------------------------------------------------------------------ диагностика и журнал
    @Slot()
    def refreshDiagnostics(self) -> None:
        def work():
            return {
                "tools": system.tool_report(),
                "firewall": system.firewall_hint(),
                "session": system.session_info(),
                "missing": system.missing_packages(),
                "budsClient": buds.flatpak_installed(),
            }

        def done(result) -> None:
            if isinstance(result, dict):
                self._diagnostics = result
                self.diagnosticsChanged.emit()

        self._run(work, done, busy=False)

    @Slot()
    def refreshLog(self) -> None:
        self._log_text = read_log_tail() or "Журнал пока пуст."
        self.logChanged.emit()

    @Slot(str)
    def openUrl(self, url: str) -> None:
        from PySide6.QtGui import QDesktopServices
        QDesktopServices.openUrl(QUrl(url))

    @Slot()
    def openLogFolder(self) -> None:
        from PySide6.QtGui import QDesktopServices
        QDesktopServices.openUrl(QUrl.fromLocalFile(str(log_path().parent)))

    @Slot()
    def shutdown(self) -> None:
        self._timer.stop()
        self._pool.waitForDone(3000)
