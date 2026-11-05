---
type: doc
description: "The computer part of Monkeyworks: what is the same for everyone and comes from the image. Booting, updates and rollback, users and login, services, networking, power, storage, printing. Read when one of these misbehaves, or before changing one."
status: active
---
The computer: what is the same for everyone, set by the image (the OS build every machine runs). A change here is a change to the image, so it reaches every machine.
- Booting: how the machine comes up, stage by stage
- Updates and rollback: how a new image arrives, and how to go back
- Users and login: accounts, the login screen, sudo
- Services: what runs in the background, and how to turn one off
- Networking: wifi, the firewall, the mesh
- Power: battery, suspend, power profiles
- Storage: disks and their health
- Printing: printers

- [[monkeyimage]]: every package and config file the image holds
- [[monkeyworks]]: the front page

---
## Booting

Booting: the real order in which the machine comes up. systemd (the init system, the first process after the kernel) names the stages as targets: `sysinit`, `basic`, `multi-user`, `graphical`.
- firmware → bootloader → kernel → initramfs → systemd → system services → login → session → apps
- read it as a grid: stages are the rows, kernel pillars are the columns

### Rows: stages
Stage: a coarse step of the boot, where a piece runs. The list goes deepest first. The deeper a piece sits, the more it belongs in the image, the more it reaches Jojo, and the harder a mistake is to undo.
1. kernel: firmware, bootloader, kernel, initramfs. Drivers, kernel args
2. system: `sysinit` → `multi-user`. Root, system services, `/etc`. For every user
3. session: `graphical`, login, then the user's own manager. Inside Sway, runs as the user
4. apps: on demand. Flatpaks in a sandbox
5. project: on demand. One repo's toolchain, in its container

The split between system and session comes from systemd, which has two managers.
- the system manager: boot, root
- the user manager: the session

One package can have parts at different stages. swayosd has a backend (system) and a popup client (session).

A stage is where a piece runs. A path is where it lives.
- kernel, system → `/usr`, `/etc`
- session → `/usr` (the binaries) + `~` (their config)
- apps → `/var/lib/flatpak`
- project → `~/.local/share/containers`

### Columns: pillars
Pillar: a kernel subsystem that cuts across the stages. The split comes from the Linux source tree: `kernel/` (processes), `mm/` (memory), `fs/`, `drivers/`, `net/`, `security/`.
- one column runs through every row. Network: driver (kernel), NetworkManager (system), tray applet (session), Proton VPN (app)
- three pillars carry the image work
	- files: on Atomic the filesystem is the design ([[how-it-works]], Files on Atomic)
	- processes: system services vs user services, the stage split
	- security: root vs the user, and the flatpak sandbox

---
## Updates and rollback

Update path: image in ghcr (GitHub's container registry) → machine. Two loops meet only at the registry. GitHub builds, the machine pulls, and nothing pushes to the machine.

### Build side
GitHub builds `latest` on every push to main and daily at 06:00 UTC, so Fedora's base fixes are baked in even when the recipe is unchanged.

### Machine side
`rpm-ostreed-automatic.timer` with `AutomaticUpdatePolicy=stage`. Once a day it downloads the changed layers and stages the new image as a second deployment. The new image takes over at the next reboot, whenever the user chooses. Docs: [rpm-ostree](https://coreos.github.io/rpm-ostree/), [bootc](https://bootc-dev.github.io/bootc/), [Fedora bootc](https://docs.fedoraproject.org/en-US/bootc/).
- the base ships both update timers disabled and no policy. The image turns this one on and sets the policy ([[monkeyimage]], Config)
- not `bootc-fetch-apply-updates.timer`: it applies and reboots by itself every 8 hours. Right for a server, wrong for a laptop in use
- by hand: `monke update` asks what to update: everything, the system (`rpm-ostree upgrade`), the apps (`flatpak update`) or your settings (`chezmoi update`); reboot to use a new image. `monke status` shows the booted, staged and rollback images ([[monke]])
- apps update separately from the image, and no timer updates them yet: `monke update` does them with the system
- `/etc` gets a 3-way merge of three things: the old image's defaults, the new image's defaults, local changes

### Update size
A stage downloads the layers that changed. Fedora chunks the base by package. Our own layers are rebuilt every day, about 248 MB even with nothing changed. Rechunking measured worse.

### Rollback
The previous deployment is the second entry in the boot menu. `monke rollback` runs `rpm-ostree rollback`: the previous deployment boots next, and running it again undoes that.
- the menu is hidden while boots succeed. `grub-boot-success.timer` marks a boot good after a couple of minutes logged in
- when a boot never gets there, the menu shows on the next boot, so the previous deployment is one pick away
- no greenboot: its default checks need the network at boot and reboot the machine by themselves, wrong for a laptop

So a change to the recipe reaches every machine with no hands on it, on its next reboot, Jojo's included.

---
## Users and login

- login screen: SDDM, as Fedora ships it
- accounts: one per person. Each person's setup comes through [[setup]]
- sudo and login with a YubiKey: `pam-u2f` and `pamu2fcfg` are in the image. Each key is set up in PAM per machine
- fingerprint login: `fprintd`, from the base

---
## Services

Service: a program that runs in the background. System services run as root for the whole machine. User services run in each person's session.
- system, enabled by the image: `rpm-ostreed-automatic.timer` (updates), `keyd.service` (key remaps), `tailscaled.service` (the mesh)
- user, enabled for everyone by the image: `battery-warn.timer`, `wlsunset.service` (night light), `kanshi.service` (screen layouts), `restic-backup.timer` and `restic-prune.timer` (backup)
- what each does and how to change it: [[monkeyimage]] (Config)
- turn a user service off for one person: `systemctl --user mask <unit>`
- after a drop-in change: `systemctl --user daemon-reload`, then restart the unit

---
## Networking

- wifi and wired: NetworkManager, with its tray applet in the session
- firewall: firewalld. Every network starts in zone `public`, as shipped: in only ssh, mdns, dhcpv6
	- a trusted network, such as the wifi at home, goes in zone `home`, which also lets in LocalSend, so a phone can send files to the laptop
	- mark one, once per network: `nmcli connection modify "<wifi name>" connection.zone home`. `nmcli connection show` lists the names
	- the image adds LocalSend's service (`/etc/firewalld/services/localsend.xml`) and the `home` zone with it (`/etc/firewalld/zones/home.xml`)
- the mesh: tailscale, joined once per machine during [[setup]]. The vault is on the mesh
- VPN: NetworkManager's OpenVPN and OpenConnect plugins. Proton VPN is an app, in one person's own list

---
## Power

- power profiles: tuned with tuned-ppd. thermald for heat
- battery warning: at 20% and 10%, from `battery-warn.timer`
	- change the levels for one person in `~/.config/systemd/user/battery-warn.service.d/<name>.conf`: `[Service]` and `Environment=BATTERY_WARN_LOW=<n> BATTERY_WARN_CRITICAL=<n>`
- at 2% UPower suspends the machine (Fedora's `CriticalPowerAction=Auto`)
- lid: logind sleeps on lid close, and stays awake when docked

---
## Storage

- disks: udisks2 mounts removable drives. `fstrim.timer` trims SSDs
- disk health: `smartctl` (smartmontools)
- a full disk: `ncdu`
- your files are backed up every night: [[you]] (Backup)

---
## Printing

- CUPS, as Fedora ships it, with `cups-browsed` and `ipp-usb` to find printers on the network and over USB
