"""Модели данных. Только то, что реально удалось узнать — остальное остаётся None."""

from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum
from typing import Any


class LinkState(str, Enum):
    """Реальное состояние связи с устройством."""

    CONNECTED = "connected"          # есть живое соединение
    AVAILABLE = "available"          # устройство видно, но не соединено / не сопряжено
    UNAVAILABLE = "unavailable"      # устройство не найдено или инструмент не установлен
    VIA_PHONE = "via_phone"          # доступно только через телефон (часы)


@dataclass
class DeviceStatus:
    kind: str                                   # "phone" | "buds" | "watch"
    title: str
    state: LinkState = LinkState.UNAVAILABLE
    name: str | None = None                     # имя устройства, если известно
    battery: int | None = None                  # 0..100, только если реально получено
    charging: bool | None = None
    source: str = ""                            # откуда получены данные
    message: str = ""                           # человекочитаемое пояснение
    details: dict[str, Any] = field(default_factory=dict)

    def to_qml(self) -> dict[str, Any]:
        """Плоский словарь для QML (None → -1 / пустая строка, чтобы не путать типы)."""
        return {
            "kind": self.kind,
            "title": self.title,
            "state": self.state.value,
            "connected": self.state == LinkState.CONNECTED,
            "name": self.name or "",
            "battery": -1 if self.battery is None else int(self.battery),
            "hasBattery": self.battery is not None,
            "charging": bool(self.charging),
            "source": self.source,
            "message": self.message,
            "details": self.details,
        }


@dataclass
class BtDevice:
    path: str
    address: str
    name: str
    paired: bool = False
    connected: bool = False
    trusted: bool = False
    battery: int | None = None
    icon: str = ""


@dataclass
class KcDevice:
    device_id: str
    name: str
    paired: bool
    reachable: bool
    battery: int | None = None
    charging: bool | None = None


@dataclass
class AdbDevice:
    serial: str
    state: str                  # device | unauthorized | offline | ...
    model: str = ""
    battery: int | None = None

    @property
    def authorized(self) -> bool:
        return self.state == "device"
