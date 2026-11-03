---
type: doc
description: "How Monkeyworks works as a whole: where each thing lives and who owns it, how config layers stack, and how each part changes, from building the image to backing up. Read to understand the model before changing any part of the machine."
status: active
---
The model of the whole machine, which every part follows.
- Where things live: each path, what it holds, who owns it, how it changes
- How things change: the verbs: build, update, apply, back up, secrets, setup

- [[monkeyworks]]: the map of every note

---
## Where things live
Basis: the Filesystem Hierarchy Standard, plus the OSTree split, which is how Fedora documents Atomic. Each path has one owner and one way it changes.
- sorting rule: the machine goes in the image, a person goes in their dotfiles, a project goes in its container
- the rule, by boot stage: [[monkeyimage]] (What gets baked)

| Path                         | Holds                                              | Owner                                   | Changes by           |
| ---------------------------- | -------------------------------------------------- | --------------------------------------- | -------------------- |
| `/usr`                       | kernel, sway, drivers, packages. Read-only         | the image ([[monkeyimage]])             | Build, [[machine]] (Updates and rollback) |
| `/etc`                       | system config: image defaults + local changes      | the image (`files/system/etc`) + local  | [[machine]] (Updates and rollback) (3-way merge) |
| `/var/lib/flatpak`           | GUI apps, system scope                             | [[monkeyflatpaks]]                      | `default-flatpaks`, at boot |
| `~/.local/share/containers`  | dev environments (rootless Podman)                 | [[dev-containers]]                      | per project          |
| `~`: dotfiles                | config, user CLI tools                             | each person's repo                      | [[you]] (Dotfiles)     |
| `~`: data                    | projects, documents, media, downloads              | each person, not in git                 | [[you]] (Backup)       |
| `~/.ssh`, `~/.aws`           | ssh keys, cloud creds                              | the vault, through rbw                  | [[you]] (Secrets)      |

- not on disk: each person's vault master password, the tailnet identity

### Files on Atomic
```
/usr    read-only, from the image        → what the recipe bakes
/etc    image defaults + local changes   → files/system/etc
/var    yours, survives every update     → /home is /var/home
```
- so `files/system/` writes only `/usr` and `/etc`: nothing else is part of the image
- git declares `/usr`, `/etc`, the app lists and the dotfiles. The rest of `/var` is state: backed up, not built

### Config layering
How a program finds its config: it reads the layers in order, and a later layer wins. The same convention runs through the whole machine: the [XDG Base Directory spec](https://specifications.freedesktop.org/basedir-spec/latest/) (`/etc/xdg`, then `~/.config`) and [systemd's unit drop-ins](https://www.freedesktop.org/software/systemd/man/latest/systemd.unit.html) (`/usr/lib`, then `/etc`, then `~/.config`).

| Layer            | Path        | Owner                                | Examples                                                                           |
| ---------------- | ----------- | ------------------------------------ | ---------------------------------------------------------------------------------- |
| vendor defaults  | `/usr`      | the image: Fedora + [[monkeyimage]]  | `/usr/share/sway/config.d/`, `/usr/lib/systemd/`, `/etc/xdg` (shipped by packages) |
| system overrides | `/etc`      | the image's `/etc` + per-host config | `/etc/sway/config.d/`, `/etc/keyd/`, `/etc/rpm-ostreed.conf`                       |
| user overrides   | `~/.config` | each person's dotfiles               | `~/.config/sway/config.d/`, `~/.config/systemd/user/`                              |

- drop-ins: many programs read a `.d` folder of small files at each layer. A file adds or changes one thing, and leaves the rest of the vendor default in place
	- Sway on Fedora: `/etc/sway/config` reads `/usr/share/sway/config.d/*.conf`, `/etc/sway/config.d/*.conf`, then `~/.config/sway/config.d/*.conf`. A user file with the same name overrides Fedora's; an empty one disables it
- a whole user file replaces the vendor default, and with it everything the vendor wired in. Example: a user `~/.config/sway/config` drops Fedora's bar, polkit agent and session plumbing
- fallback: with no user file, the program uses the layer below. That is why Fedora's waybar appears with no waybar config in `~`
- rule: add a drop-in. Replace a whole file only for a named reason
- each note says how to change its own defaults: [[machine]], [[desktop]], [[you]]

---
## How things change
Basis: the nouns Fedora and bootc use in their own docs. The image's cycle: image → deployment → staged update → reboot → rollback, when needed.

| Verb          | Path                    | From → to                         | Engine                    | Where                          |
| ------------- | ----------------------- | --------------------------------- | ------------------------- | ------------------------------ |
| **Build**     | `/usr`, `/etc`, apps    | recipe in git → image in ghcr     | BlueBuild                 | Build                     |
| **Update**    | `/usr`, `/etc`          | image in ghcr → machine           | rpm-ostree timer, stage   | [[machine]] (Updates and rollback) |
| **Apply**     | `~`: dotfiles           | a person's repo → `~`             | chezmoi                   | [[you]] (Dotfiles)               |
| **Back up**   | `~`: data               | `~` → S3                          | restic                    | [[you]] (Backup)                 |
| **Secrets**   | `~/.ssh`, `~/.aws`      | vault → rbw → tools               | rbw + chezmoi templates   | [[you]] (Secrets)                |
| *sequence*    |                         |                                   |                           |                                |
| **Setup**     | all                     | nothing → whole machine           | the verbs above, in order | [[setup]]                      |

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
	- `files`, `copy`: `/usr`, `/etc`
	- `default-flatpaks`: `/var/lib/flatpak`
	- `chezmoi`: `~`
	- `signing`: the image is signed, so a machine can check where it came from ([cosign](https://blue-build.org/how-to/cosign/))
	- `justfiles`: named commands, for "how do I…"
- why BlueBuild and not a bare Containerfile: modules for apps and dotfiles, signing, and one recipe that reads top to bottom
- the way out: the generated Containerfile builds without BlueBuild, the plain way ([ublue image-template](https://github.com/ublue-os/image-template))
- base and packages: [[monkeyimage]]
