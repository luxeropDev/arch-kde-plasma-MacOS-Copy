"""Сбор реального состояния экосистемы из BlueZ, KDE Connect и ADB (без симуляции)."""

from __future__ import annotations

import logging
from dataclasses import dataclass, field
from datetime import datetime

from ..integrations import adb, bluez, kdeconnect
from ..models.device import AdbDevice, BtDevice, DeviceStatus, KcDevice, LinkState

log = logging.getLogger("samsung_hub.collector")


@dataclass
class Snapshot:
    phone: DeviceStatus
    buds: DeviceStatus
    watch: DeviceStatus
    bt_powered: bool | None = None
    bt_error: str = ""
    kc_available: bool = False
    kc_devices: list[KcDevice] = field(default_factory=list)
    adb_available: bool = False
    scrcpy_available: bool = False
    adb_devices: list[AdbDevice] = field(default_factory=list)
    updated_at: datetime = field(default_factory=datetime.now)

    @property
    def connected_count(self) -> int:
        return sum(1 for d in (self.phone, self.buds, self.watch) if d.state == LinkState.CONNECTED)

    def summary(self) -> str:
        n = self.connected_count
        if n == 0:
            return "Нет активных подключений"
        return f"Подключено устройств: {n} из 3"

    def to_qml(self) -> dict:
        return {
            "phone": self.phone.to_qml(),
            "buds": self.buds.to_qml(),
            "watch": self.watch.to_qml(),
            "btPowered": bool(self.bt_powered),
            "btKnown": self.bt_powered is not None,
            "btError": self.bt_error,
            "kdeconnectAvailable": self.kc_available,
            "kdeconnectDevices": [
                {"id": d.device_id, "name": d.name, "paired": d.paired, "reachable": d.reachable}
                for d in self.kc_devices
            ],
            "adbAvailable": self.adb_available,
            "scrcpyAvailable": self.scrcpy_available,
            "adbDevices": [
                {"serial": d.serial, "state": d.state, "model": d.model, "authorized": d.authorized}
                for d in self.adb_devices
            ],
            "summary": self.summary(),
            "connectedCount": self.connected_count,
            "updatedAt": self.updated_at.strftime("%H:%M:%S"),
        }


def _pick_kc(devices: list[KcDevice]) -> KcDevice | None:
    """Предпочитаем сопряжённое и доступное, затем доступное, затем сопряжённое."""
    for predicate in (lambda d: d.paired and d.reachable, lambda d: d.reachable, lambda d: d.paired):
        for dev in devices:
            if predicate(dev):
                return dev
    return None


def build_phone(kc_ok: bool, kc: list[KcDevice], adb_ok: bool, adb_devs: list[AdbDevice]) -> DeviceStatus:
    status = DeviceStatus(kind="phone", title="Galaxy Phone")
    adb_dev = next((d for d in adb_devs if d.authorized), None)
    dev = _pick_kc(kc)

    if dev is not None:
        status.name = dev.name
        status.source = "KDE Connect"
        status.details["kdeconnectId"] = dev.device_id
        if dev.paired and dev.reachable:
            status.state = LinkState.CONNECTED
            status.battery, status.charging = dev.battery, dev.charging
            status.message = "Подключён через KDE Connect"
        elif dev.reachable:
            status.state = LinkState.AVAILABLE
            status.message = "Телефон найден, но не сопряжён. Нажмите «Сопрячь»."
        else:
            status.state = LinkState.AVAILABLE
            status.message = "Сопряжён, но сейчас недоступен (выключен или в другой сети)."
    elif not kc_ok:
        status.message = "KDE Connect не установлен: sudo pacman -S kdeconnect"
    else:
        status.message = "Телефон не найден. Откройте KDE Connect на телефоне в той же Wi‑Fi сети."

    if adb_dev is not None:
        status.details["adbSerial"] = adb_dev.serial
        if status.battery is None and adb_dev.battery is not None:
            status.battery = adb_dev.battery
            status.source = (status.source + " + ADB").strip(" +")
        if status.state != LinkState.CONNECTED:
            status.state = LinkState.CONNECTED
            status.name = status.name or adb_dev.model or adb_dev.serial
            status.source = "ADB"
            status.message = "Подключён по ADB (USB-отладка)"
    return status


def build_buds(powered: bool | None, devices: list[BtDevice], err: str = "") -> DeviceStatus:
    status = DeviceStatus(kind="buds", title="Galaxy Buds", source="BlueZ (Bluetooth)")
    candidates = [d for d in devices if bluez.classify(d.name) == "buds"]
    dev = next((d for d in candidates if d.connected), None) or next(iter(candidates), None)

    if err:
        status.message = "Bluetooth недоступен: " + err
    elif dev is None:
        status.message = ("Bluetooth выключен." if powered is False
                          else "Наушники не сопряжены с этим компьютером.")
    else:
        status.name = dev.name
        status.details["address"] = dev.address
        status.details["paired"] = dev.paired
        status.battery = dev.battery
        if dev.connected:
            status.state = LinkState.CONNECTED
            status.message = ("Подключены" if dev.battery is not None
                              else "Подключены. Заряд по Bluetooth не передаётся — смотрите в GalaxyBudsClient.")
        else:
            status.state = LinkState.AVAILABLE
            status.message = ("Сопряжены, но не подключены." if powered
                              else "Bluetooth выключен.")
    return status


def build_watch(phone: DeviceStatus, powered: bool | None, devices: list[BtDevice]) -> DeviceStatus:
    status = DeviceStatus(kind="watch", title="Galaxy Watch")
    direct = next((d for d in devices if bluez.classify(d.name) == "watch"), None)
    if direct is not None:
        status.name = direct.name
        status.source = "BlueZ (Bluetooth)"
        status.details["address"] = direct.address
        status.battery = direct.battery
        status.state = LinkState.CONNECTED if direct.connected else LinkState.AVAILABLE
        status.message = ("Часы видны этому компьютеру по Bluetooth. Данные здоровья и уведомления "
                          "через Linux недоступны.")
        return status

    status.state = LinkState.VIA_PHONE
    status.source = "через телефон (Galaxy Wearable)"
    status.message = ("Galaxy Watch сопрягаются с телефоном, а не с Linux. Заряд, пульс и Samsung Health "
                      "на ПК недоступны — у Samsung нет для них Linux-интерфейса.")
    if phone.state == LinkState.CONNECTED:
        status.details["phoneOnline"] = True
    return status


def collect() -> Snapshot:
    """Один полный опрос. Блокирующий — вызывать из рабочего потока."""
    powered, bt_devices, bt_res = bluez.snapshot()
    bt_err = "" if bt_res.ok else (bt_res.text or "нет ответа от bluetoothd")

    kc_ok = kdeconnect.available()
    kc_devices: list[KcDevice] = []
    if kc_ok:
        kc_devices, kc_res = kdeconnect.list_devices()
        if not kc_res.ok:
            log.info("kdeconnect-cli -l: %s", kc_res.text)

    adb_ok = adb.adb_available()
    adb_devices: list[AdbDevice] = []
    if adb_ok:
        adb_devices, adb_res = adb.list_devices()
        if not adb_res.ok:
            log.info("adb devices: %s", adb_res.text)

    phone = build_phone(kc_ok, kc_devices, adb_ok, adb_devices)
    buds = build_buds(powered, bt_devices, bt_err)
    watch = build_watch(phone, powered, bt_devices)
    return Snapshot(
        phone=phone, buds=buds, watch=watch,
        bt_powered=powered, bt_error=bt_err,
        kc_available=kc_ok, kc_devices=kc_devices,
        adb_available=adb_ok, scrcpy_available=adb.scrcpy_available(), adb_devices=adb_devices,
    )
