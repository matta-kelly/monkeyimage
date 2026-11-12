---
type: component
description: "The image of Monkeyworks: what owns `/usr` and `/etc`. The base it builds on and why, which packages it holds by boot stage, and the config it ships. Reference before adding a package to the machine or changing the base."
status: planned
---
The image of [[monkeyworks]]: the system layer (`/usr` and `/etc`), built from one recipe and the same on every machine.
- Repo: where the recipe lives
- Base: what it builds on, and why
- What gets baked: the rule, by boot stage
- Packages: `/usr`, what it holds: by stage, then by job, each tagged by where it comes from
- Config: `/etc`, the config files it ships
- Not in the image: what goes somewhere else

- [[how-it-works]] (Build): how the recipe becomes an image (BlueBuild)
- [[machine]] (Updates and rollback): how a machine gets the new image

---
## Repo

The repo is `github.com/matta-kelly/monkeyimage`. It is public and made from [blue-build/template](https://github.com/blue-build/template).
- recipe: `recipes/recipe.yml`; it can split into more files ([from-file](https://blue-build.org/how-to/multiple-files/))
- files copied into the image: `files/system/` → `/`
- docs: `docs/`, the notes on how this machine works (this one among them)
	- copied into the image at `/usr/share/doc/monkeyworks/`, so every machine carries the docs that match it
	- public, so they name nothing on my network: a value like a server address is a placeholder
- checks: every change to the image is checked before it is built, so a broken change never reaches a machine
	- the check: `scripts/check.sh` (`just check`), the `checks` job in `.github/workflows/checks.yml`. Four sets: the note lint, dashes (no em-dash in a note), units (each unit the recipe enables has a committed file in `files/system/`, or comes from the base, a package or a stage, named in the script), and generate (`bluebuild generate`: the recipe is valid)
	- the gate: the ruleset on main requires `checks` on the exact commit, so `git land` waits for it, and main never takes a red change
- signing: the image is signed, so a machine only takes images that came from this repo
	- `cosign.pub` is in the repo
	- the private key is the repo secret `SIGNING_SECRET`, with a copy in Vaultwarden (`monkeyimage-cosign-signing-key`)
- CI: `.github/workflows/build.yml` (BlueBuild Action)
	- it builds on every push to any branch that changes a file other than `README.md` (a change to `docs/` rebuilds, since the docs are in the image), on pull requests, and daily at 06:00 UTC for Fedora's base updates
	- it pushes signed images to `ghcr.io/matta-kelly/monkeyimage`, public: `latest`, `<commit>-44`, and `pr-<n>-44` for pull requests (the suffix is the Fedora version)
	- update size: the image is not rechunked (split into layers that change independently). A rebuild with nothing changed still costs each machine about 248 MB. Rechunking measured worse (457 MB)
- an offline install ISO can be made from the image ([generate ISO](https://blue-build.org/how-to/generate-iso/))
- the repo is public, so nothing goes in that names our network or is personal: that goes in each person's [[dotfiles]]

## Base

The base is `quay.io/fedora-ostree-desktops/sway-atomic:44`, official Fedora Sway Atomic. It is pinned to the latest released Fedora: 45 is pre-release, and goes in when it is released.
- [Sway Atomic Home](https://fedoraproject.org/atomic-desktops/sway/), [Atomic Desktops docs](https://docs.fedoraproject.org/en-US/atomic-desktops/)
- size: 1423 packages in all, about 180 of them over the bare atomic base
- value: not Sway, but the plumbing Fedora tests together: login, keyring, wifi, VPN, printing, audio, power
- Jojo needs all of that plumbing

| Rejected                      | Why                                                                                                                  |
| ----------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| `ghcr.io/ublue-os/base-main`  | [Universal Blue](https://universal-blue.org/). No Sway (uBlue builds no Sway image). Its extras are mostly codecs, and flatpaks bring their own |
| [`ghcr.io/wayblueorg/sway`](https://github.com/wayblueorg/wayblue) | beta, only a `latest` tag, one Fedora release behind. Perhaps a reference design (it uses the same base image) |
| `quay.io/fedora/fedora-bootc` | server minimal: every desktop piece would be built by hand                                                           |

## What gets baked

The image holds what runs at the kernel, system and session stages ([[machine]], Booting). Each kind of thing has one home:

| Stage / kind                 | Goes in                           |
| ---------------------------- | --------------------------------- |
| kernel, system, session      | the image                         |
| apps                         | a flatpak ([[monkeyflatpaks]])    |
| project                      | its dev container                 |
| a CLI tool one person uses   | their [[dotfiles]] or a distrobox |
| config: stable defaults for every user | the image's `/etc` ([[how-it-works]], Config layering) |
| config: identity, or changed often | the person's `~`, from their [[dotfiles]] |

- Jojo gets the same image, so anything baked in is hers too
- each user can override shared config in their own `~`: a same-named file wins
- an image change means a rebuild and a reboot, so the image holds only what is stable

## Packages

The packages are in `/usr`. Rows are boot stages. Buckets are the [Arch General recommendations](https://wiki.archlinux.org/title/General_recommendations) sections, plus the *UNIX and Linux System Administration Handbook*'s sections where Arch has none (storage, virtualization). Only packages that are a decision or that I touch are listed. The rest of the 1423 are libraries and support (`rpm -qa` in the base image).

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
Runs as root for every user, from `sysinit` to `multi-user` (systemd targets: boot steps)
- system administration
	- systemd `base`
	- polkit `base`
	- SELinux `base`
	- sssd `base`
	- systemd-homed `base`
	- zram-generator: compressed swap in RAM `base`
	- git: Bootstrap clones the dotfiles with it, before the User layer exists `added`
	- chezmoi: Bootstrap applies each user's dotfiles with it, so every user (Jojo too) starts from one command `added`
	- rbw: Bitwarden CLI with an agent that holds the unlocked vault; each user's dotfiles read Vaultwarden through it. Not Bitwarden's own `bw`: Fedora does not package it, and its binary is 143 MB `added`
	- gh: GitHub CLI; `gh auth login`, and git's credential helper for GitHub `added`
	- restic: each user's nightly backup ([[backup]]) `added`
	- pi: an AI agent in the terminal, for every user. Each person's settings and key are in `~/.pi/agent/`, from their dotfiles `added`
		- not in Fedora: the upstream release binary, from the recipe's `pi` stage, installed in `/usr/lib/pi` with `/usr/bin/pi` linked to it
		- not pinned: each build takes the latest release and checks it against the release's own `SHA256SUMS`, so the daily build keeps it current. `pi --version` says which one a machine has, and a rollback takes pi back with the image
		- it cannot update itself: `/usr` is read-only
		- its extension packages (`pi install npm:...`, or `packages` in a person's `~/.pi/agent/settings.json`) install with npm, so the image carries `nodejs-npm` `added`
	- monke: the CLI of the machine (`status`, `update`, `rollback`, `help`, `init`), from its own repo `added`
		- not pinned: the recipe's `monke` stage takes monke's latest release at each build, checked against its `SHA256SUMS`
		- it brings `/etc/monke/config`, its prompts in `/usr/share/monke/`, and `monke-model.service`, which is enabled: on the first boot that is online it downloads `help`'s local model (2 GB) to `/var/lib/monke/models/`, then does nothing
	- sddm-astronaut-theme: the login screen's look, in `/usr/share/sddm/themes/`, with its fonts in `/usr/share/fonts/sddm-astronaut-theme/` `added`
		- not in Fedora: the recipe's `sddm-theme` stage takes it from GitHub, pinned to a commit and its sha256, since it has no releases. It sets the Pixel Sakura (static) preset
		- `qt6-qtmultimedia` and `qt6-qtvirtualkeyboard`: what the theme loads `added`
	- llama-server: runs `monke help`'s local model on the CPU, only while a local chat is open `added`
		- not Fedora's `llama-cpp`: that package pulls the AMD GPU stack, 1.3 GB. llama.cpp's own CPU build is 23 MB, in `/usr/lib/llama.cpp` with `/usr/bin/llama-server` linked to it
		- pinned in the recipe's `llama-cpp` stage to a build number and its sha256, since llama.cpp releases many times a day. To bump, change both together
	- rescue kit: for a sick machine, with no container or dotfiles needed. Dev tools (strace, perf) go in a toolbox
		- htop: it's slow `added`
		- lm_sensors: it's hot `added`
		- ncdu: the disk is full `added`
		- fastfetch: what this machine is at a glance: the OS, kernel, hardware, memory and disk `added`
- security
	- firewalld: enabled, zone `public`, which lets in only ssh, mdns and dhcpv6. Kept as shipped: nothing needs to reach in, the tailnet included `base`
		- the zone `home` adds LocalSend, for networks a person marks as trusted ([[machine]], Networking)
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
	- tailscale: `tailscaled.service` is enabled; a machine joins the mesh with `tailscale up` ([[setup]]) `added`
- power management
	- tuned + tuned-ppd: power profiles `base`
	- thermald `base`
	- upower `base`. Its shipped `UPower.conf` is the safety net: `CriticalPowerAction=Auto` suspends at 2%. Kept as shipped. A drop-in (an extra config file that overrides it) in `/etc/UPower/UPower.conf.d/` with `CriticalPowerAction=PowerOff` would shut down instead
- input devices
	- keyd: key remapping per keyboard (chord to chord, F-keys to media keys), which xkb can't do `added`
		- not in Fedora: built from the upstream release in a build stage, not a COPR. It is a root daemon that sees every key
		- pinned to v2.6.0, with the tarball's sha256, in the recipe's `keyd` stage. To bump, change the version and the sha256 together (`curl -fsSL <tarball URL> | sha256sum`)
		- `keyd.service` is enabled. With no config, keyd grabs no keyboard
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
	- guest agents, for running as a VM: enabled, but each starts only inside its own VM `base`
		- open-vm-tools
		- virtualbox-guest-additions
		- qemu-guest-agent
		- spice-vdagent
- multimedia
	- rtkit: realtime audio priority `base`

### Session
Runs at `graphical`: SDDM login, then the user's own manager, inside Sway
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
		- kanshi `base`. Started by Fedora's `kanshi.service` for a user with profiles (Config)
	- night light
		- wlsunset `base`. Started by the image's `wlsunset.service` (Config)
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

The config is in `/etc`. The image ships three things there: config files from `files/system/etc/` in the repo, the unit links the recipe's `systemd` module makes (a unit: a systemd service or timer), and what a build stage installs.
- `rpm-ostreed.conf`: `AutomaticUpdatePolicy=stage`. An update downloads and stages the new image; it takes over at the next reboot ([[machine]], Updates and rollback)
- `rpm-ostreed-automatic.timer`: a unit link, enabled by the `systemd` module. It runs the policy once a day
- `flatpak-update.timer`: a system unit and a user unit of the same name, each enabled by the `systemd` module
	- the system one updates the system flatpaks each day at 03:00, the user one each user's own flatpaks at 03:30
	- a run missed while the machine was off or asleep happens when it is back, and a failed run tries again for about half an hour
	- an app runs its new version from its next start
	- a user changes the time with a drop-in in `~/.config/systemd/user/flatpak-update.timer.d/`, or turns theirs off with `systemctl --user mask flatpak-update.timer`
- `keyd.service`: a unit link, enabled by the `systemd` module
- `battery-warn.timer`: a user unit, enabled for every user by the `systemd` module
	- in the graphical session, every minute, `/usr/bin/battery-warn` asks UPower and warns once at 20% and once at 10%, through dunst
	- a user changes the levels with a drop-in in `~/.config/systemd/user/battery-warn.service.d/`, or turns it off with `systemctl --user mask battery-warn.timer`
- `wlsunset.service`: a user unit, enabled for every user by the `systemd` module
	- night light from 20:00 to 07:00 (`WLSUNSET_ARGS`)
	- a user sets a location or other times with a drop-in in `~/.config/systemd/user/wlsunset.service.d/`; a location stays out of the image, which is public
- `kanshi.service`: Fedora's user unit, enabled for every user by the `systemd` module
	- the image's drop-in `kanshi.service.d/50-user-config.conf` starts it only when the user has `~/.config/kanshi/config`
	- the profiles are each user's own; with none, sway places new screens itself
- `restic-backup.timer`, `restic-prune.timer`: user units, enabled for every user by the `systemd` module ([[backup]])
	- backup: each night at 02:00, restic backs up `~`
	- prune: each Sunday, restic removes old backups, keeping 7 daily, 4 weekly and 6 monthly
	- a run missed while the machine was off or asleep happens when it is back
	- they run only while the user is logged in, and only for a user with `~/.config/restic/env` (the repository's address and keys) and `~/.config/restic/password`
	- a failed run tries again for about half an hour, so a laptop that just woke can reach wifi
	- a user changes the time with a drop-in in `~/.config/systemd/user/restic-backup.timer.d/`
- `restic-failed.service`: a user unit. A failed backup or prune starts it, and it warns through dunst
- `restic/excludes`: what the backup skips in `~`: things a program can make again, or that restic cannot read
- `/etc/keyd/`: empty, from the keyd stage
	- keep it: keyd's source exits at startup when the directory is missing
	- per-host config goes in it, outside the image: the owner's dotfiles carry the file, and a `sudo` script installs it
- `sway/config.d/70-lid.conf`: the laptop panel (`eDP-1`) turns off while the lid is closed, so a docked machine uses only its external screens. Undocked, logind still sleeps on lid close. Fedora's sway config reads `/etc/sway/config.d/`; a user's same-named file in `~/.config/sway/config.d/` overrides it

## Not in the image

- GUI apps: flatpaks, installed at boot. The recipe carries the "both" list: [[monkeyflatpaks]]
- CLI and dev tools: each person's [[dotfiles]] or a distrobox, so no tmux, vim, fzf in the image
- VMs (libvirt, qemu-kvm, virt-manager): added when a real need shows up, such as another OS or testing images. A project's own environment is a dev container
- Arch tools that Atomic replaces: yay, grub-btrfs, timeshift, stow, docker
- batteries not taken
	- full codecs (RPM Fusion `ffmpeg`, `mesa-va-drivers-freeworld`): only host apps need them, flatpaks bring their own
	- udev rules for solaar, openrgb, ratbag: no such hardware
	- lshw: not needed
