# Roselogin

SDDM (Qt 6, SDDM 0.21+) port of roselock: the same big stacked clock, Material 3 palette and entry view.

## Install
    ./install.sh ~/Pictures/wall.jpg        # copies the theme, derives the palette from the wallpaper, enables it
    ./install.sh --test ~/Pictures/wall.jpg # preview in a window only, nothing enabled

Preview later with `sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/roselogin`.
Keep a TTY handy (Ctrl+Alt+F2) the first time you log in through it.

## Config
Edit `/usr/share/sddm/themes/roselogin/theme.conf` (or drop overrides in `theme.conf.user`). Same keys as roselock
(`input`, `keypad`, `pin_length`, `font`, `md3_mode`, `blur`, `dim`, `hour24`, `clock`, `clock_gap`, `idle_timeout`, weather).
New: `background` (file inside the theme dir), `seed` (hex colour; the greeter can't read your wallpaper, so install.sh computes it),
`power_buttons`.

## Differences from the lock screen
- Login goes through SDDM (`sddm.login`), so PAM config options are gone. Click the user / session chips under the field to switch.
- No media card or battery/wifi row (no MPRIS/UPower/nmcli in the greeter). Suspend / reboot / power-off buttons are top right.
- Weather is fetched directly over HTTPS (open-meteo); it needs network when the greeter starts and retries until it has it.
- Needs `python-pillow` only for install.sh's colour extraction, and the Google Sans font installed system-wide.
