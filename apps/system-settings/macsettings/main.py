"""Точка входа «Системных настроек»."""

from __future__ import annotations

import argparse
import logging
import signal
import sys
from pathlib import Path

from PySide6.QtCore import QTimer, QUrl
from PySide6.QtGui import QGuiApplication, QIcon
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtQuickControls2 import QQuickStyle

from . import APP_ID, APP_NAME, __version__
from .backend import Backend

UI = Path(__file__).resolve().parent / "ui"
PANES = ["wifi", "bluetooth", "network", "battery", "general", "appearance", "controlcenter", "dock",
         "displays", "wallpaper", "notifications", "sound", "focus", "lock", "privacy", "users",
         "keyboard", "mouse", "trackpad", "printers", "about", "spotlight", "accessibility", "screensaver"]


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog=APP_ID, description=APP_NAME)
    parser.add_argument("pane", nargs="?", default="general", choices=PANES, help="открыть раздел")
    parser.add_argument("--version", action="version", version=f"{APP_NAME} {__version__}")
    args, qt_args = parser.parse_known_args(argv if argv is not None else sys.argv[1:])

    logging.basicConfig(level=logging.WARNING, format="%(levelname)s %(name)s: %(message)s")
    QGuiApplication.setApplicationName(APP_ID)
    QGuiApplication.setDesktopFileName("systemsettings")   # значок в Dock совпадает с ярлыком
    QQuickStyle.setStyle("Basic")

    app = QGuiApplication([sys.argv[0], *qt_args])
    app.setApplicationDisplayName(APP_NAME)
    app.setWindowIcon(QIcon.fromTheme("preferences-system", QIcon.fromTheme("systemsettings")))

    backend = Backend()
    engine = QQmlApplicationEngine()
    engine.addImportPath(str(UI))
    engine.rootContext().setContextProperty("settings", backend)
    engine.rootContext().setContextProperty("startPane", args.pane)
    engine.load(QUrl.fromLocalFile(str(UI / "Main.qml")))
    if not engine.rootObjects():
        return 1

    app.aboutToQuit.connect(backend.shutdown)
    signal.signal(signal.SIGINT, lambda *_: app.quit())
    signal.signal(signal.SIGTERM, lambda *_: app.quit())
    wake = QTimer()
    wake.timeout.connect(lambda: None)
    wake.start(300)
    return app.exec()
