#!/usr/bin/env bash
# Ставит «Системные настройки» в профиль пользователя (без sudo).
set -euo pipefail
ROOT="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
mkdir -p "$HOME/.local/bin" "$HOME/.local/share/applications"
ln -sf "$ROOT/bin/mac-system-settings" "$HOME/.local/bin/mac-system-settings"
sed "s|@BIN@|$HOME/.local/bin/mac-system-settings|" "$ROOT/mac-system-settings.desktop" \
    > "$HOME/.local/share/applications/mac-system-settings.desktop"
# Подменяем ярлык «Параметры системы»: Dock, Launchpad и поиск открывают это окно.
# Модули KDE по-прежнему доступны (KDE System Settings и пункты со стрелкой).
cat > "$HOME/.local/share/applications/systemsettings.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Системные настройки
Name[en]=System Settings
Comment=Настройки компьютера в стиле macOS
Exec=$HOME/.local/bin/mac-system-settings
Icon=preferences-system
Terminal=false
Categories=Settings;
Keywords=settings;preferences;system settings;настройки;параметры;
StartupWMClass=systemsettings
EOF
sed -i 's/^Categories=Settings;$/Categories=Settings;\nNoDisplay=true/' "$HOME/.local/share/applications/mac-system-settings.desktop"
command -v kbuildsycoca6 >/dev/null && kbuildsycoca6 >/dev/null 2>&1 || true
echo "Готово: mac-system-settings (в меню — «Системные настройки»)"
