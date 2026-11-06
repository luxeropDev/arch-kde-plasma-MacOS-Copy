#!/usr/bin/env bash
# Установка одной командой / One-line install:
#   bash <(curl -fsSL https://raw.githubusercontent.com/luxeropDev/arch-kde-plasma-MacOS-Copy/main/bootstrap.sh)
# Параметры передаются в install.sh, например:  ... bootstrap.sh) --light --samsung
set -euo pipefail
REPO="https://github.com/luxeropDev/arch-kde-plasma-MacOS-Copy.git"
DIR="$HOME/.local/share/macos-kde/src"

[[ $EUID -eq 0 ]] && { echo "Run as a normal user, not root / Запускайте обычным пользователем"; exit 1; }
command -v git >/dev/null || sudo pacman -S --needed --noconfirm git
if [[ -d "$DIR/.git" ]]; then
    git -C "$DIR" pull --ff-only
else
    mkdir -p "$(dirname "$DIR")"
    git clone --depth 1 "$REPO" "$DIR"
fi
exec bash "$DIR/install.sh" "$@"
