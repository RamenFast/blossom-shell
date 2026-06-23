#!/usr/bin/env bash
# build.sh — generate the Blossom cursor variants from a base theme into ~/.icons.
# Default base is Bibata-Modern-Classic (rounded, modern); override with
# BLOSSOM_CURSOR_SRC=/usr/share/icons/<theme>.
set -euo pipefail
HERE="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
SRC="${BLOSSOM_CURSOR_SRC:-/usr/share/icons/Bibata-Modern-Classic}"
DEST="$HOME/.icons"
mkdir -p "$DEST"

build() { python3 "$HERE/blossom-cursorize.py" --src "$SRC" --dest "$DEST/$1" --name "$2" --fill "$3" --outline "$4"; }

#       dir              menu name        fill (body)  outline
build Blossom-Rose      "Blossom Rose"    db3776       f7e7c0   # pink body, cream-gold edge
build Blossom-Gold      "Blossom Gold"    f1bf40       4a2f10   # gold body, dark edge
build Blossom-Petal     "Blossom Petal"   e6739f       ffffff   # soft pink body, white edge

gtk-update-icon-cache -f -t "$DEST"/Blossom-Rose "$DEST"/Blossom-Gold "$DEST"/Blossom-Petal 2>/dev/null || true
echo "❀ Blossom cursors installed to $DEST. Pick one in Blossom Control, or:"
echo "    gsettings set org.cinnamon.desktop.interface cursor-theme Blossom-Rose"
