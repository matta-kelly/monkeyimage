---
type: component
description: "The image of Monkeyworks: what owns `/usr` and `/etc`. The base it builds on and why, which packages it holds by boot stage, and the config it ships. Reference before adding a package to the machine or changing the base."
status: planned
---
The image of [[Monkeyworks]]: `/usr` and `/etc`, built from one recipe, the same on every machine.
- [[#Repo]] where the recipe lives
- [[#Base]] what it builds on, and why
- [[#What gets baked]] the rule, by boot stage
- [[#Packages]] `/usr`, what it holds: by stage, then by job, each tagged by where it comes from
- [[#Config]] `/etc`, the config files it ships
- [[#Not in the image]] what goes somewhere else

- [[Monkeyworks#Build]]: how the recipe becomes an image (BlueBuild)
- [[Monkeyworks#Update]]: how a machine gets the new image

### Desk
- open questions
	- added packages not in the Fedora 45 repos: how each gets in (all others are in `fedora`, tailscale included)
		- swayosd: COPR `erikreider/swayosd`, the author's own
		- keyd: COPR `alternateved/keyd` or `meeuw/keyd`, both 2.6.0
		- satty: only personal Hyprland COPRs, not on Flathub. Build stage (cargo), or swappy (in Fedora)
		- shikane: no COPR builds for Fedora 45. Build stage (cargo), or kanshi (in the base)
		- wl-gammarelay-rs: one small personal COPR. Build stage (cargo). The bluelight scripts and units in [[deeotee]] need it
	- remove the replaced base picks, or leave them installed and unused
	- night light: gammastep and wl-gammarelay-rs do one job. Keep one?
	- the base enables VM guest agents (open-vm-tools, VirtualBox, qemu, spice): leave them, or disable on hardware?
	- the base enables firewalld: keep it as is next to tailscale, or configure it?
	- `battery?` items: decide each

---
## Repo

This folder is the repo: `github.com/matta-kelly/monkeyimage`, public, made from [blue-build/template](https://github.com/blue-build/template).
- recipe: `recipes/recipe.yml`; it can split into more files ([from-file](https://blue-build.org/how-to/multiple-files/))
- files copied into the image: `files/system/` → `/`
- CI: `.github/workflows/build.yml` (BlueBuild Action), paused until signing is set up
	- signing needs a cosign key pair: `cosign.pub` in the repo, the private key as the repo secret `SIGNING_SECRET`
- an offline install ISO can be made from the image ([generate ISO](https://blue-build.org/how-to/generate-iso/))
- public, so nothing goes in that names my network or is personal: that goes in [[deeotee]] or the Jojo layer

## Base

`quay.io/fedora-ostree-desktops/sway-atomic:45`, official Fedora Sway Atomic.
- [Sway Atomic Home](https://fedoraproject.org/atomic-desktops/sway/), [Atomic Desktops docs](https://docs.fedoraproject.org/en-US/atomic-desktops/)
- 1423 packages in all, about 180 of them over the bare atomic base
- the value is not Sway, it is the plumbing Fedora tests together: login, keyring, wifi, VPN, printing, audio, power
- Jojo needs all of that plumbing

| Rejected                      | Why                                                                                                                  |
| ----------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| `ghcr.io/ublue-os/base-main`  | [Universal Blue](https://universal-blue.org/). No Sway (uBlue builds no Sway image). Its extras are mostly codecs, and flatpaks bring their own                     |
| [`ghcr.io/wayblueorg/sway`](https://github.com/wayblueorg/wayblue) | beta, only a `latest` tag, one Fedora release behind -->perhaps look at as a reference design (uses same base image) |
| `quay.io/fedora/fedora-bootc` | server minimal: every desktop piece would be built by hand                                                           |

## What gets baked

The image holds what runs at the kernel, system and session stages ([[Monkeyworks#Boot sequence]]).

| Stage / kind                 | Goes in                           |
| ---------------------------- | --------------------------------- |
| kernel, system, session      | the image                         |
| apps                         | a flatpak ([[monkeyflatpaks]])    |
| project                      | its dev container                 |
| a CLI tool only I use        | [[deeotee]] or a distrobox        |

- Jojo gets the same image: anything baked in is hers too
- an image change means a rebuild and a reboot: the image holds what is stable

## Packages

In `/usr`. Rows: boot stage. Buckets: the [Arch General recommendations](https://wiki.archlinux.org/title/General_recommendations) sections, plus [[Monkeyworks#ULSAH outline]] where Arch has none (storage, virtualization). Only packages that are a decision or that I touch; the rest of the 1423 are libraries and support (`rpm -qa` in the base image).

Tags: `base` in the base image, `added` by the recipe, `battery?` not chosen yet, `not in Fedora` needs a source (Desk).

### Kernel
Firmware, bootloader, kernel, initramfs
- booting: kernel, grub2 + shim (UEFI), bootupd (updates the bootloader), plymouth (boot splash) `base`
- drivers and firmware: linux-firmware, amd-gpu-firmware, amd-ucode-firmware (microcode), mesa (GPU), fwupd (firmware updates) `base`
- the image itself: ostree, rpm-ostree, bootc `base`

### System
`sysinit` → `multi-user`, root, for every user
- system administration: systemd, polkit, SELinux, sssd, systemd-homed, zram-generator (compressed swap in RAM) `base`
- security: firewalld (enabled), audit, fprintd + fprintd-pam (fingerprint) `base`
	- pam-u2f, pamu2fcfg, yubikey-manager (log in or sudo with a security key) `battery?`
- package management: flatpak, podman, toolbox `base`
	- distrobox (Bootstrap uses `distrobox-assemble`), just (runs the `justfiles` commands) `battery?`, likely yes
- networking: NetworkManager, wpa_supplicant, ModemManager, systemd-resolved, chrony (time), avahi (local discovery), openvpn, wireguard-tools `base`
	- tailscale `added`
- power management: tuned + tuned-ppd (power profiles), thermald, upower `base`
- input devices: keyd `added` `not in Fedora`
	- udev rules for solaar, openrgb, ratbag `battery?`, only with that hardware
- printing: cups, cups-browsed, ipp-usb `base`
- storage: udisks2, lvm2, mdadm, xfsprogs, fstrim timer `base`
	- smartmontools, lshw (diagnose the machine) `battery?`
- virtualization: libvirt, qemu, virt-manager `added`
	- guest agents, for running as a VM: open-vm-tools, virtualbox-guest-additions, qemu-guest-agent, spice-vdagent `base`, enabled
- multimedia: rtkit (realtime audio priority) `base`

### Session
`graphical`, SDDM login, then my user manager, inside Sway
- graphical user interface
	- display manager: sddm `base`
	- compositor: sway, sway-config-fedora, sway-systemd, swaybg, swayidle, swaylock `base`
	- bar and launcher: waybar, rofi `base`
	- terminal: foot `base`, kitty `added`
	- notifications: dunst `base` → mako `added`
	- outputs: kanshi `base` → shikane `added` `not in Fedora`
	- night light: wlsunset `base` → gammastep `added`, wl-gammarelay-rs `added` `not in Fedora`
	- on-screen display: swayosd `added` `not in Fedora`
	- screenshots and recording: grim, slurp `base`; satty `added` `not in Fedora`; wf-recorder `added`
	- clipboard: wl-clipboard `base`; cliphist `added`
	- portals: xdg-desktop-portal-wlr, xdg-desktop-portal-gtk, oo7-portal `base`
	- polkit agent: lxqt-policykit `base`
	- keyring: oo7-daemon + pam_oo7 (unlocks at login) `base`
- multimedia: pipewire, wireplumber, pipewire-pulseaudio, gstreamer (free plugins), ffmpeg-free, pavucontrol, playerctl `base`
	- full codecs (RPM Fusion `ffmpeg`, `mesa-va-drivers-freeworld`): `ffmpeg-free` has no H.264 or HEVC. Only host apps need them; flatpaks bring their own `battery?`
- networking: network-manager-applet + VPN plugins (openvpn, openconnect), blueman, bluez `base`
- files: Thunar, tumbler (thumbnails), gvfs + gvfs-smb `base`
	- heif-pixbuf-loader, ffmpegthumbnailer (thumbnails for phone photos and videos, likely matters for Jojo) `battery?`
- appearance: fonts: Noto, Adwaita, Cantarell, Font Awesome (waybar icons) `base`
- small tools: imv, wev, brightnessctl `base`

## Config

In `/etc`. Config files the image ships: `files/system/etc/` in the repo. None yet.
- planned: keyd layout, logind lid-close (clamshell), geoclue (location for the night light)

## Not in the image

- GUI apps: flatpaks, installed at boot. The recipe carries the "both" list: [[monkeyflatpaks]]
- CLI and dev tools: [[deeotee]] or a distrobox. So no htop, tmux, vim, fzf in the image
- Arch tools that Atomic replaces: yay, grub-btrfs, timeshift, stow, docker
