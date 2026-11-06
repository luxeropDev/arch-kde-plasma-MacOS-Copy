#!/usr/bin/env bash
# Удаляет только файлы самого приложения. Системные пакеты (kdeconnect, scrcpy, bluez, flatpak,
# GalaxyBudsClient) и исходники в ~/Projects остаются нетронутыми.
#   --purge  дополнительно удалить настройки и журнал приложения
set -euo pipefail
rm -fv "$HOME/.local/bin/samsung-ecosystem-hub" \
       "$HOME/.local/share/applications/samsung-ecosystem-hub.desktop" \
       "$HOME/.local/share/icons/hicolor/scalable/apps/samsung-ecosystem-hub.svg" \
       "$HOME/.config/autostart/samsung-ecosystem-hub.desktop"
if [[ "${1:-}" == "--purge" ]]; then
    rm -rfv "$HOME/.config/samsung-ecosystem-hub" "$HOME/.local/state/samsung-ecosystem-hub"
fi
command -v kbuildsycoca6 >/dev/null && kbuildsycoca6 >/dev/null 2>&1 || true
echo "Готово. Исходники остались в $(dirname "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
