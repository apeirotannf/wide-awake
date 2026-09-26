# Wide Awake

A tiny menu bar app that keeps your Mac awake, shown as a pair of eyes. Inspired by [Caffeine](https://www.caffeine-app.net/en/).

- **Click** the eyes in the menu bar to switch it on or off. Open eyes mean your Mac stays awake. Closed eyes mean it can sleep.
- On a timer, the eyes get sleepy as time runs out. While awake, they follow your pointer. Reduce Motion keeps them still.
- **Right-click** (or ⌘/⌃-click) for the menu: run it for a set time, pick a default duration, turn on at launch, start at login.
- While on, it blocks idle sleep, screen dimming and the screensaver.

No dependencies. One Swift file plus an icon made in Icon Composer (`AppIcon.icon`).

Runs on macOS 11 or newer, on Apple silicon and Intel. "Start at Login" appears on macOS 13 and newer.

## Build

Needs Xcode 26 or newer, for the Liquid Glass icon.

```sh
./build.sh          # makes "build/Wide Awake.app" (Apple silicon + Intel)
./check.sh          # builds, switches it on, checks macOS sees the sleep block
```

Then drag `build/Wide Awake.app` into `/Applications`.

## Copying to another Mac

Copy `Wide Awake.app` over with a USB drive or file sharing and it opens right away.

If it arrives by AirDrop, email or download, macOS warns the first time. The app is signed ad hoc, not notarized by Apple. To open it anyway:

- **macOS 15 and newer:** open it once, then go to System Settings → Privacy & Security and click **Open Anyway**.
- **macOS 11 to 14:** right-click the app and choose **Open**.
