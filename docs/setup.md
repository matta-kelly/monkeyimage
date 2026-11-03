---
type: doc
description: "Setup for Monkeyworks: a new machine to our shared desktop, then a new person to their whole setup. Read when installing a machine or adding a person."
status: active
---
A new machine becomes whole in two parts: the machine, once per machine; then each person, once per person.
- Machine: install, rebase to the image, join the mesh
- Each person: vault, GitHub, dotfiles, backup

The image and the person stay apart.
- the image holds the tools, the same for everyone: git, chezmoi, rbw, gh ([[monkeyimage]], Packages)
- each person brings their identity, and the image never bakes it in: their own dotfiles repo, GitHub account and vault ([[you]], Account)
- the only input nobody else can supply is each person's master password

- [[monkeyworks]]: the front page

---
## Machine

Do these steps in order.
1. install generic Sway Atomic from USB ([Atomic Desktops docs](https://docs.fedoraproject.org/en-US/atomic-desktops/))
2. rebase to the image (switch the system to it) in two hops, with a reboot after each ([rpm-ostree](https://coreos.github.io/rpm-ostree/))
	- `rpm-ostree rebase ostree-unverified-registry:ghcr.io/matta-kelly/monkeyimage:latest`: the first image brings the signing key and policy
	- `rpm-ostree rebase ostree-image-signed:docker://ghcr.io/matta-kelly/monkeyimage:latest`: from here every image is checked
	- the flatpaks install at the first boot ([[monkeyflatpaks]])
3. join the mesh (the private network of our machines, run by headscale): `sudo tailscale up --login-server <your headscale URL> --auth-key <key>`
	- the key is single-use, from whoever runs the headscale server
	- the vault is on the mesh, so this step comes before each person's steps

## Each person

Two things come first:
- a Vaultwarden account (the vault), with a master password only they know
- a dotfiles repo

Then do these steps in order. `monke init` walks them: each step checks first, skips what is done, and asks before it changes anything ([[monke]]).
1. log in to the vault: `rbw config set base_url <your Vaultwarden URL>`, `rbw config set email <email>`, `rbw login` (it asks for the master password)
2. `gh auth login`, HTTPS: this sets up GitHub, and git's credential helper
3. `chezmoi init --apply <their dotfiles repo>`: secret files (SSH keys, cloud creds) come from the vault through rbw templates ([[dotfiles]])
4. start backup. It needs an S3 bucket and key, and two vault items, named as the person's templates expect
	- the address and key: `hetzner-s3-<name>`, with notes = JSON holding `RESTIC_REPOSITORY`, `AWS_DEFAULT_REGION`, `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
	- a long random repository password: `restic-<name>`, in the notes
	- step 3 writes these to `~/.config/restic/`
	- then, once: `set -a; . ~/.config/restic/env; set +a; restic -p ~/.config/restic/password init`
	- then run one backup by hand: `systemctl --user start restic-backup`
	- then restore one file ([[you]], Backup)
5. `restic restore`, when there is data to bring back: the password comes from the vault ([[backup]])
