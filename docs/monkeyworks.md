---
type: moc
description: "The map of Monkeyworks, the Fedora Sway Atomic machine Jojo and I share: every note, and where each part of the machine is covered. Read it first, to find the note for any part."
status: active
---
Monkeyworks: one Fedora Sway Atomic image, the same on every machine, with each person's own setup on top.
- [[how-it-works]] the model of the whole machine
	- [[how-it-works#Where things live]] each path, what it holds, who owns it
		- [[how-it-works#Files on Atomic]] `/usr` read-only, `/etc` merged, `/var` yours
		- [[how-it-works#Config layering]] vendor, then system, then user; drop-ins
	- [[how-it-works#How things change]] build, update, apply, back up, secrets, setup
		- [[how-it-works#Build]] the recipe becomes the image
- [[machine]] the computer: shared, the same for everyone
	- [[machine#Booting]] · [[machine#Updates and rollback]] · [[machine#Users and login]] · [[machine#Services]]
	- [[machine#Networking]] · [[machine#Power]] · [[machine#Storage]] · [[machine#Printing]]
	- [[monkeyimage]] every package and config file in the image
- [[desktop]] what you see and use
	- [[desktop#Sway]] · [[desktop#Bar, launcher, notifications]] · [[desktop#Screens]] · [[desktop#Input]]
	- [[desktop#Sound]] · [[desktop#Appearance]] · [[desktop#Apps]]
	- [[monkeyflatpaks]] the apps, in three bins
- [[you]] what is yours alone
	- [[you#Account]] · [[you#Dotfiles]] · [[you#Secrets]] · [[you#Backup]] · [[you#Shell and terminal]]
	- [[backup]] the nightly backup, and how to restore
		- [[restic]] the tool behind it
- [[setup]] a new machine, then a new person
- [[#Machines]] where it runs

---
## Machines
- mine: monkeyworks (ThinkPad)
- Jojo's: the same image and app lists, her own setup through [[setup]], and what only she gets (apps, keyboard, her entry point): [[jojo-onboard]]
