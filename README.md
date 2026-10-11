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

Starting with 1.0.6 the cask runs RoachNet Setup's native installer (`roachnet-runtime --install`), the same staged install the Setup app performs: Apple Silicon and macOS checks, a contained Ollama runner, a smoke test of the new runtime before it replaces the old one, and storage preserved across upgrades. No Node runtime, source tree, or host Homebrew dylibs are involved. The companion bridge stays off until you enable it in the app.

Current desktop build notes:

- RoachClaw can be opened from anywhere in the native app and from the global command bar, with voice prompts routed through the same permissioned context controls.
- RoachBrain compiles saved memories into an Obsidian-readable local wiki inside the selected RoachNet storage root for RAG-style context without a cloud handoff.
- Vault content opens in built-in reader/player/preview lanes instead of bouncing everything out to Finder.
- Dev Studio keeps project context, editor state, inline RoachClaw assist, and shell context in one contained IDE desk.
- Published macOS DMG SHA-256 for `v1.0.5`: `332057c4f85d136882971957d907bec82e7657833272d30d0849990590e1d122`.
- Published macOS DMG SHA-256 for `v1.0.6` (native Swift runtime): `b6a31dc48faf6a48822bb6770fc8958473c2e0bed460e5ca131f9ab460a90a6f`.
- Published macOS DMG SHA-256 for `v1.0.7` (native Swift runtime; security patch for 1.0.6): `2ccf51663fa559f3461304c7f2644e697483eccd9543734ee684b87c4c2bf6e3`. Ad-hoc signed, not Apple-notarized; the cask clears the quarantine flags on the setup app before it runs the installer.
