---
type: component
description: "The Image layer of Monkeyworks: the base image it builds on and why, and which packages go in it. Reference before adding a package to the machine or changing the base."
status: planned
---
The Image layer of [[Monkeyworks]]: the OS as one image, built from a recipe, the same on every machine.
- [[#Repo]] where the recipe lives
- [[#Base]] what it builds on, and why
- [[#Packages]] what is in it, what goes in it, what stays out
- [[#Batteries]] uBlue's extras, not chosen yet

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
	- remove the replaced Fedora picks, or leave them installed and unused

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
- it adds about 180 packages over the bare atomic base
- the value is not Sway, it is the plumbing Fedora tests together: login, keyring, wifi, VPN, printing, audio, power
- Jojo needs all of that plumbing

| Rejected                      | Why                                                                                                                  |
| ----------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| `ghcr.io/ublue-os/base-main`  | [Universal Blue](https://universal-blue.org/). No Sway (uBlue builds no Sway image). Its extras are mostly codecs, and flatpaks bring their own                     |
| [`ghcr.io/wayblueorg/sway`](https://github.com/wayblueorg/wayblue) | beta, only a `latest` tag, one Fedora release behind -->perhaps look at as a reference design (uses same base image) |
| `quay.io/fedora/fedora-bootc` | server minimal: every desktop piece would be built by hand                                                           |

## Packages

- From the base, already what I use
	- sway, swaybg, swayidle, swaylock, waybar, foot, rofi, grim, slurp, brightnessctl, blueman, Thunar, imv, wev, xdg-desktop-portal-wlr
- From the base, plumbing
	- SDDM, lxqt-policykit, oo7 keyring + PAM (unlocks at login), NetworkManager applet + VPN plugins, pavucontrol, playerctl, printing, fprintd, tuned power profiles, gvfs/smb, sway-config-fedora, sway-systemd
- From the base, Fedora picks I replace
	- dunst → mako
	- kanshi → shikane
	- wlsunset → gammastep
- Added by the recipe
	- desktop: kitty, mako, swayosd, satty, wf-recorder, cliphist, gammastep, wl-gammarelay-rs, shikane, keyd
	- system: tailscale, libvirt, qemu, virt-manager
- Not in the image
	- GUI apps: flatpaks, installed at boot. The recipe carries the "both" list: [[monkeyflatpaks]]
	- CLI and dev tools: User layer ([[deeotee]]) or a distrobox
	- Arch tools that atomic replaces: yay, grub-btrfs, timeshift, stow, docker

## Batteries

uBlue's extras, checked against the base. Not in the recipe until chosen.
- Already in the base: wl-clipboard, wireguard-tools, toolbox, libfido2, libheif, libcamera, zstd, nvme-cli, ffmpeg-free
- Likely yes
	- distrobox: Bootstrap uses `distrobox-assemble`
	- just: runs the `justfiles` commands
- Maybe, if the need is real
	- pam-u2f, pamu2fcfg, yubikey-manager: log in or sudo with a security key
	- heif-pixbuf-loader, ffmpegthumbnailer: thumbnails in Thunar for phone photos (HEIC) and videos. Likely matters for Jojo
	- smartmontools, lshw: diagnose the machine
	- full codecs (RPM Fusion `ffmpeg`, `mesa-va-drivers-freeworld`): Fedora's `ffmpeg-free` has no H.264 or HEVC. Only host apps need them; flatpaks bring their own
	- hardware udev rules (solaar, openrgb, ratbag): only for that hardware
- No: htop, tmux, vim, fzf. CLI tools go in the User layer or a distrobox
