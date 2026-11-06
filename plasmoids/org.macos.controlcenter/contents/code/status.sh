#!/bin/sh
# Собирает состояние системы для Control Center в формате key=value

echo "wifi=$(nmcli radio wifi 2>/dev/null)"
nmcli -t -f NAME,TYPE con show --active 2>/dev/null | awk -F: '
    $2 == "802-11-wireless" && !w { print "ssid=" $1; w = 1 }
    $2 == "802-3-ethernet"  && !e { print "eth=" $1;  e = 1 }'

if command -v bluetoothctl >/dev/null 2>&1; then
    echo "bt=$(timeout 2 bluetoothctl show 2>/dev/null | awk '/Powered:/ { print $2; exit }')"
    echo "btdev=$(timeout 2 bluetoothctl devices Connected 2>/dev/null | head -n1 | cut -d' ' -f3-)"
fi

echo "vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)"

disp=$(qdbus6 org.kde.ScreenBrightness 2>/dev/null | grep -m1 '^/org/kde/ScreenBrightness/display')
if [ -n "$disp" ]; then
    get() { qdbus6 org.kde.ScreenBrightness "$disp" org.freedesktop.DBus.Properties.Get org.kde.ScreenBrightness.Display "$1" 2>/dev/null; }
    echo "disp=$disp"
    echo "bri=$(get Brightness)"
    echo "brimax=$(get MaxBrightness)"
fi

echo "scheme=$(kreadconfig6 --group General --key ColorScheme 2>/dev/null)"
echo "night=$(kreadconfig6 --file kwinrc --group NightColor --key Active 2>/dev/null)"

# Подсветка клавиатуры (если есть)
kb() { qdbus6 org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement/Actions/KeyboardBrightnessControl "org.kde.Solid.PowerManagement.Actions.KeyboardBrightnessControl.$1" 2>/dev/null; }
kbmax=$(kb keyboardBrightnessMax)
if [ -n "$kbmax" ] && [ "$kbmax" -gt 0 ] 2>/dev/null; then
    echo "kbd=$(kb keyboardBrightness)"
    echo "kbdmax=$kbmax"
fi

# Телефон через KDE Connect (если установлен)
if command -v kdeconnect-cli >/dev/null 2>&1; then
    echo "phone=$(kdeconnect-cli -a --name-only 2>/dev/null | head -n1)"
fi
