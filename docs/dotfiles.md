---
type: doc
description: "Dotfiles on Monkeyworks: each person's own config, in their own git repo, applied with chezmoi. What they hold, and how to change them and undo a change. Read when changing your own setup, or starting a repo for someone."
status: active
---
Dotfiles: the config files in `~` that set up your tools. Yours live in your own git repo, and chezmoi (a tool that copies the files of a repo into `~`) applies them. Nobody else's account sees them.
- What they hold: what is yours, and where it lands
- How you change them: the loop, getting them onto a machine, and how a file is written

- [[you]]: everything else that is yours
- [[how-it-works]]: where things live, and how config layers stack
- [[monkeyworks]]: the map

---
## What they hold

One rule sorts every file:
- the machine goes in the image
- a person goes in their dotfiles
- a project goes in its container

### What goes in
- your identity: git name and email, SSH keys, cloud creds. The secret ones come from your vault
- config you change often, or that only you use: keys, screen layouts, the prompt, the terminal
- tools only you use, or a distrobox (a container for extra tools) for them
- your personal apps: a script that runs `flatpak install --user`
- overrides of the shared defaults: the night light, battery levels, the backup time

### What does not
- anything every person should get: it goes in the image ([[monkeyimage]])

### Files outside `~`
chezmoi does not write to `/etc`, but some config lives there. A keyboard remap is the common case: keyd reads only `/etc/keyd/`.
- your dotfiles carry the file
- a `sudo` script installs it, and a chezmoi script runs that script
- it changes only the machine you install it on

---
## How you change them

### The loop
chezmoi keeps your repo (the source) and `~` (the live files) in step.
- change: edit the file in your repo, or edit it in `~` and run `chezmoi re-add` to copy it back
- check: `chezmoi diff` shows what an apply would change
- apply: `chezmoi apply` writes your repo to `~`. It may ask before it overwrites a file you changed by hand
- save: commit and push your repo, so the change is kept and can be undone
- undo: `git revert` the commit, then `chezmoi apply`
- inspect: `chezmoi managed` lists the files it manages, and `chezmoi status` shows what has drifted
- stop managing a file: `chezmoi forget <path>`

### Getting them onto a machine
- the first time: `chezmoi init --apply <repo>` clones the repo into `~/.local/share/chezmoi` and writes every file. That clone is the copy chezmoi works from
- after that: `chezmoi update` pulls the repo and applies it in one step
- a repo someone else helps manage: keep it private on GitHub, and give the machine a read-only deploy key
	- the helper pushes from their own machine; the owner runs `chezmoi update`, with no GitHub account
	- the deploy key's private half is a vault item. A template writes it to `~/.ssh/`, and an SSH host in `~/.ssh/config` uses it for `github.com`
	- the clone's remote is that SSH host: `chezmoi git -- remote set-url origin git@<host>:<owner>/<repo>.git`
	- the first clone runs before the key exists: clone over HTTPS while the repo is public, or with a token, then switch the remote to the SSH host

### How a file is written
- drop-in: a small file next to the shared default. Use drop-ins first, and replace a whole file only for a named reason ([[how-it-works]], Config layering)
- template (`.tmpl`): a file filled in at apply time. Use it for secrets from your vault through `rbw`, or for a difference between machines
- script (`run_onchange_`): a script that runs when its content changes. Use it for installs, such as a pinned download or your personal apps
- one repo for more than one OS: `.chezmoiignore` decides, per OS, what deploys
