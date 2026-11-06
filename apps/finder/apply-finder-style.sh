#!/usr/bin/env bash
# Делает Dolphin похожим на Finder из macOS 27:
#   • панель инструментов: ‹ › | путь | вид, сортировка, поиск, меню
#   • боковая панель «Места» с мелкими значками и русскими названиями как в Finder
#   • вид «Значки» 64 px, папки сначала, без строки меню
# Перед изменением делает копию настроек. Откат: --restore <папка-копии>
set -euo pipefail

if [[ "${1:-}" == "--restore" ]]; then
    src="${2:?укажите папку резервной копии}"
    cp -a "$src/dolphinrc" "$HOME/.config/" 2>/dev/null || true
    cp -a "$src/user-places.xbel" "$HOME/.local/share/" 2>/dev/null || true
    rm -f "$HOME/.local/share/kxmlgui5/dolphin/dolphinui.rc"
    [[ -d "$src/dolphin" ]] && cp -a "$src/dolphin" "$HOME/.local/share/kxmlgui5/"
    echo "Настройки Dolphin восстановлены"
    exit 0
fi

if pgrep -x dolphin >/dev/null; then
    echo "Закройте Dolphin и запустите скрипт снова (иначе он перезапишет настройки при выходе)." >&2
    exit 1
fi

BK="$HOME/.local/share/macos-kde/backup-finder-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BK"
cp -a "$HOME/.config/dolphinrc" "$HOME/.local/share/user-places.xbel" "$BK/" 2>/dev/null || true
[[ -d "$HOME/.local/share/kxmlgui5/dolphin" ]] && cp -a "$HOME/.local/share/kxmlgui5/dolphin" "$BK/"

kw() { kwriteconfig6 --file dolphinrc "$@"; }

# ---- окно и вид ----
kw --group MainWindow --key MenuBar Disabled
kw --group MainWindow --key ToolBarsMovable Disabled
kw --group General --key ShowFullPath false
kw --group General --key EditableUrl false
kw --group General --key ShowZoomSlider false
kw --group General --key ShowSpaceInfo false
kw --group General --key GlobalViewProps true
kw --group General --key BrowseThroughArchives true
kw --group General --key FilterBar false
kw --group General --key UseTabForSwitchingSplitView true
kw --group IconsMode --key IconSize 64
kw --group IconsMode --key PreviewSize 64
kw --group IconsMode --key MaximumTextLines 2
kw --group CompactMode --key IconSize 16
kw --group DetailsMode --key IconSize 16
kw --group DetailsMode --key PreviewSize 16
kw --group DetailsMode --key ExpandableFolders true
kw --group PlacesPanel --key IconSize 16

# Глобальный вид: значки, превью, папки сначала (как в Finder)
VP="$HOME/.local/share/dolphin/view_properties/global"
mkdir -p "$VP"
cat > "$VP/.directory" <<'EOF'
[Dolphin]
PreviewsShown=true
SortFoldersFirst=true
SortRole=text
ViewMode=0
Version=4

[Settings]
HiddenFilesShown=false
EOF

# ---- панель инструментов как в Finder ----
# Версия 999 — собственная раскладка пользователя имеет приоритет над встроенной.
mkdir -p "$HOME/.local/share/kxmlgui5/dolphin"
cat > "$HOME/.local/share/kxmlgui5/dolphin/dolphinui.rc" <<'EOF'
<?xml version="1.0"?>
<!DOCTYPE gui SYSTEM "kpartgui.dtd">
<gui name="dolphin" version="999" translationDomain="dolphin">
 <ToolBar name="mainToolBar" noMerge="1" iconText="icononly">
  <text context="@title:menu">Main Toolbar</text>
  <Action name="go_back"/>
  <Action name="go_forward"/>
  <Separator name="separator_0"/>
  <Action name="url_navigators"/>
  <Action name="view_mode"/>
  <Action name="sort"/>
  <Action name="toggle_search"/>
  <Action name="hamburger_menu"/>
 </ToolBar>
</gui>
EOF

# ---- боковая панель: названия и порядок как в Finder ----
python3 - "$HOME/.local/share/user-places.xbel" "$(id -un)" <<'PY'
import sys
import xml.etree.ElementTree as ET

path, user = sys.argv[1], sys.argv[2]
ns = {"bookmark": "http://www.freedesktop.org/standards/desktop-bookmarks",
      "mime": "http://www.freedesktop.org/standards/shared-mime-info",
      "kdepriv": "http://www.kde.org/kdepriv"}
for p, u in ns.items():
    ET.register_namespace(p, u)
tree = ET.parse(path)
root = tree.getroot()
home = "file://" + __import__("os").path.expanduser("~")
titles = {
    home: user, home + "/Desktop": "Рабочий стол", home + "/Documents": "Документы",
    home + "/Downloads": "Загрузки", home + "/Music": "Музыка", home + "/Pictures": "Изображения",
    home + "/Videos": "Фильмы", "remote:/": "Сеть", "trash:/": "Корзина",
    "recentlyused:/files": "Недавние", "applications:/": "Программы",
}
order = ["recentlyused:/files", "applications:/", home + "/Desktop", home + "/Documents", home + "/Downloads",
         home, home + "/Pictures", home + "/Music", home + "/Videos"]

bookmarks = root.findall("bookmark")
by_href = {b.get("href"): b for b in bookmarks}

# «Программы» (applications:/) — как в Finder
if "applications:/" not in by_href:
    b = ET.SubElement(root, "bookmark", {"href": "applications:/"})
    ET.SubElement(b, "title").text = "Программы"
    info = ET.SubElement(b, "info")
    md = ET.SubElement(info, "metadata", {"owner": "http://freedesktop.org"})
    ET.SubElement(md, "{%s}icon" % ns["bookmark"], {"name": "applications-all"})
    by_href["applications:/"] = b

for href, b in by_href.items():
    t = b.find("title")
    if href in titles and t is not None:
        t.text = titles[href]
    if href == "recentlyused:/locations":           # в Finder нет «Недавних мест»
        for md in b.iter("metadata"):
            if md.get("owner") != "http://www.kde.org":
                continue
            hid = md.find("IsHidden")
            if hid is None:
                hid = ET.SubElement(md, "IsHidden")
            hid.text = "true"

# переставляем избранное в порядке Finder, остальное оставляем как было
for href in reversed(order):
    b = by_href.get(href)
    if b is not None:
        root.remove(b)
        root.insert(list(root).index(next(x for x in root if x.tag == "bookmark")) if root.find("bookmark") is not None else len(root), b)
tree.write(path, encoding="UTF-8", xml_declaration=True)
PY

echo "Dolphin оформлен как Finder. Копия прежних настроек: $BK"
echo "Откат: $0 --restore $BK"
