---
type: component
description: "The Image layer of Monkeyworks: the base image it builds on and why, and which packages go in it. Reference before adding a package to the machine or changing the base."
status: planned
---
The Image layer of [[Monkeyworks]]: the OS as one image, built from a recipe, the same on every machine.
- [[#Repo]] where the recipe lives
- [[#Base]] what it builds on, and why
- [[#Packages]] what is in it, what goes in it, what stays out
- [[#Open]]

- [[Monkeyworks#Build]]: how the recipe becomes an image (BlueBuild)
- [[Monkeyworks#Update]]: how a machine gets the new image

---
## Repo

This folder is the repo: `github.com/matta-kelly/monkeyimage`, public.
- recipe: `recipes/recipe.yml`
- files copied into the image: `files/system/` → `/`
- CI: `.github/workflows/build.yml` (BlueBuild Action), paused until signing is set up
	- signing needs a cosign key pair: `cosign.pub` in the repo, the private key as the repo secret `SIGNING_SECRET`
- public, so nothing goes in that names my network or is personal: that goes in [[deeotee]] or the Jojo layer

## Base

`quay.io/fedora-ostree-desktops/sway-atomic:45`, official Fedora Sway Atomic.
- it adds about 180 packages over the bare atomic base
- the value is not Sway, it is the plumbing Fedora tests together: login, keyring, wifi, VPN, printing, audio, power
- Jojo needs all of that plumbing

| Rejected                         | Why                                                                     |
| -------------------------------- | ----------------------------------------------------------------------- |
| `ghcr.io/ublue-os/base-main`     | no Sway (uBlue builds no Sway image). Its extras are mostly codecs, and flatpaks bring their own |
| `ghcr.io/wayblueorg/sway`        | beta, only a `latest` tag, one Fedora release behind                    |
| `quay.io/fedora/fedora-bootc`    | server minimal: every desktop piece would be built by hand              |

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
	- GUI apps: Apps layer, flatpaks
	- CLI and dev tools: User layer ([[deeotee]]) or a distrobox
	- Arch tools that atomic replaces: yay, grub-btrfs, timeshift, stow, docker

## Open
- which added packages are not in the Fedora repos (likely keyd, swayosd, wl-gammarelay-rs): COPR or a build stage
- remove the replaced Fedora picks, or leave them installed and unused
