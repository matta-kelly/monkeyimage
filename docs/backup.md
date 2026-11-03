---
type: service
description: Nightly restic backup of each user's data to Hetzner S3; reference for what is backed up, where, how long it is kept, and how to restore.
status: planned
---
Promise: each user's data on this machine is snapshotted every night, kept per the retention policy, and can be restored. Each user gets the same default and can change it.
- Engine: the tool that does the work
- Orchestration: what turns the tool into a service
- Restore

- part of the Data layer in [[monkeyworks]]
- the default service and timer go in [[monkeyimage]]; a person's overrides go in their own [[dotfiles]]

---
## Engine

- [[restic]]: snapshots, dedup, encryption, forget/prune

## Orchestration

A thin layer: plain systemd user units first, resticprofile if it outgrows them.
- proven, against the real bucket, with the image's restic in a container:
	- the templates
	- the key
	- restic's backup, restore and prune
- not proven, because it needs a machine on the image:
	- the timers
	- the desktop warning
	- `chezmoi apply`

Files:
- in the image
	- `restic-backup.service` (what runs, repo, password file) and `restic-backup.timer` (when)
	- `restic-prune.service` and `restic-prune.timer`
	- all four in `/usr/lib/systemd/user/`
	- `restic-failed.service`: warns on the desktop when a backup or prune fails
	- `/etc/restic/excludes`: the default excludes
- in a user's dotfiles
	- a template that writes `~/.config/restic/env`, from the vault item `hetzner-s3-<name>`
		- its notes hold JSON with `RESTIC_REPOSITORY`, `AWS_DEFAULT_REGION`, `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
	- a template that writes `~/.config/restic/password`, from the notes of the vault item `restic-<name>`
	- a drop-in that overrides the default: `~/.config/systemd/user/restic-backup.timer.d/time.conf`
	- the pattern is the same as `wlsunset` and `battery-warn` ([[how-it-works]], Config layering)

Settings:
- **What:** all of `~`, minus the excludes file, so a user has no folders to choose. Clean `~` out first
- **Where:** Hetzner S3, one bucket per owner
	- each person's repository is a folder in their bucket, such as `<bucket>/laptop/restic`
	- Jojo gets her own bucket, made with object lock
	- all buckets are in the same Hetzner project, so a key on a laptop also opens the other buckets. restic's encryption still protects what is in them
	- why S3: any machine can use it, it needs no extra hardware, and it survives theft and fire
	- no local copy: it would add only faster restores and restores with no internet
- **When:** a systemd timer. Nightly backup, weekly `forget --prune`
	- `Persistent=true`: a laptop asleep at night runs the missed backup when it wakes
	- a failed run tries again for about half an hour, so a laptop that just woke can reach wifi. Then it warns on the desktop
- **Secret:** the repo password is in Vaultwarden
	- chezmoi writes it to a private file in `~`
	- restic reads that file through `RESTIC_PASSWORD_FILE`, so a nightly run works with `rbw` locked
- **Retention:** 7 daily, 4 weekly, 6 monthly

## Restore

- test restore once at setup, then quarterly
