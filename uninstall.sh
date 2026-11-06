#!/usr/bin/env bash
# Удаляет оформление macOS и возвращает прежние настройки KDE.
# Системные пакеты (kvantum, krema, шрифты, kdeconnect…) не удаляются.
set -uo pipefail
DATA="$HOME/.local/share/macos-kde"

last=$(ls -1d "$DATA"/backup-2* 2>/dev/null | sort | tail -1)
if [[ -n "$last" && -x "$last/restore.sh" ]]; then
    bash "$last/restore.sh"
else
    echo "Резервная копия настроек не найдена — восстанавливаю только компоненты"
fi

for id in org.macos.applemenu org.macos.appname org.macos.controlcenter org.macos.spotlight \
          org.macos.launchpad org.macos.batteries; do
    kpackagetool6 -t Plasma/Applet -r "$id" >/dev/null 2>&1
done
systemctl --user disable --now macos-lock-on-login.service macos-lockscreen-sync.service 2>/dev/null
rm -f "$HOME/.config/systemd/user/macos-lock-on-login.service" "$HOME/.config/systemd/user/macos-lockscreen-sync.service"
"$HOME/.local/bin/macos-lockscreen-sync" --remove 2>/dev/null
rm -f "$HOME/.local/bin/"{macos-appearance,macos-launchpad,macos-lock-on-login,macos-lockscreen-sync,mac-system-settings}
rm -f "$HOME/.local/share/applications/"{macos-launchpad,mac-system-settings,systemsettings}.desktop
[[ -x "$DATA/apps/samsung-ecosystem-hub/scripts/uninstall.sh" ]] && bash "$DATA/apps/samsung-ecosystem-hub/scripts/uninstall.sh" >/dev/null
last_finder=$(ls -1d "$DATA"/backup-finder-* 2>/dev/null | sort | head -1)
[[ -n "$last_finder" ]] && bash "$DATA/apps/finder/apply-finder-style.sh" --restore "$last_finder" 2>/dev/null
sudo rm -f /etc/pacman.d/hooks/macos-lockscreen.hook
echo "Готово. Выйдите из сеанса и войдите снова. / Done — log out and back in."
