<p align="center">
  <img src="https://roachnet.org/assets/readme/homebrew-roachnet.png" width="100%" alt="RoachNet Brew, the Homebrew tap: brew install --cask roachnet.">
</p>

# RoachNet Brew

The Homebrew tap for [RoachNet](https://roachnet.org/), the offline-first Mac app for local AI, code, maps, media and your vault. The cask installs the same release as the disk image and keeps your data across upgrades.

**roachnet 1.1.2** · Apple Silicon, macOS 14 or later · [Homebrew guide](https://roachnet.org/docs/get-started/homebrew/)

## Install

```sh
brew tap --force RoachWares/roachnet
brew install --cask roachnet
open ~/RoachNet/app/RoachNet.app
```

## What the cask does

It's more than a `brew install` in a trenchcoat. The cask runs RoachNet's own installer:

1. It downloads `RoachNet-Setup-macOS.dmg` from the [RoachNet release](https://github.com/RoachWares/RoachNet/releases/latest) and checks it against the SHA-256 in the cask.
2. It puts RoachNet Setup in `~/RoachNet/setup` and runs its headless installer: the same install the Setup app does, with the companion bridge left off.
3. The app lands in `~/RoachNet/app` and your data in `~/RoachNet/storage`. Existing storage is kept.

The companion bridge stays off until you turn it on in the app, which you only need to pair a phone.

## Upgrade and remove

```sh
brew upgrade --cask roachnet
```

An upgrade runs the installer over the existing install and keeps `~/RoachNet/storage`.

```sh
# removes RoachNet Setup; the app and ~/RoachNet/storage stay
brew uninstall --cask roachnet
```

> [!WARNING]
> `brew uninstall --zap --cask roachnet` also moves `~/RoachNet` to the Trash, your data included, along with RoachNet's settings. Copy `~/RoachNet/storage` somewhere first if you want to keep it.

If `brew update` shows an error for `roachwares/roachnet`, run this once:

```sh
brew update-reset "$(brew --repo roachwares/roachnet)"
```

## What's in this repository

`Casks/roachnet.rb`, the cask, and nothing else. It changes with each RoachNet release.

## Help

Email [support@roachwares.org](mailto:support@roachwares.org). For anything about security, please don't post it in public. [Documentation](https://roachnet.org/docs/).

---

<sub>Made by RoachWares LLC. RoachNet · offline on purpose.</sub>
