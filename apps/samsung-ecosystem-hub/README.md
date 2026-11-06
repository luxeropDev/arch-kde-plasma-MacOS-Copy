# Samsung Ecosystem Hub

Одно окно для **Galaxy Phone, Galaxy Buds и Galaxy Watch** в KDE Plasma 6 (Arch Linux, Wayland).
PySide6 + QML, светлая и тёмная темы, никаких декоративных кнопок: каждая кнопка вызывает
настоящую команду или D-Bus-интерфейс, а чего Linux не умеет — честно помечено.

## Запуск

```bash
~/Projects/SamsungEcosystemHub/scripts/install.sh   # один раз: ярлык в меню KDE, иконка, команда
samsung-ecosystem-hub                                # или из меню: «Samsung Ecosystem Hub»
```

Параметры: `--background` (только трей), `--page 0..6` (открыть вкладку), `--verbose` (подробный журнал).
Горячие клавиши: `F5` — обновить, `Ctrl+Tab` — следующая вкладка, `Ctrl+Q` — выход.

## Что нужно поставить

```bash
sudo pacman -S --needed kdeconnect android-tools scrcpy     # телефон и зеркалирование
flatpak install flathub me.timschneeberger.GalaxyBudsClient  # наушники (уже можно ставить без sudo: flatpak install --user)
```

На телефоне установите **KDE Connect** (Google Play / F-Droid). Телефон и ПК — в одной Wi‑Fi сети.
Если включён `ufw`, один раз откройте порты KDE Connect:

```bash
sudo ufw allow 1714:1764/tcp && sudo ufw allow 1714:1764/udp
```

## Вкладки и как это работает

| Вкладка | Источник данных | Что делает |
|---|---|---|
| Overview | всё вместе | общий статус, три карточки, быстрые действия |
| Phone | KDE Connect (`kdeconnect-cli`, D-Bus), ADB | сопряжение, пинг, «найти телефон», буфер обмена, уведомления, заряд |
| Galaxy Buds | BlueZ (D-Bus), GalaxyBudsClient | статус Bluetooth, подключение, заряд (если наушники его отдают), запуск клиента |
| Galaxy Watch | BlueZ (только если часы видны ПК) | честный статус «через телефон» |
| File Transfer | KDE Connect `--share` | выбор файлов или перетаскивание |
| Screen Mirroring | ADB + scrcpy | проверка готовности и запуск scrcpy |
| Settings | — | тема, автозапуск, диагностика, журнал, конфиденциальность |

### USB-отладка (делаете вы сами)

Приложение её **не включает**. Настройки → О телефоне → Сведения о ПО → 7 раз коснуться «Номер сборки» →
Параметры разработчика → «Отладка по USB» → подключить кабель → подтвердить запрос на телефоне.

## Ограничения (это не баги)

* **Galaxy Watch** сопрягаются только с телефоном. Заряд, пульс, сон, шаги (Samsung Health) на Linux
  недоступны, и обходить защиту Samsung приложение не пытается. Вкладка Watch показывает статус
  «Через телефон» и не выдумывает показатели.
* **Galaxy Buds**: шумоподавление/ambient/эквалайзер и заряд каждого наушника — закрытый протокол Samsung,
  с ним работает только GalaxyBudsClient. Hub его запускает и не дублирует. Общий заряд виден в Hub,
  только если наушники сообщают его через стандартный профиль Bluetooth.
* **Передача файлов**: KDE Connect отдаёт файл в фоне, процент выполнения показывает его уведомление;
  в Hub виден индикатор «Отправка…» и итог (успех/ошибка).
* **Буфер обмена**: Android разрешает чтение буфера обмена только приложению на переднем плане.
* **Последняя синхронизация** часов недостоверна для Linux и не показывается; в Overview отображается
  время последнего *опроса* устройств.

## Безопасность и приватность

* Внешние программы запускаются только списком аргументов (без `shell=True`), с таймаутами;
  идентификаторы устройств проходят валидацию.
* Приложение не требует root, не открывает сетевых портов, не хранит ADB-ключи и пароли.
* В журнале (`~/.local/state/samsung-ecosystem-hub/hub.log`) MAC-адреса и id устройств маскируются.
* Единственные изменения системы, которые приложение делает по вашему нажатию: включение/выключение
  Bluetooth (`rfkill unblock` + `bluetoothctl power`), подключение/отключение наушников, команды KDE Connect.

## Структура

```
samsung_hub/
  app/            main.py (вход), backend.py (мост QML ↔ Python, фоновые потоки)
  services/       runner (безопасный запуск), collector (сбор состояния), config, logger
  integrations/   bluez, kdeconnect, adb, buds, system
  models/         device.py (DeviceStatus, LinkState…)
  ui/             Main.qml, Theme.qml, страницы и компоненты
  assets/         иконки SVG и иконка приложения
tests/            unittest (разборы, сборка состояния, раннер, конфиг)
scripts/          install.sh, uninstall.sh, run-tests.sh
bin/              samsung-ecosystem-hub — безопасный лаунчер
```

Тесты: `scripts/run-tests.sh`

## Удаление

```bash
scripts/uninstall.sh          # убирает ярлык, иконку, команду и автозапуск
scripts/uninstall.sh --purge  # + настройки и журнал
```

Системные пакеты, Flatpak GalaxyBudsClient и исходники не затрагиваются.

## Что можно улучшить дальше

* Тонкая интеграция с D-Bus KDE Connect (сигналы вместо опроса, прогресс передачи файлов).
* Ответы на SMS и управление медиа телефона через плагины KDE Connect.
* Беспроводной ADB (`adb pair`/`adb connect`) с вводом кода сопряжения.
* Виджет Plasma с батареями устройств.
