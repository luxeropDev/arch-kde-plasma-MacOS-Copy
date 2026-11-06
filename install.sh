#!/usr/bin/env bash
# =============================================================================
#  macOS Tahoe для Arch Linux + KDE Plasma 6 — полная установка одним скриптом
#
#  Что получится:
#    • строка меню сверху:  [Apple] [Приложение] [Меню приложения] … [значки]
#      [Пункт управления] [Spotlight] [Дата и время]
#    • меню Apple: Об этом компьютере, Настройки, App Store, Сон, Перезагрузить,
#      Выключить, Заблокировать, Завершить сеанс
#    • Пункт управления (Control Center): Wi‑Fi, Bluetooth, Авиарежим,
#      Не беспокоить, Тёмная тема, Ночной свет, Яркость, Звук, Сейчас играет
#    • Dock Krema с параболическим увеличением значков при наведении
#    • экран блокировки как в macOS: крупные часы сверху, аватар и пароль внизу
#    • тема MacTahoe (окна, иконки, курсоры, GTK), кнопки окон слева,
#      «джинн» при сворачивании, размытие, горячие клавиши как на Mac
#
#  Запуск (внутри сессии Plasma, обычным пользователем — НЕ через sudo):
#      ./install.sh                    # тёмное оформление
#      ./install.sh --light            # светлое
#      ./install.sh --update           # заново скачать темы MacTahoe
#      ./install.sh --samsung          # + Samsung Ecosystem Hub (KDE Connect, scrcpy, Galaxy Buds)
#      ./install.sh --grub-timeout 1   # + меню GRUB на 1 секунду
#  Пароль sudo спросят один раз в начале.
#  Откат: bash ~/.local/share/macos-kde/backup-*/restore.sh
# =============================================================================
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VARIANT=Dark
UPDATE=0
SAMSUNG=0
GRUB_TIMEOUT=""
while (($#)); do
    case "$1" in
        --light)  VARIANT=Light ;;
        --dark)   VARIANT=Dark ;;
        --update) UPDATE=1 ;;
        --samsung) SAMSUNG=1 ;;
        --grub-timeout) GRUB_TIMEOUT="${2:?укажите секунды}"; shift ;;
        -h|--help) sed -n '2,27p' "$0"; exit 0 ;;
        *) echo "Неизвестный параметр: $1"; exit 1 ;;
    esac
    shift
done
v="${VARIANT,,}"

DATA="$HOME/.local/share/macos-kde"
SRC="$HOME/.cache/macos-tahoe-src"
LOG="$DATA/install.log"
mkdir -p "$DATA" "$HOME/.local/bin"
exec > >(tee -a "$LOG") 2>&1

c_b='\e[1;34m'; c_g='\e[1;32m'; c_y='\e[1;33m'; c_r='\e[1;31m'; c_0='\e[0m'
STEP=0; TOTAL=11
step() { STEP=$((STEP + 1)); echo -e "\n${c_b}[$STEP/$TOTAL] $*${c_0}"; }
ok()   { echo -e "  ${c_g}✔${c_0} $*"; }
warn() { echo -e "  ${c_y}!${c_0} $*"; WARNINGS+=("$*"); }
die()  { echo -e "  ${c_r}✘ $*${c_0}"; exit 1; }
WARNINGS=()

kw() { kwriteconfig6 "$@"; }
qd() { qdbus6 "$@" 2>/dev/null; }

# ----------------------------------------------------------------- проверки --
[[ $EUID -eq 0 ]] && die "Запусти обычным пользователем: ./install.sh (без sudo)"
command -v pacman >/dev/null       || die "Нужен Arch Linux"
command -v plasmashell >/dev/null  || die "Нужна KDE Plasma 6"
[[ "$(plasmashell --version 2>/dev/null | grep -oE '[0-9]+' | head -1)" == 6 ]] || die "Нужна Plasma 6"
[[ -n "${WAYLAND_DISPLAY:-}${DISPLAY:-}" ]] || die "Запусти скрипт из графической сессии Plasma (в Konsole)"
for f in plasmoids/org.macos.applemenu plasmoids/org.macos.controlcenter plasmoids/org.macos.appname \
         plasmoids/org.macos.spotlight plasmoids/org.macos.launchpad plasmoids/org.macos.batteries lockscreen/patch.py lockscreen/MacClock.qml lockscreen/MacTopBar.qml \
         lockscreen/macos-lockscreen-sync bin/macos-appearance bin/macos-launchpad bin/macos-lock-on-login; do
    [[ -e "$HERE/$f" ]] || die "Не найден $HERE/$f — запускай install.sh из папки репозитория"
done

echo -e "${c_b}macOS Tahoe для KDE Plasma — оформление: $VARIANT${c_0}"
sudo -v || die "Нужен пароль sudo"
( while kill -0 $$ 2>/dev/null; do sudo -n true; sleep 45; done ) 2>/dev/null &
KEEPALIVE=$!
trap 'kill $KEEPALIVE 2>/dev/null' EXIT

# ---------------------------------------------------------- 1. резервная копия
step "Резервная копия текущих настроек"
BK="$DATA/backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BK/config"
for f in kdeglobals kwinrc kglobalshortcutsrc plasmarc plasmashellrc kcminputrc krunnerrc \
         plasma-org.kde.plasma.desktop-appletsrc kscreenlockerrc ksplashrc kremarc \
         Kvantum gtk-3.0 gtk-4.0; do
    [[ -e "$HOME/.config/$f" ]] && cp -a "$HOME/.config/$f" "$BK/config/"
done
cat > "$BK/restore.sh" <<EOF
#!/usr/bin/env bash
# Возврат к настройкам до установки macOS-оформления
pkill -x krema 2>/dev/null
rm -f "\$HOME/.config/autostart/krema.desktop"
"\$HOME/.local/bin/macos-lockscreen-sync" --remove 2>/dev/null
systemctl --user disable --now macos-lockscreen-sync.service 2>/dev/null
sudo rm -f /etc/pacman.d/hooks/macos-lockscreen.hook
cp -a "$BK/config/." "\$HOME/.config/"
echo "Готово. Выйди из сеанса и зайди снова."
EOF
chmod +x "$BK/restore.sh"
ok "Сохранено в $BK"

# ------------------------------------------------------------------ 2. пакеты
step "Пакеты из репозиториев Arch"
PKGS=(git base-devel python kvantum qt6-tools inter-font noto-fonts noto-fonts-emoji ttf-jetbrains-mono
      appmenu-gtk-module sassc glib2 libxml2 gtk-update-icon-cache kde-gtk-config
      xdg-desktop-portal-kde networkmanager bluez-utils wireplumber
      dolphin kinfocenter plasma-systemmonitor spectacle discover pyside6 python-pip)
((SAMSUNG)) && PKGS+=(kdeconnect android-tools scrcpy flatpak)
sudo pacman -Syu --needed --noconfirm "${PKGS[@]}" && ok "Система обновлена, пакеты установлены" \
    || die "pacman завершился с ошибкой — смотри вывод выше"

if ! command -v yay >/dev/null; then
    rm -rf "$SRC/yay-bin" && git clone -q --depth 1 https://aur.archlinux.org/yay-bin.git "$SRC/yay-bin" \
        && (cd "$SRC/yay-bin" && makepkg -si --noconfirm) && ok "yay установлен" || warn "yay не установился"
fi

# --------------------------------------------------------------------- 3. AUR
step "Dock Krema и шрифт San Francisco (AUR, сборка займёт пару минут)"
aur() { yay -S --needed --noconfirm --answerdiff None --answerclean None --removemake "$@"; }
if command -v yay >/dev/null; then
    aur krema && ok "Krema (Dock с увеличением значков)" || warn "Krema не собралась — останется обычный Dock Plasma"
    { aur apple-fonts || aur otf-apple-sf-pro; } && ok "Шрифты SF Pro" || warn "SF Pro не установился — будет шрифт Inter"
else
    warn "Нет yay — Dock Krema и SF Pro пропущены"
fi

# ------------------------------------------------------------- 4. темы MacTahoe
step "Темы MacTahoe (KDE, Kvantum, иконки, курсоры, GTK)"
have_theme() { [[ -d "$HOME/.local/share/plasma/look-and-feel/com.github.vinceliuice.MacTahoe-$VARIANT" \
                  && -d "$HOME/.local/share/icons/MacTahoe-$v" && -d "$HOME/.local/share/icons/MacTahoe-cursors" ]]; }
if have_theme && [[ $UPDATE -eq 0 ]]; then
    ok "Уже установлены (обновить: --update)"
else
    mkdir -p "$SRC"
    for repo in MacTahoe-kde MacTahoe-icon-theme MacTahoe-gtk-theme; do
        if [[ -d "$SRC/$repo/.git" ]]; then git -C "$SRC/$repo" pull -q --ff-only
        else git clone -q --depth 1 "https://github.com/vinceliuice/$repo.git" "$SRC/$repo"; fi \
            || warn "Не удалось скачать $repo"
    done
    (cd "$SRC/MacTahoe-kde" && ./install.sh >/dev/null 2>&1) && ok "KDE-тема, Kvantum, обои, рамки окон" || warn "MacTahoe-kde: ошибка установки"
    (cd "$SRC/MacTahoe-icon-theme" && ./install.sh >/dev/null 2>&1) && ok "Иконки" || warn "Иконки: ошибка установки"
    (cd "$SRC/MacTahoe-icon-theme/cursors" && ./install.sh >/dev/null 2>&1) && ok "Курсоры" || warn "Курсоры: ошибка установки"
    (cd "$SRC/MacTahoe-gtk-theme" && ./install.sh -l >/dev/null 2>&1) && ok "GTK-тема" || warn "GTK-тема: ошибка установки"
fi
have_theme || die "Тема MacTahoe не установилась — проверь интернет и запусти снова"

# ---------------------------------------------------------- 5. наши компоненты
step "Меню Apple, Пункт управления, Spotlight, экран блокировки"
for p in "$HERE"/plasmoids/*/; do
    id=$(basename "$p")
    { kpackagetool6 -t Plasma/Applet -u "$p" >/dev/null 2>&1 || kpackagetool6 -t Plasma/Applet -i "$p" >/dev/null 2>&1; } \
        && ok "$id" || die "Не удалось установить $id"
done
install -m755 "$HERE/bin/macos-lock-on-login" "$HERE/bin/macos-launchpad" "$HERE/bin/macos-appearance" "$HERE/lockscreen/macos-lockscreen-sync" "$HOME/.local/bin/"
mkdir -p "$DATA/lockscreen"
cp "$HERE/lockscreen/MacClock.qml" "$HERE/lockscreen/MacTopBar.qml" "$HERE/lockscreen/patch.py" "$DATA/lockscreen/"

# Приложения копируются в ~/.local/share/macos-kde/apps — папку репозитория потом можно удалить
mkdir -p "$DATA/apps"
cp -a "$HERE/apps/." "$DATA/apps/"
find "$DATA/apps" -name __pycache__ -prune -exec rm -rf {} + 2>/dev/null

# «Системные настройки» в стиле macOS 27
bash "$DATA/apps/system-settings/install.sh" >/dev/null && ok "Системные настройки" || warn "Системные настройки не установились"

# Samsung Ecosystem Hub (по желанию: --samsung)
if ((SAMSUNG)); then
    bash "$DATA/apps/samsung-ecosystem-hub/scripts/install.sh" >/dev/null && ok "Samsung Ecosystem Hub" || warn "Samsung Ecosystem Hub не установился"
    flatpak install --user -y --noninteractive flathub me.timschneeberger.GalaxyBudsClient >/dev/null 2>&1 \
        || { flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo \
             && flatpak install --user -y --noninteractive flathub me.timschneeberger.GalaxyBudsClient >/dev/null 2>&1; } \
        && ok "GalaxyBudsClient (Flatpak)" || warn "GalaxyBudsClient не установился"
fi

# Dolphin в стиле Finder (только если Dolphin сейчас закрыт)
bash "$DATA/apps/finder/apply-finder-style.sh" >/dev/null 2>&1 && ok "Dolphin в стиле Finder" \
    || warn "Оформление Finder пропущено: закройте Dolphin и выполните apps/finder/apply-finder-style.sh"

# Синхронизация экрана блокировки при каждом входе (до запуска plasmashell)
mkdir -p "$HOME/.config/systemd/user"
cat > "$HOME/.config/systemd/user/macos-lockscreen-sync.service" <<'EOF'
[Unit]
Description=Экран блокировки в стиле macOS (синхронизация с версией Plasma)
Before=plasma-plasmashell.service

[Service]
Type=oneshot
ExecStart=%h/.local/bin/macos-lockscreen-sync

[Install]
WantedBy=plasma-workspace.target
EOF
systemctl --user daemon-reload && systemctl --user enable macos-lockscreen-sync.service >/dev/null 2>&1 \
    && ok "Автосинхронизация при входе" || warn "Не удалось включить службу синхронизации"

# Блокировка после автовхода — служба systemd до запуска рабочего стола
# (работает, только если вы включили автовход в настройках экрана входа)
rm -f "$HOME/.config/autostart/macos-lock-on-login.desktop"
cat > "$HOME/.config/systemd/user/macos-lock-on-login.service" <<'EOF'
[Unit]
Description=Экран блокировки macOS сразу после автовхода (до показа рабочего стола)
After=plasma-kwin_wayland.service
Before=plasma-plasmashell.service

[Service]
Type=oneshot
ExecStart=%h/.local/bin/macos-lock-on-login
TimeoutStartSec=20

[Install]
WantedBy=plasma-workspace.target
EOF
systemctl --user daemon-reload && systemctl --user enable macos-lock-on-login.service >/dev/null 2>&1 \
    && ok "Блокировка после автовхода" || warn "Не удалось включить блокировку после автовхода"

# Не открывать заново программы прошлого сеанса (в macOS — флажок «Открывать окна снова»)
kw --file ksmserverrc --group General --key loginMode emptySession

# …и сразу после обновления Plasma через pacman
sudo mkdir -p /etc/pacman.d/hooks
sudo tee /etc/pacman.d/hooks/macos-lockscreen.hook >/dev/null <<EOF
[Trigger]
Operation = Install
Operation = Upgrade
Type = Package
Target = plasma-desktop

[Action]
Description = Обновляю экран блокировки в стиле macOS…
When = PostTransaction
Exec = /usr/bin/runuser -u $USER -- /usr/bin/env HOME=$HOME $HOME/.local/bin/macos-lockscreen-sync
EOF
"$HOME/.local/bin/macos-lockscreen-sync" --force && ok "Экран блокировки macOS"

# -------------------------------------------------------------- 6. оформление
step "Оформление MacTahoe-$VARIANT"
LNF="com.github.vinceliuice.MacTahoe-$VARIANT"
plasma-apply-lookandfeel -a "$LNF" >/dev/null 2>&1 && ok "Глобальная тема" || warn "Глобальная тема не применилась"
"$HOME/.local/bin/macos-appearance" "$v" && ok "Цвета, Plasma, Kvantum, рамки окон, иконки, GTK"
plasma-apply-cursortheme MacTahoe-cursors >/dev/null 2>&1 && ok "Курсор"
kw --group KDE --key widgetStyle kvantum
kw --group KDE --key LookAndFeelPackage "$LNF"

WP="$HOME/.local/share/wallpapers/MacTahoe"      # сам меняется днём/ночью вместе с темой
[[ -d "$WP" ]] || WP="$HOME/.local/share/wallpapers/MacTahoe-$VARIANT"
plasma-apply-wallpaperimage "$WP" >/dev/null 2>&1 && ok "Обои рабочего стола"
kw --file kscreenlockerrc --group Greeter --key WallpaperPlugin org.kde.image
kw --file kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General --key Image "file://$WP"
kw --file kscreenlockerrc --group Greeter --group LnF --group General --key alwaysShowClock true
kw --file kscreenlockerrc --group Greeter --group LnF --group General --key showMediaControls true
ok "Обои экрана блокировки"

# ------------------------------------------------------------------ 7. шрифты
step "Шрифты"
fc-cache -f >/dev/null 2>&1
if   fc-list | grep -qi "SF Pro Text"; then UI="SF Pro Text"; TITLE="SF Pro Display"
elif fc-list | grep -qi "SF Pro";      then UI="SF Pro";      TITLE="SF Pro"
else UI="Inter"; TITLE="Inter"; fi
MONO="JetBrains Mono"; fc-list | grep -qi "SF Mono" && MONO="SF Mono"
font() { echo "$1,$2,-1,5,$3,0,0,0,0,0,0,0,0,0,0,1"; }
kw --group General --key font                 "$(font "$UI" 10 400)"
kw --group General --key menuFont             "$(font "$UI" 10 400)"
kw --group General --key toolBarFont          "$(font "$UI" 10 400)"
kw --group General --key smallestReadableFont "$(font "$UI" 8 400)"
kw --group General --key fixed                "$(font "$MONO" 10 400)"
kw --group WM      --key activeFont           "$(font "$TITLE" 10 700)"
for g in 3.0 4.0; do kw --file "$HOME/.config/gtk-$g/settings.ini" --group Settings --key gtk-font-name "$UI 10"; done
ok "Интерфейс: $UI, моноширинный: $MONO"

# ------------------------------------------------- 8. окна, эффекты, клавиши
step "Окна, анимации и горячие клавиши как на Mac"
kw --file kwinrc --group org.kde.kdecoration2 --key library org.kde.kwin.aurorae
kw --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft "XIA"
kw --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight ""
kw --file kwinrc --group org.kde.kdecoration2 --key BorderSize None
kw --file kwinrc --group org.kde.kdecoration2 --key BorderSizeAuto false
for g in 3.0 4.0; do kw --file "$HOME/.config/gtk-$g/settings.ini" --group Settings --key gtk-decoration-layout "close,minimize,maximize:"; done
gsettings set org.gnome.desktop.wm.preferences button-layout "close,minimize,maximize:" 2>/dev/null

kw --file kwinrc --group Plugins --key blurEnabled true
kw --file kwinrc --group Plugins --key contrastEnabled true
kw --file kwinrc --group Plugins --key magiclampEnabled true     # «джинн» при сворачивании в Dock
kw --file kwinrc --group Plugins --key squashEnabled false
kw --file kwinrc --group Plugins --key overviewEnabled true      # Mission Control
kw --file kwinrc --group Plugins --key windowviewEnabled true    # App Exposé
kw --file kwinrc --group Plugins --key slideEnabled true
kw --file kwinrc --group Plugins --key scaleEnabled true
kw --file kwinrc --group Plugins --key glideEnabled false
kw --file kwinrc --group Plugins --key shakecursorEnabled true
kw --file kwinrc --group Effect-blur --key BlurStrength 10
kw --file kwinrc --group Effect-blur --key NoiseStrength 0
kw --file kwinrc --group Effect-overview --key BorderActivate 9  # горячий угол слева сверху
kw --file kwinrc --group ElectricBorders --key TopLeft None
kw --file kwinrc --group Windows --key Placement Centered
kw --file kwinrc --group TabBox --key LayoutName big_icons
kw --file kwinrc --group TabBox --key HighlightWindows false
kw --group KDE --key AnimationDurationFactor 0.75
kw --group KDE --key SingleClick false
kw --file krunnerrc --group General --key FreeFloating true      # Spotlight по центру

GS=kglobalshortcutsrc
kw --file $GS --group services --group org.kde.krunner.desktop --key _launch "Meta+Space	Alt+Space	Search"
kw --file $GS --group kwin --key "Overview"  "Meta+Up	Meta+W,Meta+W,Toggle Overview"
kw --file $GS --group kwin --key "ExposeAll" "Meta+Down	Ctrl+F10,Ctrl+F10,Toggle Present Windows (All desktops)"
kw --file $GS --group kwin --key "Window Close" "Meta+Q	Alt+F4,Alt+F4,Close Window"
kw --file $GS --group kwin --key "Kill Window" "Ctrl+Alt+Esc,Meta+Ctrl+Esc,Kill Window"
kw --file $GS --group services --group org.kde.spectacle.desktop --key FullScreenScreenShot "Meta+Shift+3	Print"
kw --file $GS --group services --group org.kde.spectacle.desktop --key RectangularRegionScreenShot "Meta+Shift+4	Meta+Shift+Print"
kw --file $GS --group services --group org.kde.spectacle.desktop --key _launch "Meta+Shift+5	Meta+Shift+S"
kw --file ksplashrc --group KSplash --key Engine KSplashQML
ok "Кнопки ● ● ● слева, «джинн», размытие, Mission Control"
ok "Meta+Space — Spotlight, Meta+Q — закрыть, Meta+Shift+3/4/5 — скриншоты"

# ------------------------------------------------------------------ 9. Dock
step "Dock"
DOCK_LAUNCHERS=$(grep -m1 '^launchers=' "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" 2>/dev/null | cut -d= -f2-)
[[ -n "$DOCK_LAUNCHERS" ]] || DOCK_LAUNCHERS="preferred://filemanager,preferred://browser,applications:org.kde.konsole.desktop,applications:org.kde.discover.desktop,applications:systemsettings.desktop"
mkdir -p "$HOME/.local/share/applications"
cat > "$HOME/.local/share/applications/macos-launchpad.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Launchpad
Comment=Все приложения
Exec=$HOME/.local/bin/macos-launchpad
Icon=view-app-grid
Terminal=false
NoDisplay=true
EOF
[[ "$DOCK_LAUNCHERS" == *macos-launchpad.desktop* ]] || DOCK_LAUNCHERS="applications:macos-launchpad.desktop,$DOCK_LAUNCHERS"
USE_KREMA=0
if command -v krema >/dev/null; then
    USE_KREMA=1
    K="$HOME/.config/kremarc"
    kw --file kremarc --group General --key IconSize 52
    kw --file kremarc --group General --key IconSpacing 6
    kw --file kremarc --group General --key MaxZoomFactor 1.8
    kw --file kremarc --group General --key ZoomStyle 0
    kw --file kremarc --group General --key ZoomAnimationPreset 0
    kw --file kremarc --group General --key IconOpacityInactive 1.0
    kw --file kremarc --group General --key IconOpacityMinimized 0.75
    kw --file kremarc --group General --key CornerRadius 20
    kw --file kremarc --group General --key Floating true
    kw --file kremarc --group General --key FloatingMargin 6
    kw --file kremarc --group General --key VisibilityMode 2
    kw --file kremarc --group General --key ReserveScreenSpace false
    kw --file kremarc --group General --key Edge 1
    kw --file kremarc --group General --key BackgroundStyle 3
    kw --file kremarc --group General --key BackgroundOpacity 0.45
    kw --file kremarc --group General --key PreviewEnabled true
    kw --file kremarc --group General --key SeparateLaunchers true
    if ! grep -q '^PinnedLaunchers=' "$K" 2>/dev/null; then
        kw --file kremarc --group General --key PinnedLaunchers "$DOCK_LAUNCHERS"
    fi
    ok "Krema: увеличение ×1.8, стекло, уходит из‑под окон"
else
    warn "Krema не установлена — используется Dock Plasma (без увеличения значков)"
fi

# ------------------------------------------------------- 10. строка меню и Dock
step "Строка меню сверху"
LAYOUT=$(cat <<EOF
panels().forEach(function (p) { p.remove(); });

var top = new Panel("org.kde.panel");
top.location = "top";
top.height = 30;
top.floating = false;
top.hiding = "none";
top.lengthMode = "fill";
print("TOPID=" + top.id);

top.addWidget("org.macos.applemenu");
top.addWidget("org.macos.appname");
top.addWidget("org.kde.plasma.appmenu");
top.addWidget("org.kde.plasma.panelspacer");

var tray = top.addWidget("org.kde.plasma.systemtray");
tray.currentConfigGroup = ["General"];
tray.writeConfig("shownItems", ["org.kde.plasma.battery", "org.kde.plasma.networkmanagement", "org.kde.plasma.keyboardlayout"]);
tray.writeConfig("hiddenItems", ["org.kde.plasma.volume", "org.kde.plasma.brightness", "org.kde.plasma.clipboard",
    "org.kde.plasma.bluetooth", "org.kde.plasma.notifications", "org.kde.plasma.mediacontroller",
    "org.kde.plasma.devicenotifier", "org.kde.kscreen", "org.kde.plasma.cameraindicator",
    "org.kde.plasma.printmanager", "org.kde.plasma.vault", "org.kde.plasma.weather",
    "org.kde.plasma.keyboardindicator", "org.kde.plasma.manage-inputmethod", "org.kde.plasma.dwellclicker",
    "org.kde.kupapplet"]);

var launchpad = top.addWidget("org.macos.launchpad");           // Launchpad (Alt+F1 или значок в Dock)
launchpad.globalShortcut = "Alt+F1";

top.addWidget("org.macos.controlcenter");
top.addWidget("org.macos.spotlight");

var clock = top.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("showDate", true);
clock.writeConfig("dateDisplayFormat", "BesideTime");
clock.writeConfig("dateFormat", "custom");
clock.writeConfig("customDateFormat", "ddd d MMM");
clock.writeConfig("use24hFormat", 2);
clock.writeConfig("showSeconds", 0);

if (!$USE_KREMA) {
    var dock = new Panel("org.kde.panel");
    dock.location = "bottom";
    dock.height = 60;
    dock.floating = true;
    dock.lengthMode = "fit";
    dock.alignment = "center";
    dock.hiding = "dodgewindows";
    var tasks = dock.addWidget("org.kde.plasma.icontasks");
    tasks.currentConfigGroup = ["General"];
    tasks.writeConfig("launchers", "$DOCK_LAUNCHERS");
    tasks.writeConfig("showOnlyCurrentDesktop", false);
    tasks.writeConfig("groupingStrategy", 1);
    tasks.writeConfig("indicateAudioStreams", true);
    tasks.writeConfig("iconSpacing", 1);
    dock.addWidget("org.kde.plasma.marginsseparator");
    dock.addWidget("org.kde.plasma.trash");
}

// Виджет «Батареи» справа на рабочем столе, как в macOS
desktops().forEach(function (d) {
    if (d.screen !== 0) return;
    d.widgets("org.macos.batteries").forEach(function (w) { w.remove(); });
    var r = screenGeometry(d.screen);
    d.addWidget("org.macos.batteries", r.width - 368, 52, 340, 168);
});
EOF
)
if OUT=$(qd org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$LAYOUT"); then
    TOPID=$(grep -oE 'TOPID=[0-9]+' <<<"$OUT" | cut -d= -f2)
    # Полупрозрачная строка меню, как в macOS (даже при развёрнутом окне)
    [[ -n "$TOPID" ]] && kw --file plasmashellrc --group PlasmaViews --group "Panel $TOPID" --key panelOpacity 2
    ok "Панели собраны"
else
    echo "$LAYOUT" > "$DATA/layout.js"
    warn "Plasma не приняла раскладку — скрипт сохранён в $DATA/layout.js"
fi

# ------------------------------------------------------------- 11. применение
step "Применяю изменения"
qd org.kde.KWin /KWin reconfigure >/dev/null
qd org.kde.kglobalaccel /kglobalaccel org.kde.KGlobalAccel.reloadConfig >/dev/null
# Plasma не перезапускаем: вместе с ней закрылись бы программы, запущенные из панели
# (в том числе терминал с этим скриптом). Новые виджеты подхватятся после повторного входа.
ok "Изменения сохранены — выйдите из сеанса и войдите снова"
if [[ $USE_KREMA -eq 1 ]]; then
    pkill -x krema 2>/dev/null; sleep 1
    (setsid krema >/dev/null 2>&1 &)
    ok "Dock Krema запущен (дальше стартует сам при входе)"
fi

# Меню GRUB (по желанию: --grub-timeout N)
if [[ -n "$GRUB_TIMEOUT" ]]; then
    sudo bash "$HERE/bin/set-grub-timeout" "$GRUB_TIMEOUT" >/dev/null 2>&1 && ok "Меню GRUB: $GRUB_TIMEOUT с" \
        || warn "GRUB не изменён (загрузчик не GRUB или нет /boot/grub/grub.cfg)"
fi

echo -e "\n${c_g}════════════════════════════════════════════════════════════════${c_0}"
echo -e "${c_g}  Готово! Для полного эффекта (шрифты, курсор, GTK) — выйди из сеанса и зайди снова.${c_0}"
echo    "   Меню Apple ............ значок  слева сверху"
echo    "   Пункт управления ...... значок с двумя переключателями справа"
echo    "   Launchpad ............. клавиша Meta или первый значок в Dock"
echo    "   Spotlight ............. Meta+Space"
echo    "   Mission Control ....... Meta+↑ или мышь в левый верхний угол"
echo    "   Заблокировать экран ... Meta+L"
echo    "   Тёмная/светлая тема ... в Пункте управления или: macos-appearance toggle"
echo    "   Откат ................. bash $BK/restore.sh"
if ((${#WARNINGS[@]})); then
    echo -e "\n${c_y}Предупреждения (на основное не влияют):${c_0}"
    for w in "${WARNINGS[@]}"; do echo "   • $w"; done
fi
echo "   Лог: $LOG"
