#!/bin/sh
# Тест плазмоида без перезапуска Plasma: копия с уникальным id в верхней панели,
# авто-действие через 2.5 с и снимок экрана.  usage: plasmoid-test.sh <plugin-dir> [js] [out.png]
SRC=${1:?plugin}; OPEN=${2:-root.expanded = true}; OUT=${3:-/tmp/plasmoid-test.png}
T=$(mktemp -d)
qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript 'panels().forEach(p=>p.widgets().forEach(w=>{ if (w.type.indexOf("org.macos.t")==0) w.remove(); }))' >/dev/null
for d in "$HOME"/.local/share/plasma/plasmoids/org.macos.t*; do [ -d "$d" ] && kpackagetool6 -t Plasma/Applet -r "$(basename "$d")" >/dev/null 2>&1; done
ID=org.macos.t$(date +%s)
cp -r "$HOME/macos-kde/plasmoids/$SRC" "$T/p"
sed -i "s/\"Id\": \"$SRC\"/\"Id\": \"$ID\"/" "$T/p/metadata.json"
sed -i "0,/^    P5Support.DataSource {/s||    Timer { interval: 2500; running: true; onTriggered: { $OPEN } }\n    P5Support.DataSource {|" "$T/p/contents/ui/main.qml"
kpackagetool6 -t Plasma/Applet -i "$T/p" >/dev/null
sleep 1
qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "var p=panels().filter(p=>p.location=='top')[0]; p.addWidget('$ID')" >/dev/null
sleep 5
spectacle -b -n -f -o "$OUT"
journalctl --user --since "-10s" | grep -E "$ID" | tail -5
rm -rf "$T"
