# homebrew-roachnet

Homebrew tap for installing RoachNet on Apple Silicon Macs.

## Install

```bash
brew update
brew tap --force RoachWares/roachnet
brew install --cask roachnet
open ~/RoachNet/app/RoachNet.app
```

RoachNet lands in `~/RoachNet/app/RoachNet.app` so the app, storage, and local tools stay grouped inside the RoachNet folder instead of scattering across the machine.

The Homebrew lane also writes the contained RoachNet config automatically, disables the companion bridge on first boot, skips the launch intro, and stages the compiled runtime in `~/RoachNet/storage/state/runtime-cache` so a fresh Apple Silicon install does not depend on host Homebrew dylibs.

Current desktop build notes:

- RoachClaw can be opened from anywhere in the native app and from the global command bar, with voice prompts routed through the same permissioned context controls.
- RoachBrain compiles saved memories into an Obsidian-readable local wiki inside the selected RoachNet storage root for RAG-style context without a cloud handoff.
- Vault content opens in built-in reader/player/preview lanes instead of bouncing everything out to Finder.
- Dev Studio keeps project context, editor state, inline RoachClaw assist, and shell context in one contained IDE desk.
- Published macOS DMG SHA-256 for `v1.0.5`: `332057c4f85d136882971957d907bec82e7657833272d30d0849990590e1d122`.
