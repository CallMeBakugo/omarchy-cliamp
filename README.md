# CLIamp Radio — Omarchy bar widget

A bar widget for [Omarchy](https://omarchy.org) that puts [cliamp](https://cliamp.stream) playback in your bar: a play/pause chip that always shows the current state, with the track / artist / station on hover. Built for Omarchy Radio, works with anything cliamp plays.

## What it does

- ▶ / ⏸ icon in the bar, always visible, click to toggle playback
- Hover tooltip: current track — artist • station
- Polls `cliamp status --json` every 2 s; hides itself only when cliamp isn't running at all
- Works against the cliamp TUI **or** the headless daemon (`cliamp --daemon`)

## Install

```bash
omarchy plugin add https://github.com/CallMeBakugo/omarchy-cliamp
```

Then place the widget: `omarchy bar put bakugo.cliamp --section right --after omarchy.tray`

## Recommended: run cliamp headless

The widget is most useful when cliamp doesn't need a terminal open. Install the bundled systemd user service:

```bash
cp cliamp-daemon.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now cliamp-daemon.service
```

That runs `cliamp --daemon --playlist "Favorites" --auto-play` at login (edit the service to change the playlist). Notes:

- The TUI and the daemon are mutually exclusive — both want `~/.config/cliamp/cliamp.sock`. Stop the daemon (`systemctl --user stop cliamp-daemon`) before launching the TUI, and vice versa.
- The widget talks to whichever one owns the socket; nothing else changes.

## Requirements

- [Omarchy](https://omarchy.org) (tested on 4.0.4)
- [cliamp](https://cliamp.stream) v2.0+ installed and in `$PATH`

## How it works

The widget shells out to `cliamp status --json` on a 2 s timer (Quickshell `Process` + `StdioCollector`) and renders a `BarIconButton` with `Quickshell.execDetached` for the play/pause command. No extra daemons of its own, no socket protocol code — cliamp's CLI is the interface.

One quirk worth knowing: cliamp's `toggle` subcommand cycles playing → paused → *stopped*, so a second click would kill the stream. The widget therefore sends `toggle` only while playing and `play` to resume.

## License

MIT
