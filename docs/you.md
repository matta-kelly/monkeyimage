---
type: doc
description: "The personal part of Monkeyworks: what belongs to one person and nobody else. Their account, dotfiles, secrets, backup, shell and terminal. Read when changing your own setup, or setting one up for someone."
status: active
---
What is yours alone: your account and everything in `~` (your home directory). You can change any of it, and nothing here reaches anyone else.
- Account: who you are on the machine and online
- Dotfiles: your config, in your own repo
- Secrets: keys and passwords, from your vault
- Backup: your files, every night
- Shell and terminal: the prompt, aliases, the terminal

- [[setup]]: how a new person gets all of this
- [[monkeyworks]]: the front page

---
## Account

Each person brings their own identity. The image bakes none of it. You need four things:
- an account on the machine
- a vault: a password store run with Vaultwarden (a Bitwarden-compatible server). Its master password is known only to you, so it is the one thing nobody else can supply
- a GitHub account: run `gh auth login` once (`gh` is the GitHub command line tool). Git then asks `gh` for the token, so no token sits in a file
- a dotfiles repo (see below)

## Dotfiles

Dotfiles: the config files in `~` that set up your tools. Yours live in your own repo and chezmoi applies them (chezmoi: a tool that copies the files of a repo into `~`). What goes in the repo, how to change it and how to undo a change: [[dotfiles]].

## Secrets

Secrets have one home, and access is deliberate.
- secrets live in your vault (Vaultwarden)
- you read them through `rbw` (a Bitwarden command line client, in the image)
	- `rbw list` shows the names
	- `rbw get <name>` shows one secret
	- the rbw agent holds the unlocked vault and locks it again after an hour
	- the unlocked vault is never in an environment variable
- secret files in `~` (SSH keys, cloud creds) come from the vault at `chezmoi apply`, through the rbw templates in your dotfiles
- a project's secrets: `rbw-run` reads the project's `secrets.toml` and runs a command with those secrets set

## Backup

Your files go to your own S3 bucket (cloud object storage) every night. Git protects your setup. [[restic]] (the backup tool) protects your data. The details and how to restore: [[backup]].
- what: all of `~`, minus a default excludes file in the image (caches, node_modules, build junk)
- when: nightly at 02:00. A missed run happens at wake
- pruning: weekly, keeping 7 daily, 4 weekly and 6 monthly backups
- failure: a failed backup warns on the desktop
- password: it lives in your vault, never only on the machine. Your dotfiles write it to a private file, so the nightly run works while `rbw` is locked
- timing change: put the new time in `~/.config/systemd/user/restic-backup.timer.d/<name>.conf`
- test: restore once each quarter, or it is not a backup
- status: not proven. No machine on the image has run the timers yet

## Shell and terminal

- shell: bash. Fedora's `~/.bashrc` stays whole and loads every file in `~/.bashrc.d/`. Put your additions there, one file per reason
- terminal: foot. Your config goes in `~/.config/foot/`
- tools only you use go in your dotfiles or in a distrobox (a container for extra tools), not in the image
