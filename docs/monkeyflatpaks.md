---
type: component
description: "The Apps layer of Monkeyworks: GUI apps as flatpaks, sorted into three bins (both of us, just me, just Jojo), and how each bin is installed with BlueBuild or chezmoi. Reference before adding a GUI app, or when deciding whose app it is."
status: planned
---
The Apps layer of [[monkeyworks]]: every GUI app is a flatpak, and every flatpak sits in one of three bins.
- [[#Bins]] who an app is for, and where its list lives
- [[#How BlueBuild installs them]] the `default-flatpaks` module
- [[#Apps]] the lists
- [[#Open]]

- [[monkeyimage]]: its recipe holds the "both" list
- [[deeotee]]: holds the "just me" list
- [[jojo-onboard]]: holds the "just Jojo" list

### Desk
- open questions
	- does removing an ID from the list uninstall the app? The docs do not say
	- does a derived image's `default-flatpaks` list add to its parent's, or replace it? The Jojo recipe depends on it
	- when do user-scope installs run, relative to login?
	- VS Code as a flatpak is sandboxed ([sandbox permissions](https://docs.flatpak.org/en/latest/sandbox-permissions.html)): [[dev-containers]] needs it to reach the host's Podman. Check, or put VS Code in a distrobox or the image
	- Proton VPN as a flatpak: does it work with system NetworkManager, or does it belong in the image?
---
## Bins

Sorting rule: who uses the app decides the bin, not what the app is.

| Bin           | Where the list lives | Installed by                                  | Scope            |
| ------------- | -------------------- | --------------------------------------------- | ---------------- |
| **Both**      | the [[monkeyimage]] recipe (`recipes/recipe.yml`) | BlueBuild `default-flatpaks`, on every boot   | system: all users |
| **Just me**   | [[deeotee]]          | chezmoi script: `flatpak install --user`      | my user          |
| **Just Jojo** | [[jojo-onboard]]     | her recipe `FROM` monkeyimage, or her dotfiles | her machine or her user |

- "just me" is not in the image: the same image goes to Jojo, so anything in it is hers too
- "just Jojo" depends on one open question: her own machine, or a shared one
	- her own machine: her recipe `FROM` monkeyimage, with its own `default-flatpaks` list, system scope
	- a shared machine: her own dotfiles, the same way as "just me"

## How BlueBuild installs them

The `default-flatpaks` module ([reference](https://blue-build.org/reference/modules/default-flatpaks/)), in the recipe:

```yaml
- type: default-flatpaks
  configurations:
    - scope: system
      install:
        - com.github.tchx84.Flatseal
```

- installs the list on every boot, from Flathub by default; it removes Fedora's flatpak remote
- `scope: system`: one install for every user; managing it needs admin
- `scope: user`: the same list, installed into each user's home. Not a way to give one person their own apps
- Flathub IDs are checked at build time: a wrong ID fails the build, not the boot
- `notify: true` (default): a notification when the boot install starts and ends
- `bluebuild-flatpak-manager`: runs the setup by hand, or turns the boot install off and on

## Apps

The GUI apps on the Arch machine. Flathub IDs checked against Flathub.

- Both
	- `com.github.tchx84.Flatseal`: see and change what each flatpak may reach
- Just me
	- `com.visualstudio.code`: VS Code
	- `dev.zed.Zed`: Zed
- Just Jojo
	- (none yet)
- To sort
	- `com.brave.Browser`: Brave
	- `io.gitlab.librewolf-community`: LibreWolf
	- `com.google.Chrome`: Chrome
	- `md.obsidian.Obsidian`: Obsidian
	- `org.onlyoffice.desktopeditors`: OnlyOffice
	- `com.spotify.Client`: Spotify
	- `org.darktable.Darktable`: darktable
	- `com.protonvpn.www`: Proton VPN
- Not on Flathub
	- goose-desktop, grok-bot, featherpad: another way in, or drop



