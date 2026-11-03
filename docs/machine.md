---
type: doc
description: "The computer part of Monkeyworks: what is the same for everyone and comes from the image. Booting, updates and rollback, users and login, services, networking, power, storage, printing. Read when one of these misbehaves, or before changing one."
status: active
---
The computer: shared, the same for everyone, set by the image. A change here is a change to the image, so it reaches every machine.
- [[#Booting]] how the machine comes up, stage by stage
- [[#Updates and rollback]] how a new image arrives, and how to go back
- [[#Users and login]] accounts, the login screen, sudo
- [[#Services]] what runs in the background, and how to turn one off
- [[#Networking]] wifi, the firewall, the mesh
- [[#Power]] battery, suspend, power profiles
- [[#Storage]] disks and their health
- [[#Printing]] printers

- [[monkeyimage]]: every package and config file the image holds
- [[monkeyworks]]: the front page

---
## Booting

When things run. Basis: the real order the machine comes up in; systemd names the stages as targets (`sysinit`, `basic`, `multi-user`, `graphical`).
- firmware → bootloader → kernel → initramfs → systemd → system services → login → session → apps
- read as a grid: stages as rows, kernel pillars as columns

### Rows: stages
Coarse stages, deepest first. The deeper a piece sits, the more it belongs in the image, the more it reaches Jojo, and the harder a mistake is to undo.
1. kernel: firmware, bootloader, kernel, initramfs. Drivers, kernel args
2. system: `sysinit` → `multi-user`. Root, system services, `/etc`. For every user
3. session: `graphical`, login, then the user's own manager. Inside Sway, runs as the user
4. apps: on demand. Flatpaks in a sandbox
5. project: on demand. One repo's toolchain, in its container

- the split comes from systemd: a system manager (boot, root) and a user manager (the session)
- one package can have parts at different stages: swayosd has a backend (system) and a popup client (session)
- a stage is where a piece runs, a path is where it lives
	- kernel, system → `/usr`, `/etc`
	- session → `/usr` (the binaries) + `~` (their config)
	- apps → `/var/lib/flatpak`
	- project → `~/.local/share/containers`

### Columns: pillars
- the split comes from the Linux source tree: `kernel/` (processes), `mm/` (memory), `fs/`, `drivers/`, `net/`, `security/`
- one column runs through every row. Network: driver (kernel), NetworkManager (system), tray applet (session), Proton VPN (app)
- three carry the image work
	- files: on Atomic the filesystem is the design ([[monkeyworks#Files on Atomic]])
	- processes: system services vs user services, the stage split
	- security: root vs the user, and the flatpak sandbox

---
## Updates and rollback

Image in ghcr → machine. Two loops that meet only at the registry: GitHub builds, the machine pulls; nothing pushes to it.
- build side: GitHub builds `latest` on every push to main and daily at 06:00 UTC, so Fedora's base fixes are baked in even when the recipe is unchanged
- machine side: `rpm-ostreed-automatic.timer` with `AutomaticUpdatePolicy=stage`. Once a day it downloads the changed layers and stages the new image as a second deployment; it takes over at the next reboot, whenever the user chooses ([rpm-ostree](https://coreos.github.io/rpm-ostree/), [bootc](https://bootc-dev.github.io/bootc/), [Fedora bootc](https://docs.fedoraproject.org/en-US/bootc/))
	- the base ships both update timers disabled and no policy. The image turns this one on and sets the policy ([[monkeyimage#Config]])
	- not `bootc-fetch-apply-updates.timer`: it applies and reboots by itself every 8 hours. Right for a server, wrong for a laptop in use
	- by hand: `rpm-ostree upgrade`, then reboot. `rpm-ostree rollback` goes back one deployment
- apps update separately, and nothing updates them yet: `flatpak update` by hand ([[jojo-onboard]] holds the open question)
- update size: a stage downloads the layers that changed. Fedora chunks the base by package; our own layers are rebuilt every day, about 248 MB even with nothing changed. Rechunking measured worse. Options: [[smaller-image-updates]]
- `/etc` gets a 3-way merge: the old image's defaults, the new image's defaults, local changes
- rollback: the previous deployment is the second entry in the boot menu
	- the menu is hidden while boots succeed. `grub-boot-success.timer` marks a boot good after a couple of minutes logged in; when a boot never gets there, the menu shows on the next boot, so the previous deployment is one pick away
	- no greenboot: its default checks need the network at boot and reboot the machine by themselves, wrong for a laptop
- so a change to the recipe reaches every machine with no hands on it, on its next reboot, Jojo's included
- the dazoo bootc nodes run the apply-and-reboot version of this loop: [[c-devops]]

---
## Users and login

- login screen: SDDM, as Fedora ships it. How it should look and behave is open: [[login-screen]]
- accounts: one per person. Each person's setup comes through [[setup]]
- sudo and login with a YubiKey: `pam-u2f` and `pamu2fcfg` are in the image; each key is set up in PAM per machine
- fingerprint login: `fprintd`, from the base

---
## Services

What runs in the background. System services run as root for the whole machine; user services run in each person's session.
- system, enabled by the image: `rpm-ostreed-automatic.timer` (updates), `keyd.service` (key remaps), `tailscaled.service` (the mesh)
- user, enabled for everyone by the image: `battery-warn.timer`, `wlsunset.service` (night light), `kanshi.service` (screen layouts), `restic-backup.timer` and `restic-prune.timer` (backup)
- what each does and how to change it: [[monkeyimage#Config]]
- turn a user service off for one person: `systemctl --user mask <unit>`. After a drop-in change: `systemctl --user daemon-reload`, then restart the unit

---
## Networking

- wifi and wired: NetworkManager, with its tray applet in the session
- firewall: firewalld, zone `public`, as shipped: in only ssh, mdns, dhcpv6
- the mesh: tailscale, joined once per machine during [[setup]]. The vault is on the mesh
- VPN: NetworkManager's OpenVPN and OpenConnect plugins. Proton VPN is an app for me only: [[matt-extras]]

---
## Power

- power profiles: tuned with tuned-ppd; thermald for heat
- battery warning: at 20% and 10%, from `battery-warn.timer`. Change the levels for one person with `~/.config/systemd/user/battery-warn.service.d/<name>.conf`: `[Service]` and `Environment=BATTERY_WARN_LOW=<n> BATTERY_WARN_CRITICAL=<n>`
- at 2% UPower suspends the machine (Fedora's `CriticalPowerAction=Auto`)
- lid: logind sleeps on lid close, and stays awake when docked

---
## Storage

- disks: udisks2 mounts removable drives; `fstrim.timer` trims SSDs
- disk health: `smartctl` (smartmontools)
- a full disk: `ncdu`
- your files are backed up every night: [[you#Backup]]

---
## Printing

- CUPS, as Fedora ships it, with `cups-browsed` and `ipp-usb` to find printers on the network and over USB
