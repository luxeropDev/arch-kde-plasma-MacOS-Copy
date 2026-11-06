"""Точка входа: QGuiApplication + QML."""

from __future__ import annotations

import argparse
import logging
import signal
import sys
from pathlib import Path

from PySide6.QtCore import QCoreApplication, QTimer, QUrl
from PySide6.QtGui import QGuiApplication, QIcon
from PySide6.QtWidgets import QApplication      # нужен трею (QMenu) на KDE
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtQuickControls2 import QQuickStyle

from .. import APP_ID, APP_NAME, __version__
from ..services.logger import setup_logging
from .backend import Backend

ROOT = Path(__file__).resolve().parent.parent
UI_DIR = ROOT / "ui"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog=APP_ID, description=APP_NAME)
    parser.add_argument("--background", action="store_true", help="запуск в трее без окна")
    parser.add_argument("--page", type=int, default=0, choices=range(7), help="открыть вкладку 0–6 (Overview…Settings)")
    parser.add_argument("--verbose", action="store_true", help="подробный журнал")
    parser.add_argument("--version", action="version", version=f"{APP_NAME} {__version__}")
    args, qt_args = parser.parse_known_args(argv if argv is not None else sys.argv[1:])

    log = setup_logging(args.verbose)
    log.info("запуск %s %s", APP_NAME, __version__)

    QCoreApplication.setOrganizationName("SamsungEcosystemHub")
    QGuiApplication.setApplicationName(APP_ID)
    QGuiApplication.setDesktopFileName(APP_ID)
    QQuickStyle.setStyle("Basic")                  # свой дизайн, без наследования стиля KDE

    app = QApplication([sys.argv[0], *qt_args])
    app.setApplicationDisplayName(APP_NAME)
    app.setWindowIcon(QIcon(str(ROOT / "assets" / "app-icon.svg")))

    backend = Backend(background=args.background)
    engine = QQmlApplicationEngine()
    engine.addImportPath(str(UI_DIR))
    ctx = engine.rootContext()
    ctx.setContextProperty("hub", backend)
    ctx.setContextProperty("assetsUrl", QUrl.fromLocalFile(str(ROOT / "assets")).toString() + "/")
    ctx.setContextProperty("startHidden", args.background)
    ctx.setContextProperty("startPage", args.page)

    engine.load(QUrl.fromLocalFile(str(UI_DIR / "Main.qml")))
    if not engine.rootObjects():
        log.error("не удалось загрузить QML")
        return 1

    app.aboutToQuit.connect(backend.shutdown)
    signal.signal(signal.SIGINT, lambda *_: app.quit())      # Ctrl+C в терминале закрывает приложение
    wake = QTimer()
    wake.start(300)                       # даёт Python обработать сигналы внутри цикла Qt
    wake.timeout.connect(lambda: None)
    signal.signal(signal.SIGTERM, lambda *_: app.quit())

    backend.refresh()
    backend.refreshDiagnostics()
    code = app.exec()
    log.info("завершение, код %s", code)
    logging.shutdown()
    return code


if __name__ == "__main__":
    sys.exit(main())
