---
type: service
description: Nightly restic backup of each user's data to Hetzner S3; reference for what is backed up, where, how long it is kept, and how to restore.
status: planned
---
Promise: each user's data on this machine gets snapshotted every night, kept per the retention policy, and can be restored. Each user gets the same default, and can change it.
- Engine: the tool that does the work
- Orchestration: what turns the tool into a service
- Restore

- part of the Data layer in [[monkeyworks]]
- the default service and timer go in [[monkeyimage]]; a person's overrides go in their own dotfiles

---
## Engine
- [[restic]]: snapshots, dedup, encryption, forget/prune

## Orchestration
Thin layer: plain systemd user units first, resticprofile if it outgrows that. The templates, the key and restic's backup, restore and prune are proven against the real bucket, with the image's restic in a container. Not proven: the timers, the desktop warning and `chezmoi apply`, which need a machine on the image.
- **Files**
	- image: `restic-backup.service` (what runs, repo, password file) and `restic-backup.timer` (when), and `restic-prune.service` and `.timer`, in `/usr/lib/systemd/user/`
	- image: `restic-failed.service`, which warns on the desktop when a backup or prune fails
	- image: the default excludes, `/etc/restic/excludes`
	- a user's dotfiles: templates that write `~/.config/restic/env` (from the vault item `hetzner-s3-<name>`, notes = JSON with `RESTIC_REPOSITORY`, `AWS_DEFAULT_REGION`, `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`) and `~/.config/restic/password` (from the vault item `restic-<name>`, notes), and a drop-in that overrides the default, `~/.config/systemd/user/restic-backup.timer.d/time.conf`. The same pattern as `wlsunset` and `battery-warn` ([[how-it-works]], Config layering)
- **What:** all of `~`, minus an excludes file, so a user has no folders to choose. Clean `~` out first
- **Where:** Hetzner S3, one bucket per owner, the fleet's layout ([[backups]]): each person's repository is a folder in their bucket, such as `<bucket>/laptop/restic`, and Jojo gets her own bucket, made with object lock. Same Hetzner project, so a key on a laptop also opens the other buckets ([[hetzner-cloud]]); restic's encryption still protects what is in them. Any machine, no extra hardware, and it survives theft and fire. No local copy: it would add only faster restores and restores with no internet
- **When:** systemd timer, nightly backup, weekly `forget --prune`. `Persistent=true`, so a laptop asleep at night runs the missed backup when it wakes. A failed run tries again for about half an hour, so a laptop that just woke can reach wifi, then warns on the desktop
- **Secret:** repo password in Vaultwarden. chezmoi writes it to a private file in `~`, and restic reads that file through `RESTIC_PASSWORD_FILE`, so a nightly run works with `rbw` locked
- **Retention:** 7 daily, 4 weekly, 6 monthly

## Restore
- test restore once at setup, then quarterly
