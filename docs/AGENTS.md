# This machine: rules for an agent

You help the person at this laptop. It runs Monkeyworks: Fedora Sway Atomic from our own image. The person owns it: they can change anything, see what changed, and undo it. Your job is to make that easy.

## Read first
- the docs are in `/usr/share/doc/monkeyworks/`. Start at `monkeyworks.md`, the map. Read the note for the part you work on before you act
- the CLI is `monke` (the person may call it by another name, such as `mattmatt`). `monke.md` there says what each command does

## How this machine works
- `/usr` is read-only. Never `dnf install` or `rpm-ostree install`: they fail or drift. A package for everyone goes in the image; tell the person, and Matt makes the change
- apps are flatpaks: `flatpak install flathub <app id>`. `flatpak search <name>` finds the id
- updates: `monke update` (system, apps, settings). A new system takes over at the next reboot. `monke rollback` goes back
- the person's settings are their dotfiles, in a git repo that chezmoi applies (`dotfiles.md`)
	- to change one: edit the file in `~/.local/share/chezmoi`, show `chezmoi diff`, ask, then `chezmoi apply`, then commit with a clear message
	- to undo: `git revert` the commit in `~/.local/share/chezmoi`, then `chezmoi apply`
	- a file in `~` that chezmoi manages (`chezmoi managed` lists them) is changed in the repo, never only in `~`
- the desktop is Sway, not GNOME: `gsettings` does not change it
	- keys: `~/.config/sway/config.d/*.conf`, then reload with Super+Shift+C
	- the background: a picture at `~/Pictures/background.jpg`, then Super+Shift+C
	- the launcher is rofi (Super+D); the terminal is foot
- in foot, copy is Ctrl+Shift+C and paste is Ctrl+Shift+V. Ctrl+C stops the running program

## Rules
- say what you will do in plain words, then do it. Ask before anything that changes a file, installs, or deletes
- never read, print or copy a secret: the vault (`rbw`), `~/.config/restic/`, `~/.config/monke/key`, `~/.ssh/`
- ask before `sudo`, and before anything outside the person's home
- when a thing is hard to do here, say so: it is a fix for the system, not a workaround on this machine
