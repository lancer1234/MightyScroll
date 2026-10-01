# MightyScroll — Mighty Mouse scrolling for macOS

Make your Mighty Mouse feel at home on a modern Mac.

**English** · [繁體中文](README.zh-TW.md)

MightyScroll is a free, open-source macOS menu bar app for the Apple Mighty Mouse. Reverse mouse scrolling independently of your trackpad, and adjust scroll acceleration and momentum. Developed and tested with the A1197 wireless Mighty Mouse.

Developed independently by **MAKOTO LAB**.

## Features

- Separate scroll directions for your mouse and trackpad.
- Independent vertical and horizontal settings.
- Precise slow scrolling, with acceleration when you roll quickly and repeatedly.
- Smooth momentum between quick rolls and after you stop.
- Adjustable scroll amount, acceleration, and momentum.
- Automatic recovery when your mouse reconnects.
- Launch at login, with a native interface and light and dark appearance.

## Getting started

Requires **macOS 13.5 or later** and **Xcode**. The app is currently distributed as source code.

1. Download or clone this repository and open `MightyScroll.xcodeproj` in Xcode.
2. Select **MightyScroll → My Mac** and build the app. Move the built `MightyScroll.app` to **Applications**, then open it there.
3. Allow **Accessibility** access in **System Settings → Privacy & Security**. Input Monitoring may also be needed for raw wheel input.
4. Keep your preferred trackpad direction in macOS, then adjust your mouse through MightyScroll’s menu bar icon.

You can control automatic startup with **Launch at Login** in the app’s settings.

## Common questions

**Can I reverse mouse scrolling without changing my trackpad?**

Yes. Keep your preferred natural scrolling setting in macOS and change the mouse direction in MightyScroll.

**Does MightyScroll work with Magic Mouse?**

Magic Mouse compatibility has not been verified. The tested device is the A1197 wireless Mighty Mouse.

**Is MightyScroll free and open source?**

Yes. The source code is available under the MIT license. Sponsorship is optional.

## Compatibility & privacy

Developed and tested with the **A1197 wireless Mighty Mouse**, including Bluetooth reconnection. Other mice and apps have not been fully tested. Middle-button and side-squeeze remapping are not included.

No network requests, telemetry, or keyboard monitoring. Your settings stay on your Mac.

For build details, compatibility notes, and troubleshooting, see the [developer notes](docs/DEVELOPMENT.md).

## Feedback

Found a problem? [Open an issue](https://github.com/lancer1234/MightyScroll/issues) with your macOS version, mouse model, affected app, and steps to reproduce it.

## Support MAKOTO LAB

I build MightyScroll in my own time. If it makes your mouse more enjoyable to use, you can help fund development and additional test hardware.

[☕ Buy me a coffee](https://buymeacoffee.com/MakotoLab)

Support is optional and does not purchase features or priority support.

## About MAKOTO LAB

MAKOTO LAB is an independent experimental software and hardware studio exploring unusual, discontinued, and emerging computing platforms. Through custom software and new interactions, I explore what these devices can still do today.

You can also explore [Makoto Glass](https://github.com/lancer1234/MakotoGlass-Beta), a project bringing iPhone integration to Google Glass.

[Instagram · @d.wang\_\_\_](https://www.instagram.com/d.wang___/) · [Buy Me a Coffee](https://buymeacoffee.com/MakotoLab)

## License

[MIT](LICENSE). MightyScroll is an independent project and is not affiliated with Apple.
