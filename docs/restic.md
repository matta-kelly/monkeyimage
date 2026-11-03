---
type: tool
description: Encrypted, deduplicated backup CLI; reference to understand how restic works, its commands and best practices, wherever it is used.
status: running
---
Backs up folders into an encrypted repository as snapshots.
- How it works: repository, snapshots, dedup, encryption
- Commands: the pieces you use
- Retention: how `forget` decides what to keep
- Best practices

- used by [[backup]]
- docs: https://restic.readthedocs.io

---
## How it works
- **Repository:** an encrypted store. Can sit on a local disk, a server, or S3-compatible storage
- **Snapshot:** one run of `backup`. A full picture of the given paths at that moment
- **Dedup:** files split into chunks, each chunk stored once. Unchanged files cost almost nothing, so many snapshots are cheap
- **Encryption:** everything in the repo is encrypted with the password
	- lose the password: the backup is unreadable, no recovery
	- so the password lives in Vaultwarden

## Commands
- `init`: create a repo, once per target
- `backup <paths>`: make a snapshot. You choose the paths
	- excludes: `--exclude`, `--exclude-file`, `--exclude-caches`. Needed only when paths are broad and hold junk
- `snapshots`: list what exists
- `restore` / `mount`: get files back. `mount` browses a snapshot like a folder
- `forget`: drop snapshots by a retention policy
- `prune`: free the space forgotten snapshots used. Usually `forget --prune`
- `check`: verify the repo is not corrupt

## Retention
Example: `--keep-daily 7 --keep-weekly 4 --keep-monthly 6`
- restic walks the snapshots and keeps the newest one in each time slot
	- daily 7: last snapshot of each of the last 7 days
	- weekly 4: last snapshot of each of the last 4 weeks
	- monthly 6: last snapshot of each of the last 6 months
	- one snapshot can fill several slots. Snapshots that fill none are forgotten
- result: dense recent history, sparse old history, about 17 snapshots max
- counts days that *have* snapshots, not calendar days. A week offline still keeps 7 dailies

## Best practices
- **3-2-1:** 3 copies, 2 kinds of media, 1 off-site. The common rule; [[backup]] keeps only the off-site copy
- **Password:** a private file through `RESTIC_PASSWORD_FILE`, the usual setup for a run with nobody there to type it, with a copy elsewhere (Vaultwarden, [[backup]])
- **Automate:** a timer, not manual runs
- **Verify:** `check` now and then, real restore tests. Untested backup is a hope
