---
type: doc
description: "The desktop part of Monkeyworks: what you see and use. Sway and its keys, the bar, screens and the lid, night light, input and keyboard remaps, sound, appearance, and apps. Read when changing how the desktop looks or behaves."
status: active
---
What you see and use: Fedora's Sway desktop, as shipped, with a few shared defaults. Each person changes it for themselves with small files in `~/.config` ([[how-it-works]], Config layering).
- Sway: the window manager, its keys, and how to add your own
- Bar, launcher, notifications: the pieces around the windows
- Screens: layouts, the laptop lid, night light
- Input: keyboard, remaps, touchpad
- Sound: audio and video
- Appearance: fonts and themes
- Apps: flatpaks, and how to add or remove one

- [[monkeyimage]] (Session): every desktop package in the image
- [[monkeyworks]]: the front page

---
## Sway

Sway: a window manager (it places and sizes the windows). The image ships Fedora's Sway config whole. Sway reads Fedora's snippets, then the image's, then yours in `~/.config/sway/config.d/*.conf`.
- keys: Fedora's defaults (close a window: Super+Shift+Q). Add your own in `~/.config/sway/config.d/`
- Fedora's snippets already do these: volume and brightness keys with a popup, screenshots, lock before sleep, session plumbing
- never write a whole `~/.config/sway/config`, because it drops Fedora's bar, polkit agent and session plumbing

## Bar, launcher, notifications

- bar: waybar, as Fedora ships it. Your own look goes in `~/.config/waybar/`
- app launcher: rofi
- notifications: dunst, which also shows the volume and brightness popup

## Screens

- layouts: kanshi (a tool that applies a screen layout by profile). Each person's profiles are in `~/.config/kanshi/config`. With no profile, sway places new screens itself
- laptop lid: the panel (`eDP-1`) turns off while the lid is closed, so a docked laptop uses only its external screens. To turn this off for one person, make `~/.config/sway/config.d/70-lid.conf` empty
- night light: the screen is warm from 20:00 to 07:00, from `wlsunset.service`. To change it for one person, write `~/.config/systemd/user/wlsunset.service.d/<name>.conf` with a `[Service]` section and one of these:
	- `Environment=WLSUNSET_ARGS="-l <latitude> -L <longitude>"`: follow the real sun
	- `Environment=WLSUNSET_ARGS="-S <sunrise> -s <sunset>"`: fixed times

## Input

- keyboard layout and touchpad: sway's `input` settings, in a drop-in
- key remaps (chord to chord, F-keys to media keys): keyd. It reads only `/etc/keyd/`, so a person's dotfiles carry the file and a `sudo` script installs it

## Sound

- PipeWire with WirePlumber
- `pavucontrol`: devices and levels
- `playerctl`: media keys
- codecs: the base has the free ones. Flatpak apps bring their own

## Appearance

- fonts from the base: Noto, Adwaita, Cantarell, and Font Awesome for the bar's icons
- a person's own fonts go in `~/.local/share/fonts`

## Apps

GUI apps are flatpaks, sorted into three bins: both of us, just me, just Jojo. [[monkeyflatpaks]] has the bins, the apps, and how each bin is installed.
- the "both" list installs at the first boot, from the image's recipe
- apps update separately from the image ([[machine]], Updates and rollback)
