---
type: doc
description: "The front page of Monkeyworks, the Fedora Sway Atomic machine Jojo and I share. Read it first: before changing the machine, or to find where a piece of it lives and which note covers it."
status: active
---
Monkeyworks: one Fedora Sway Atomic image, the same on every machine, with each person's own setup on top.
- [[#Filesystem layout]] where things live: each path, what it holds, who owns it, and how config layers stack
- [[#Lifecycle]] how things change: build, update, apply, protect, secrets, bootstrap
- [[#Boot sequence]] when things run: stages as rows, kernel pillars as columns
- [[#Targets]] the machines it runs on: mine, Jojo's
- [[#ULSAH outline]] the standard sysadmin reference, as a map of the domain

Each part has its own note:
- [[monkeyimage]]: `/usr` and `/etc`, the image: base, packages, shared config
- [[monkeyflatpaks]]: `/var/lib/flatpak`, the apps, in three bins: both, just me, just Jojo
- [[backup]]: `~` data, backed up every night
- each person's dotfiles: `~`, their own repo. Mine is deeotee, private

---
## Filesystem layout

Where things live. Basis: the Filesystem Hierarchy Standard, plus the OSTree split, which is how Fedora documents Atomic. Each path has one owner and one way it changes.
- sorting rule: the machine goes in the image, I go in dotfiles, a project goes in its container
- the rule, by boot stage: [[monkeyimage#What gets baked]]

| Path                         | Holds                                              | Owner                                   | Changes by           |
| ---------------------------- | -------------------------------------------------- | --------------------------------------- | -------------------- |
| `/usr`                       | kernel, sway, drivers, packages. Read-only         | the image ([[monkeyimage]])             | [[#Build]], [[#Update]] |
| `/etc`                       | system config: image defaults + my local changes   | the image (`files/system/etc`) + local  | [[#Update]] (3-way merge) |
| `/var/lib/flatpak`           | GUI apps, system scope                             | [[monkeyflatpaks]]                      | `default-flatpaks`, at boot |
| `~/.local/share/containers`  | dev environments (rootless Podman)                 | [[dev-containers]]                      | per project          |
| `~`: dotfiles                | config, user CLI tools                             | [[deeotee]]                             | [[#Apply]]           |
| `~`: data                    | vault, projects, media, downloads                  | me, not in git                          | [[#Protect]]         |
| `~/.ssh`, `~/.aws`           | ssh keys, cloud creds, age key                     | Vaultwarden, through rbw                | [[#Secrets]]         |
| (no path yet)                | legibility: the machine describing itself          | open: [[legibility]]                    | open                 |

- not on disk: the Bitwarden master password (in my head), the tailnet identity

#### Files on Atomic
```
/usr    read-only, from the image        → what the recipe bakes
/etc    image defaults + local changes   → files/system/etc
/var    mine, survives every update      → /home is /var/home
```
- so `files/system/` writes only `/usr` and `/etc`: nothing else is part of the image
- git declares `/usr`, `/etc`, the app lists and the dotfiles. The rest of `/var` is state: protected, not built

#### Config layering
How a program finds its config: it reads the layers in order, and a later layer wins. The same convention runs through the whole machine: the [XDG Base Directory spec](https://specifications.freedesktop.org/basedir-spec/latest/) (`/etc/xdg`, then `~/.config`) and [systemd's unit drop-ins](https://www.freedesktop.org/software/systemd/man/latest/systemd.unit.html) (`/usr/lib`, then `/etc`, then `~/.config`).

| Layer            | Path        | Owner                                | Examples                                                                           |
| ---------------- | ----------- | ------------------------------------ | ---------------------------------------------------------------------------------- |
| vendor defaults  | `/usr`      | the image: Fedora + [[monkeyimage]]  | `/usr/share/sway/config.d/`, `/usr/lib/systemd/`, `/etc/xdg` (shipped by packages) |
| system overrides | `/etc`      | the image's `/etc` + per-host config | `/etc/sway/config.d/`, `/etc/keyd/`, `/etc/rpm-ostreed.conf`                       |
| user overrides   | `~/.config` | each user: [[deeotee]] for me        | `~/.config/sway/config.d/`, `~/.config/systemd/user/`                              |

- drop-ins: many programs read a `.d` folder of small files at each layer. A file adds or changes one thing, and leaves the rest of the vendor default in place
	- Sway on Fedora: `/etc/sway/config` reads `/usr/share/sway/config.d/*.conf`, `/etc/sway/config.d/*.conf`, then `~/.config/sway/config.d/*.conf`. A user file with the same name overrides Fedora's; an empty one disables it
- a whole user file replaces the vendor default, and with it everything the vendor wired in. Example: a user `~/.config/sway/config` drops Fedora's bar, polkit agent and session plumbing
- fallback: with no user file, the program uses the layer below. That is why Fedora's waybar appears with no waybar config in `~`
- rule: add a drop-in. Replace a whole file only for a named reason

##### Shared defaults a user can change
What the image sets for every user, and the file that changes it for one user. Each is in [[monkeyimage#Config]].
- night light, 20:00 to 07:00: `~/.config/systemd/user/wlsunset.service.d/<name>.conf` with `[Service]` and `Environment=WLSUNSET_ARGS="-l <latitude> -L <longitude>"` (the real sun) or `"-S <sunrise> -s <sunset>"`
- battery warning at 20% and 10%: `~/.config/systemd/user/battery-warn.service.d/<name>.conf` with `[Service]` and `Environment=BATTERY_WARN_LOW=<n> BATTERY_WARN_CRITICAL=<n>`
- laptop panel off with the lid closed: an empty `~/.config/sway/config.d/70-lid.conf` turns it off for that user
- turn a unit off for one user: `systemctl --user mask <unit>`; apply a change: `systemctl --user daemon-reload`, then restart the unit
- keybinds: Fedora's defaults (close a window: Super+Shift+Q); a user adds their own in `~/.config/sway/config.d/`
- screen layouts: a user's profiles in `~/.config/kanshi/config`; with none, sway places new screens itself
- keyboard remap: keyd reads only `/etc/keyd/`, so a user's config repo carries the file and a `sudo` script installs it

---
## Lifecycle

How each path changes. Basis: the nouns Fedora and bootc use in their own docs. The image's cycle: image → deployment → staged update → reboot → rollback, when needed.

| Verb          | Path                    | From → to                         | Engine                    |
| ------------- | ----------------------- | --------------------------------- | ------------------------- |
| **Build**     | `/usr`, `/etc`, apps    | recipe in git → image in ghcr     | BlueBuild                 |
| **Update**    | `/usr`, `/etc`          | image in ghcr → machine           | rpm-ostree timer, stage   |
| **Apply**     | `~`: dotfiles           | [[deeotee]] → `~`                 | chezmoi                   |
| **Protect**   | `~`: data               | `~` → Hetzner S3                | restic                    |
| **Secrets**   | `~/.ssh`, `~/.aws`      | Vaultwarden → rbw → tools         | rbw + chezmoi templates   |
| *sequence*    |                         |                                   |                           |
| **Bootstrap** | all                     | nothing → whole machine           | the verbs above, in order |

### Build
Recipe in git → image in ghcr. BlueBuild does it.
- [BlueBuild.org](https://blue-build.org/how-to/setup/)
- [Blue Build modules](https://github.com/blue-build/modules)
- BlueBuild: a YAML recipe lists modules, in order. The CLI turns the recipe into a Containerfile and builds it ([recipe reference](https://blue-build.org/reference/recipe/))
	- `bluebuild generate` prints that Containerfile: nothing is hidden
	- the `containerfile` module takes raw Containerfile lines, for what no module covers
	- builds run in CI (GitHub Action) or local (`bluebuild build`, [local builds](https://blue-build.org/how-to/local/))
- modules that map to paths
	- `dnf`, `systemd`, `kargs`: `/usr`
	- `files`: `/usr`, `/etc`
	- `default-flatpaks`: `/var/lib/flatpak`
	- `chezmoi`: `~`
	- `signing`: the image is signed, so a machine can check it came from me ([cosign](https://blue-build.org/how-to/cosign/))
	- `justfiles`: named commands, for "how do I…"
- why BlueBuild and not a bare Containerfile: modules for apps and dotfiles, signing, and one recipe that reads top to bottom
- the way out: the generated Containerfile builds without BlueBuild, the plain way ([ublue image-template](https://github.com/ublue-os/image-template))
- base and packages: [[monkeyimage]]

### Update
Image in ghcr → machine. Two loops that meet only at the registry: GitHub builds, the machine pulls; nothing pushes to it.
- build side: GitHub builds `latest` on every push to main and daily at 06:00 UTC, so Fedora's base fixes are baked in even when the recipe is unchanged
- machine side: `rpm-ostreed-automatic.timer` with `AutomaticUpdatePolicy=stage`. Once a day it downloads the changed layers and stages the new image as a second deployment; it takes over at the next reboot, whenever I choose ([rpm-ostree](https://coreos.github.io/rpm-ostree/), [bootc](https://bootc-dev.github.io/bootc/), [Fedora bootc](https://docs.fedoraproject.org/en-US/bootc/))
	- the base ships both update timers disabled and no policy. The image turns this one on and sets the policy ([[monkeyimage#Config]])
	- not `bootc-fetch-apply-updates.timer`: it applies and reboots by itself every 8 hours. Right for a server, wrong for a laptop in use
	- by hand: `rpm-ostree upgrade`, then reboot. `rpm-ostree rollback` goes back one deployment
- update size: a stage downloads the layers that changed. Fedora chunks the base by package; our own layers are rebuilt every day, about 248 MB even with nothing changed. Rechunking measured worse. Options: [[smaller-image-updates]]
- `/etc` gets a 3-way merge: the old image's defaults, the new image's defaults, my local changes
- rollback: the previous deployment is the second entry in the boot menu
	- the menu is hidden while boots succeed. `grub-boot-success.timer` marks a boot good after a couple of minutes logged in; when a boot never gets there, the menu shows on the next boot, so the previous deployment is one pick away
	- no greenboot: its default checks need the network at boot and reboot the machine by themselves, wrong for a laptop
- so a change to the recipe reaches every machine with no hands on it, on its next reboot, Jojo's included
- the dazoo bootc nodes run the apply-and-reboot version of this loop: [[c-devops]]

### Apply
[[deeotee]] (chezmoi source) → `~`.
- `chezmoi apply`: source to live. `chezmoi re-add`: live edits back to source
- secrets enter through `.tmpl` files, pulled from Vaultwarden
- scripts that write outside `~` (`chezmoi managed -i scripts`) are image work, parked in dotfiles until the image exists

### Protect
[[backup]]. Git protects setup. [[Restic]] protects data. Overlap is intentional: different failure modes.

The image holds restic, the timers and the excludes ([[monkeyimage#Config]]). Each user's dotfiles hold their templates. Not proven: no machine on the image has run the timers. The plan:
- restic on `~`, minus a default excludes file in the image (caches, node_modules, build junk)
- target: Hetzner S3, one bucket per owner ([[backup]]). No local copy
- systemd timer: a default in the image, nightly backup, weekly forget/prune (7d/4w/6m), and a missed run happens at wake (`Persistent=true`). A user changes the time with a drop-in in their own dotfiles
- restic password lives in Vaultwarden, never only on backed-up machines. chezmoi writes it to a private file in `~`, so a nightly run works with `rbw` locked
- quarterly restore test or it isn't a backup

### Secrets
One home, deliberate access. Crosses every path, is not one.
- secrets live in Vaultwarden (OpenBao later)
- a user reads the vault through rbw (in the image): `rbw list` for names, `rbw get <name>` for one. rbw's agent holds the unlocked vault and locks again after an hour; never in env
- secret files in `~` (SSH keys, cloud creds) come from the vault through the config repo's rbw templates, at `chezmoi apply`
- a project's secrets: `rbw-run` (in [[deeotee]]) reads the project's `secrets.toml` and runs a command with them set
- GitHub: `gh auth login` once; git asks `gh` for the token, so no token sits in a file

### Bootstrap
New machine to whole. Two parts: the machine, once per machine; then each user, once per person (me, Jojo).
- the image holds the tools, the same for everyone: git, chezmoi, rbw, gh ([[monkeyimage#Packages]])
- each user brings their identity, never baked: their own dotfiles repo, GitHub account and vault

Machine:
1. install generic Sway Atomic from USB ([Atomic Desktops docs](https://docs.fedoraproject.org/en-US/atomic-desktops/))
2. rebase to the image, in two hops, a reboot after each ([rpm-ostree](https://coreos.github.io/rpm-ostree/)) (Update)
	- `rpm-ostree rebase ostree-unverified-registry:ghcr.io/matta-kelly/monkeyimage:latest`: the first image brings the signing key and policy
	- `rpm-ostree rebase ostree-image-signed:docker://ghcr.io/matta-kelly/monkeyimage:latest`: from here every image is checked
	- the flatpaks install at the first boot ([[monkeyflatpaks]])
3. join the mesh (headscale): `sudo tailscale up --login-server <your headscale URL> --auth-key <key>`, with a single-use key from whoever runs the headscale server ([[sop-mesh-nodes]]). The vault is on the mesh, so this comes before each user's steps

Each user, who needs two things first: a Vaultwarden account, with a master password only they know, and a dotfiles repo.
1. log in to the vault: `rbw config set base_url <your Vaultwarden URL>`, `rbw config set email <email>`, `rbw login` (the master password)
2. `gh auth login`, HTTPS: GitHub, and git's credential helper
3. `chezmoi init --apply <their dotfiles repo>` (Apply): secret files (SSH keys, cloud creds) come from the vault through rbw templates
	- the config records the source dir init used. Mine: clone lot, then `chezmoi init --apply --source ~/lot/mkultra/deeotee`
4. start backup (Protect): a Hetzner S3 bucket and key, and two vault items, with the names in the user's templates: the address and key (`hetzner-s3-<name>`, notes = JSON with `RESTIC_REPOSITORY`, `AWS_DEFAULT_REGION`, `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`), and a long random repository password (`restic-<name>`, notes). Step 3 writes these to `~/.config/restic/`. Then once: `set -a; . ~/.config/restic/env; set +a; restic -p ~/.config/restic/password init`. Then one backup by hand, `systemctl --user start restic-backup`, and one file restored ([[#Protect]])
5. `restic restore` (Protect), when there is data to bring back: password from the vault. Not built ([[#Protect]])

Only unforgeable input: each user's master password.

---
## Boot sequence

When things run. Basis: the real order the machine comes up in; systemd names the stages as targets (`sysinit`, `basic`, `multi-user`, `graphical`).
- firmware → bootloader → kernel → initramfs → systemd → system services → login → session → apps
- read as a grid: stages as rows, kernel pillars as columns

### Rows: stages
Coarse stages, deepest first. The deeper a piece sits, the more it belongs in the image, the more it reaches Jojo, and the harder a mistake is to undo.
1. kernel: firmware, bootloader, kernel, initramfs. Drivers, kernel args
2. system: `sysinit` → `multi-user`. Root, system services, `/etc`. For every user
3. session: `graphical`, login, then my user manager. Inside Sway, runs as my user
4. apps: on demand. Flatpaks in a sandbox
5. project: on demand. One repo's toolchain, in its container

- the split comes from systemd: a system manager (boot, root) and a user manager (my session)
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
	- files: on Atomic the filesystem is the design ([[#Files on Atomic]])
	- processes: system services vs user services, the stage split
	- security: root vs me, and the flatpak sandbox

---
## Targets

The machines this lands on.
- mine: monkeyworks (ThinkPad)
- Jojo's: the same image and app lists, her own config through the [[personal-path]], and her overlay (apps, keyboard, her legibility entry): [[jojo-onboard]]

---
## ULSAH outline

*UNIX and Linux System Administration Handbook* (Nemeth, Snyder, Hein, Whaley, Mackin), 5th ed., Addison-Wesley, 2017. The standard sysadmin reference. Outline from its [table of contents](https://www.admin.com/samples/TOC.pdf), main headings only. ★ = bears on this machine.

- **Section 1: Basic administration**
	- 1 Where to start: a sysadmin's duties, docs and man pages, ways to find and install software
	- ★ 2 Booting and system management daemons: firmware (BIOS/UEFI), boot loaders (GRUB), init, systemd (units, targets, dependencies, execution order), a machine that won't boot
	- ★ 3 Access control and rootly powers: UNIX permissions, root, sudo, ACLs, modern access control
	- 4 Process control: the parts and life cycle of a process, signals, `/proc`, periodic processes
	- ★ 5 The filesystem: mounting, organization of the file tree, file types, device files, attributes
	- ★ 6 Software installation and management: OS install, package managers, repositories, localization and configuration
	- 7 Scripting and the shell: sh, regex, Python, Git
	- ★ 8 User management: accounts, `/etc/passwd`, home directories, PAM
	- 9 Cloud computing
	- 10 Logging: the systemd journal, syslog, kernel and boot logs, rotation
	- ★ 11 Drivers and the kernel: devices and drivers, kernel modules, kernel errors
	- 12 Printing: CUPS
- **Section 2: Networking**
	- ★ 13 TCP/IP networking: addressing, routing, DHCP, firewalls and NAT, troubleshooting
	- 14 Physical networking: Ethernet, wireless
	- 15 IP routing
	- 16 DNS
	- 17 Single sign-on: LDAP, directory logins
	- 18 Electronic mail
	- 19 Web hosting
- **Section 3: Storage**
	- ★ 20 Storage: disks, partitions, RAID, filesystems (ext4, ZFS, Btrfs), backup strategy
	- 21 NFS
	- 22 SMB
- **Section 4: Operations**
	- ★ 23 Configuration management: elements, dangers, Ansible, Salt
	- ★ 24 Virtualization
	- ★ 25 Containers: core concepts, Docker, containers in practice
	- ★ 26 CI/CD: pipelines, container images as build artifacts
	- ★ 27 Security: how security is compromised, basic measures, SSH, firewalls, VPNs
	- 28 Monitoring
	- 29 Performance analysis
	- 30 Data center basics
	- 31 Methodology, policy and politics: DevOps, policies, SLAs

- the cut: domain (basic, network, storage, operations), then subsystem
- Section 1 is close to the pillars: boot (2), security (3), processes (4), files (5), devices (11)
- Section 4 is close to the loop: config management, containers, CI/CD
- server-centric: no desktop, session or GUI. [Arch Wiki General recommendations](https://wiki.archlinux.org/title/General_recommendations) covers that part
