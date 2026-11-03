---
type: doc
description: "The personal part of Monkeyworks: what belongs to one person and nobody else. Their account, dotfiles, secrets, backup, shell and terminal. Read when changing your own setup, or setting one up for someone."
status: active
---
What is yours alone: your account and everything in `~`. You can change any of it, and nothing here reaches anyone else.
- [[#Account]] who you are on the machine and online
- [[#Dotfiles]] your config, in your own repo
- [[#Secrets]] keys and passwords, from your vault
- [[#Backup]] your files, every night
- [[#Shell and terminal]] the prompt, aliases, the terminal

- [[setup]]: how a new person gets all of this
- [[monkeyworks]]: the front page

---
## Account

Each person brings their own identity; the image bakes none of it.
- an account on the machine
- a vault: Vaultwarden, with a master password only you know. The one thing nobody else can supply
- a GitHub account: `gh auth login` once, and git asks `gh` for the token, so no token sits in a file
- a dotfiles repo, below

## Dotfiles

Your config, in your own repo, applied with chezmoi. Mine is deeotee.
- `chezmoi apply`: your repo to `~`. `chezmoi re-add`: edits made in `~` back to the repo
- `chezmoi diff` before an apply shows what would change
- add to the shared defaults with drop-ins; replace a whole file only for a named reason ([[monkeyworks#Config layering]])
- system files (`/etc`) a person needs, such as a keyboard remap: the dotfiles carry them, and a `sudo` script installs them ([[per-host-system-config]])

## Secrets

One home, deliberate access.
- secrets live in your vault (Vaultwarden)
- read it through `rbw` (in the image): `rbw list` for names, `rbw get <name>` for one. rbw's agent holds the unlocked vault and locks again after an hour; never in env
- secret files in `~` (SSH keys, cloud creds) come from the vault through your dotfiles' rbw templates, at `chezmoi apply`
- a project's secrets: `rbw-run` reads the project's `secrets.toml` and runs a command with them set

## Backup

Your files, every night, to your own S3 bucket. Git protects your setup; [[restic]] protects your data. The details and how to restore: [[backup]].
- all of `~`, minus a default excludes file in the image (caches, node_modules, build junk)
- nightly at 02:00, and a missed run happens at wake; old backups are pruned weekly, keeping 7 daily, 4 weekly, 6 monthly
- a failed backup warns on the desktop
- the password lives in your vault, never only on the machine; your dotfiles write it to a private file, so the nightly run works with `rbw` locked
- change the time with `~/.config/systemd/user/restic-backup.timer.d/<name>.conf`
- quarterly restore test, or it isn't a backup
- not proven: no machine on the image has run the timers yet

## Shell and terminal

- shell: bash. Fedora's `~/.bashrc` stays whole and loads every file in `~/.bashrc.d/`, so your additions go there, one file per reason
- terminal: foot. Your config goes in `~/.config/foot/`
- tools only you use go in your dotfiles or a distrobox, not the image
