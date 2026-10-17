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
	- nada

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

Tags: `base` in the base image, `added` by the recipe.

### Kernel
Firmware, bootloader, kernel, initramfs
- booting
	- kernel `base`
	- grub2 + shim: UEFI bootloader `base`
	- bootupd: updates the bootloader `base`
	- plymouth: boot splash `base`
- drivers and firmware
	- linux-firmware `base`
	- amd-gpu-firmware `base`
	- amd-ucode-firmware: CPU microcode `base`
	- mesa: GPU drivers `base`
	- fwupd: firmware updates `base`
- the image itself
	- ostree `base`
	- rpm-ostree `base`
	- bootc `base`

### System
`sysinit` → `multi-user`, root, for every user
- system administration
	- systemd `base`
	- polkit `base`
	- SELinux `base`
	- sssd `base`
	- systemd-homed `base`
	- zram-generator: compressed swap in RAM `base`
- security
	- firewalld: enabled, zone `public`: in only ssh, mdns, dhcpv6. Kept as shipped: nothing needs to reach in, the tailnet included `base`
	- audit `base`
	- fprintd + fprintd-pam: fingerprint login `base`
	- pam-u2f, pamu2fcfg: log in or sudo with a YubiKey, once set up in PAM `added`
	- yubikey-manager: `ykman`, configures the YubiKey `added`
- package management
	- flatpak `base`
	- podman `base`
	- toolbox `base`
	- distrobox: Bootstrap uses `distrobox-assemble` `added`
	- just: runs the `justfiles` commands `added`
- networking
	- NetworkManager `base`
	- wpa_supplicant: wifi `base`
	- ModemManager: mobile broadband `base`
	- systemd-resolved: DNS `base`
	- chrony: time `base`
	- avahi: local discovery `base`
	- openvpn `base`
	- wireguard-tools `base`
	- tailscale `added`
- power management
	- tuned + tuned-ppd: power profiles `base`
	- thermald `base`
	- upower `base`
- input devices
	- keyd: key remapping per keyboard (chord to chord, F-keys to media keys), which xkb can't do `added`
		- not in Fedora: built from the upstream release in a build stage, not a COPR. It is a root daemon that sees every key
		- its config is per keyboard and per machine, so it is not in the image's `/etc`
- printing
	- cups `base`
	- cups-browsed `base`
	- ipp-usb `base`
- storage
	- udisks2 `base`
	- lvm2 `base`
	- mdadm `base`
	- xfsprogs `base`
	- fstrim timer `base`
	- smartmontools: disk health `added`
- virtualization
	- libvirt `added`
	- qemu `added`
	- virt-manager `added`
	- guest agents, for running as a VM: enabled, but each starts only inside its own VM `base`
		- open-vm-tools
		- virtualbox-guest-additions
		- qemu-guest-agent
		- spice-vdagent
- multimedia
	- rtkit: realtime audio priority `base`

### Session
`graphical`, SDDM login, then my user manager, inside Sway
- graphical user interface
	- display manager
		- sddm `base`
	- compositor
		- sway `base`
		- sway-config-fedora `base`
		- sway-systemd `base`
		- swaybg `base`
		- swayidle `base`
		- swaylock `base`
	- bar and launcher
		- waybar `base`
		- rofi `base`
	- terminal
		- foot `base`
	- notifications
		- dunst `base`. Also the volume and brightness popup: progress-bar notifications, no OSD package
	- outputs
		- kanshi `base`
	- night light
		- wlsunset `base`
	- screenshots and recording
		- grim `base`
		- slurp `base`
		- wf-recorder: screen recording `added`
	- clipboard
		- wl-clipboard `base`
	- portals
		- xdg-desktop-portal-wlr `base`
		- xdg-desktop-portal-gtk `base`
		- oo7-portal `base`
	- polkit agent
		- lxqt-policykit `base`
	- keyring
		- oo7-daemon `base`
		- pam_oo7: unlocks the keyring at login `base`
- multimedia
	- pipewire `base`
	- wireplumber `base`
	- pipewire-pulseaudio `base`
	- gstreamer, free plugins `base`
	- ffmpeg-free `base`
	- pavucontrol `base`
	- playerctl `base`
- networking
	- network-manager-applet `base`
	- VPN plugins: openvpn, openconnect `base`
	- blueman `base`
	- bluez `base`
- files
	- Thunar `base`
	- tumbler: thumbnails `base`
	- gvfs + gvfs-smb `base`
	- heif-pixbuf-loader: thumbnails for phone photos, likely matters for Jojo `added`
	- ffmpegthumbnailer: thumbnails for videos `added`
- appearance
	- fonts: Noto, Adwaita, Cantarell `base`
	- Font Awesome: waybar icons `base`
- small tools
	- imv: image viewer `base`
	- wev: shows input events `base`
	- brightnessctl `base`

## Config

In `/etc`. Config files the image ships: `files/system/etc/` in the repo. None yet.
- planned: logind lid-close (clamshell), geoclue (location for the night light)

## Not in the image

- GUI apps: flatpaks, installed at boot. The recipe carries the "both" list: [[monkeyflatpaks]]
- CLI and dev tools: [[deeotee]] or a distrobox. So no htop, tmux, vim, fzf in the image
- Arch tools that Atomic replaces: yay, grub-btrfs, timeshift, stow, docker
- batteries not taken
	- full codecs (RPM Fusion `ffmpeg`, `mesa-va-drivers-freeworld`): only host apps need them, flatpaks bring their own
	- udev rules for solaar, openrgb, ratbag: no such hardware
	- lshw: not needed
