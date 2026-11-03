---
type: doc
description: "Setup for Monkeyworks: a new machine to our shared desktop, then a new person to their whole setup. Read when installing a machine or adding a person."
status: active
---
New machine to whole, in two parts: the machine, once per machine; then each person, once per person.
- Machine: install, rebase to the image, join the mesh
- Each person: vault, GitHub, dotfiles, backup

- the image holds the tools, the same for everyone: git, chezmoi, rbw, gh ([[monkeyimage]], Packages)
- each person brings their identity, never baked: their own dotfiles repo, GitHub account and vault ([[you]], Account)
- the only input nobody else can supply: each person's master password
- [[monkeyworks]]: the front page

---
## Machine

1. install generic Sway Atomic from USB ([Atomic Desktops docs](https://docs.fedoraproject.org/en-US/atomic-desktops/))
2. rebase to the image, in two hops, a reboot after each ([rpm-ostree](https://coreos.github.io/rpm-ostree/))
	- `rpm-ostree rebase ostree-unverified-registry:ghcr.io/matta-kelly/monkeyimage:latest`: the first image brings the signing key and policy
	- `rpm-ostree rebase ostree-image-signed:docker://ghcr.io/matta-kelly/monkeyimage:latest`: from here every image is checked
	- the flatpaks install at the first boot ([[monkeyflatpaks]])
3. join the mesh (headscale): `sudo tailscale up --login-server <your headscale URL> --auth-key <key>`, with a single-use key from whoever runs the headscale server ([[sop-mesh-nodes]]). The vault is on the mesh, so this comes before each person's steps

## Each person

Two things first: a Vaultwarden account, with a master password only they know, and a dotfiles repo.
1. log in to the vault: `rbw config set base_url <your Vaultwarden URL>`, `rbw config set email <email>`, `rbw login` (the master password)
2. `gh auth login`, HTTPS: GitHub, and git's credential helper
3. `chezmoi init --apply <their dotfiles repo>`: secret files (SSH keys, cloud creds) come from the vault through rbw templates ([[dotfiles]])
4. start backup: an S3 bucket and key, and two vault items, with the names in the person's templates: the address and key (`hetzner-s3-<name>`, notes = JSON with `RESTIC_REPOSITORY`, `AWS_DEFAULT_REGION`, `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`), and a long random repository password (`restic-<name>`, notes). Step 3 writes these to `~/.config/restic/`. Then once: `set -a; . ~/.config/restic/env; set +a; restic -p ~/.config/restic/password init`. Then one backup by hand, `systemctl --user start restic-backup`, and one file restored ([[you]], Backup)
5. `restic restore`, when there is data to bring back: password from the vault ([[backup]])
