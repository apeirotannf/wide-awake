# Caffeine for Mac

A tiny menu bar app that keeps your Mac awake. A clone of [Caffeine](https://www.caffeine-app.net/en/).

- **Click** the cup to switch it on or off. A full cup means your Mac stays awake.
- **Right-click** (or ⌘/⌃-click) for the menu: run it for a set time, pick a default duration, turn on at launch, start at login.
- While on, it blocks idle sleep, screen dimming and the screensaver.

No dependencies. One Swift file, built with Xcode's command line tools. Needs macOS 13 or newer.

## Build

```sh
./build.sh          # makes build/Caffeine.app (Apple silicon + Intel)
./check.sh          # builds, switches it on, checks macOS sees the sleep block
```

Then drag `build/Caffeine.app` into `/Applications`.

The app is signed ad hoc, not notarized. On another Mac, right-click it and choose **Open** the first time.
