---
type: doc
description: "The desktop part of Monkeyworks: what you see and use. Sway and its keys, the bar, screens and the lid, night light, input and keyboard remaps, sound, appearance, and apps. Read when changing how the desktop looks or behaves."
status: active
---
What you see and use: Fedora's Sway desktop, as shipped, with a few shared defaults. Each person changes it for themselves with small files in `~/.config` ([[how-it-works#Config layering]]).
- [[#Sway]] the window manager, its keys, and how to add your own
- [[#Bar, launcher, notifications]] the pieces around the windows
- [[#Screens]] layouts, the laptop lid, night light
- [[#Input]] keyboard, remaps, touchpad
- [[#Sound]] audio and video
- [[#Appearance]] fonts and themes
- [[#Apps]] flatpaks, and how to add or remove one

- [[monkeyimage#Session]]: every desktop package in the image
- [[monkeyworks]]: the front page

---
## Sway

- Fedora's Sway config, whole. It reads Fedora's snippets, then the image's, then yours: `~/.config/sway/config.d/*.conf`
- keys: Fedora's defaults (close a window: Super+Shift+Q). Add your own in `~/.config/sway/config.d/`
- Fedora's snippets already do: volume and brightness keys with a popup, screenshots, lock before sleep, session plumbing
- never write a whole `~/.config/sway/config`: it drops Fedora's bar, polkit agent and session plumbing

## Bar, launcher, notifications

- bar: waybar, as Fedora ships it. Your own look goes in `~/.config/waybar/`
- app launcher: rofi
- notifications: dunst, which also shows the volume and brightness popup

## Screens

- layouts: kanshi, with each person's profiles in `~/.config/kanshi/config`. With none, sway places new screens itself
- laptop lid: the panel (`eDP-1`) turns off while the lid is closed, so a docked laptop uses only its external screens. An empty `~/.config/sway/config.d/70-lid.conf` turns that off for one person
- night light: warm from 20:00 to 07:00, from `wlsunset.service`. Change it for one person with `~/.config/systemd/user/wlsunset.service.d/<name>.conf`: `[Service]` and `Environment=WLSUNSET_ARGS="-l <latitude> -L <longitude>"` (the real sun) or `"-S <sunrise> -s <sunset>"`

## Input

- keyboard layout and touchpad: sway's `input` settings, in a drop-in
- key remaps (chord to chord, F-keys to media keys): keyd. It reads only `/etc/keyd/`, so a person's dotfiles carry the file and a `sudo` script installs it ([[per-host-system-config]])

## Sound

- PipeWire with WirePlumber; `pavucontrol` for devices and levels; `playerctl` for media keys
- codecs: the base has the free ones; flatpak apps bring their own

## Appearance

- fonts: Noto, Adwaita, Cantarell, and Font Awesome for the bar's icons, from the base
- a person's own fonts go in `~/.local/share/fonts`

## Apps

GUI apps are flatpaks, sorted into three bins: both of us, just me, just Jojo. [[monkeyflatpaks]] has the bins, the apps, and how each bin is installed.
- the "both" list installs at the first boot, from the image's recipe
- apps update separately from the image ([[machine#Updates and rollback]])
