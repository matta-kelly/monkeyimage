---
type: tool
description: Encrypted, deduplicated backup CLI; reference to understand how restic works, its commands and best practices, wherever it is used.
status: running
---
restic backs up folders into an encrypted repository as snapshots.
- How it works: repository, snapshots, dedup, encryption
- Commands: the pieces you use
- Retention: how `forget` decides what to keep
- Best practices

- used by [[backup]]
- docs: https://restic.readthedocs.io

---
## How it works
- repository: an encrypted store. It can sit on a local disk, a server, or S3-compatible storage
- snapshot: the result of one `backup` run, a full picture of the given paths at that moment
- dedup (deduplication): restic splits files into chunks and stores each chunk once
	- unchanged files cost almost nothing, so many snapshots are cheap
- encryption: the password encrypts everything in the repository
	- if you lose the password, the backup is unreadable and nothing can recover it
	- so the password lives in Vaultwarden

## Commands
- `init`: create a repository, once per target
- `backup <paths>`: make a snapshot of the paths you choose
	- excludes: `--exclude`, `--exclude-file`, `--exclude-caches`. You need them only when the paths are broad and hold junk
- `snapshots`: list the snapshots that exist
- `restore`: get files back
- `mount`: get files back by browsing a snapshot like a folder
- `forget`: drop snapshots by a retention policy
- `prune`: free the space that forgotten snapshots used. Usually you run `forget --prune`
- `check`: verify that the repository is not corrupt

## Retention
Retention policy: a set of rules that says which snapshots `forget` keeps. Example: `--keep-daily 7 --keep-weekly 4 --keep-monthly 6`

restic walks the snapshots and, in each time slot, keeps the newest one.
- daily 7: the last snapshot of each of the last 7 days
- weekly 4: the last snapshot of each of the last 4 weeks
- monthly 6: the last snapshot of each of the last 6 months
- one snapshot can fill several slots
- a snapshot that fills no slot is forgotten

The result is dense recent history and sparse old history, with about 17 snapshots at most.

restic counts days that have snapshots, not calendar days. A week offline still keeps 7 dailies.

## Best practices
- 3-2-1: 3 copies, on 2 kinds of media, with 1 off-site. This is the common rule. [[backup]] keeps only the off-site copy
- password: keep it in a private file read through `RESTIC_PASSWORD_FILE`, the usual setup for a run with nobody there to type it, and keep a copy elsewhere (Vaultwarden, [[backup]])
- automate: use a timer, not manual runs
- verify: run `check` now and then, and test real restores. An untested backup is a hope
