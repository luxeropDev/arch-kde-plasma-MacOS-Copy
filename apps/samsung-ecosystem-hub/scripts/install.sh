#!/usr/bin/env bash
# Установка в профиль пользователя (~/.local). Не требует sudo и не трогает системные файлы.
set -euo pipefail
ROOT="$(dirname "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
BIN="$HOME/.local/bin/samsung-ecosystem-hub"
APPS="$HOME/.local/share/applications"
ICONS="$HOME/.local/share/icons/hicolor/scalable/apps"

mkdir -p "$HOME/.local/bin" "$APPS" "$ICONS"
chmod +x "$ROOT/bin/samsung-ecosystem-hub"
ln -sf "$ROOT/bin/samsung-ecosystem-hub" "$BIN"
install -m644 "$ROOT/samsung_hub/assets/app-icon.svg" "$ICONS/samsung-ecosystem-hub.svg"
sed "s|@BIN@|$BIN|" "$ROOT/data/samsung-ecosystem-hub.desktop" > "$APPS/samsung-ecosystem-hub.desktop"
chmod 644 "$APPS/samsung-ecosystem-hub.desktop"

command -v update-desktop-database >/dev/null && update-desktop-database "$APPS" 2>/dev/null || true
command -v kbuildsycoca6 >/dev/null && kbuildsycoca6 >/dev/null 2>&1 || true
gtk-update-icon-cache -q -t "$HOME/.local/share/icons/hicolor" 2>/dev/null || true

echo "Установлено: $BIN"
echo "Приложение появилось в меню KDE (Samsung Ecosystem Hub)."

missing=()
for pair in kdeconnect-cli:kdeconnect adb:android-tools scrcpy:scrcpy; do
    command -v "${pair%%:*}" >/dev/null || missing+=("${pair##*:}")
done
if ((${#missing[@]})); then
    echo
    echo "Не хватает пакетов. Установите одной командой (потребуется ваш пароль):"
    echo "  sudo pacman -S --needed ${missing[*]}"
fi
