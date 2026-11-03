---
type: doc
description: "Dotfiles on Monkeyworks: each person's own config, in their own git repo, applied with chezmoi. What goes in it, how to change it, and how to undo a change. Read when changing your own setup, or starting a repo for someone."
status: active
---
Your dotfiles: your own config, in your own git repo, applied to `~` with chezmoi. Nobody else's machine or account sees them.
- What goes in them: what is yours, not the machine's
- The loop: change, check, apply, undo
- How a file is written: drop-ins, templates, scripts
- Files outside `~`: the `sudo` script

- [[you]]: everything else that is yours
- [[how-it-works]]: where things live, and how config layers stack
- [[monkeyworks]]: the map

---
## What goes in them

The sorting rule: the machine goes in the image, a person goes in their dotfiles, a project goes in its container.
- your identity: git name and email, SSH keys, cloud creds (the secret ones come from your vault)
- config you change often, or that is only yours: keys, screen layouts, the prompt, the terminal
- CLI tools only you use, or a distrobox for them
- your personal apps: a script that runs `flatpak install --user`
- overrides of the shared defaults: the night light, battery levels, the backup time
- not here: anything every person should get. That goes in the image ([[monkeyimage]])

## The loop

chezmoi keeps your repo (the source) and `~` (the live files) in step.
- change: edit the file in your repo, or edit it in `~` and run `chezmoi re-add` to copy it back
- check: `chezmoi diff` shows what an apply would change
- apply: `chezmoi apply` writes your repo to `~`. It may ask before it overwrites a file you changed by hand
- save: commit and push your repo, so the change is kept and can be undone
- undo: `git revert` the commit in your repo, then `chezmoi apply`
- see what it manages: `chezmoi managed`; what has drifted: `chezmoi status`
- stop managing a file: `chezmoi forget <path>`

## How a file is written

- drop-ins first: add a small file next to the shared default, and replace a whole file only for a named reason ([[how-it-works]], Config layering)
- templates (`.tmpl`): a file filled in at apply time, for secrets from your vault through `rbw`, or for a difference between machines
- scripts (`run_onchange_`): run when their content changes, for installs such as a pinned download or your personal apps
- one repo for more than one OS: `.chezmoiignore` decides, per OS, what deploys

## Files outside `~`

Some config lives in `/etc`, which chezmoi does not write. A keyboard remap is the common case: keyd reads only `/etc/keyd/`.
- your dotfiles carry the file, and a `sudo` script installs it, run by a chezmoi script
- it is still yours: it changes only the machine you install it on
