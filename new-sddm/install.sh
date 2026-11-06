#!/bin/sh
# Install Roselogin as an SDDM theme.
#   ./install.sh [wallpaper]       copies the theme, tints it from the wallpaper, enables it
#   ./install.sh --test [wallpaper]  same, but only previews it in a window (nothing enabled)
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
DEST=/usr/share/sddm/themes/roselogin
TEST=0; [ "$1" = "--test" ] && { TEST=1; shift; }
WALL="$1"

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
cp -r "$HERE"/. "$TMP"/
rm -f "$TMP/install.sh" "$TMP/seed.py" "$TMP/README.md"; rm -rf "$TMP/__pycache__"

if [ -n "$WALL" ]; then
  [ -f "$WALL" ] || { echo "no such file: $WALL"; exit 1; }
  EXT="${WALL##*.}"
  cp "$WALL" "$TMP/background.$EXT"
  sed -i "s|^background=.*|background=background.$EXT|" "$TMP/theme.conf"
  SEED="$(python3 "$HERE/seed.py" "$WALL" "" "" 2>/dev/null | sed -n 2p)"
  if [ -n "$SEED" ]; then sed -i "s|^seed=.*|seed=$SEED|" "$TMP/theme.conf"; echo "seed colour: $SEED"
  else echo "couldn't read the wallpaper colours (needs python-pillow), keeping the default seed"; fi
fi

sudo rm -rf "$DEST"; sudo mkdir -p "$DEST"; sudo cp -r "$TMP"/. "$DEST"/
sudo chmod -R a+rX "$DEST"
echo "installed to $DEST"

if [ "$TEST" = 1 ]; then
  exec sddm-greeter-qt6 --test-mode --theme "$DEST"
fi
sudo mkdir -p /etc/sddm.conf.d
printf '[Theme]\nCurrent=roselogin\n' | sudo tee /etc/sddm.conf.d/10-roselogin.conf >/dev/null
echo "enabled. Preview any time with: sddm-greeter-qt6 --test-mode --theme $DEST"
