# Better Omarchy Bluetooth — an omarchy bar widget

A drop-in replacement for omarchy's built-in Bluetooth panel that adds
**PIN / passkey entry** when pairing devices that require one.

Omarchy's stock pairing path runs `bluetoothctl pair` with no PIN-capable
agent, and its `bt-agent` service is hard-coded to `NoInputNoOutput`. A device
that asks for a PIN (many speakers, car kits, and older headsets) therefore
fails with:

```
Failed to pair: org.bluez.Error.AuthenticationRejected
```

…and the bar widget has nowhere to type the code. This plugin fixes that: when
you pair a new device, a small dialog asks for an optional PIN/passkey and, if
you provide one, pairing runs through a private PIN-aware agent.

## Install

Requires `omarchy` 4.x and the `bluez-tools` package (already pulled in by
omarchy, since it ships the `bt-agent` service).

```bash
omarchy plugin add https://github.com/<you>/better-omarchy-bluetooth.git --enable
```

Then replace the built-in widget:

```bash
omarchy plugin disable omarchy.bluetooth
# enable our widget in the bar section you want (right is the default)
omarchy plugin enable better-omarchy-bluetooth
```

`omarchy plugin add … --enable` already places the widget (default section
`right`). Disabling `omarchy.bluetooth` removes the duplicate.

To update later:

```bash
omarchy plugin update better-omarchy-bluetooth
```

## Capabilities

Everything the stock panel does, plus PIN pairing:

- Toggle Bluetooth on/off (hero switch, `b`, or right-click the bar icon).
- List connected, paired, and discovered devices while scanning.
- Click / `Enter` to connect or disconnect; `x` to forget a device.
- Route audio to a connected speaker automatically.
- **Pair a new device with an optional PIN/passkey.** Activating an unpaired
  (discovered) device opens a *Pair device* dialog:
  - leave the field blank → pairs exactly like stock omarchy;
  - enter the PIN/passkey → pairs through a PIN-aware agent.

Keyboard: `j`/`k` move, `Enter`/`Space` activate, `Esc` closes,
`Tab` switches panels. While the PIN dialog is open the keyboard belongs to it
(`Esc` cancels, `Enter` submits).

## Where the PIN comes from

Devices with a user-set PIN show it in their own app (e.g. the Divoom app for
Divoom speakers: *Profile → Add Device*). Some devices instead display a
6-digit passkey on their screen and expect you to type it on the computer —
use that number. Leave the field blank for devices that pair with no code.

## How it works

`bin/omarchy-bluetooth-pair <address> [pin]`:

1. powers the adapter on through `omarchy-bluetooth-power`,
2. trusts the device,
3. with a PIN, starts a private `bt-agent -c KeyboardDisplay -p <pinfile>`
   that requests the default-agent slot and answers the device's
   `RequestPasskey` / `RequestPinCode`,
4. runs `bluetoothctl pair` (then `connect`) and exits non-zero on failure,
5. hands the default-agent slot back to omarchy's `bt-agent` service.

Without a PIN it is behaviourally identical to
`omarchy-bluetooth-device pair`.

## Files

```
manifest.json          plugin manifest (bar-widget)
Panel.qml              the panel (based on omarchy.bluetooth's Panel.qml)
PairPinDialog.qml      the PIN/passkey modal
Model.js               unchanged helpers from omarchy.bluetooth
bin/omarchy-bluetooth-pair   pairing helper with optional PIN
```

## Notes / limitations

- PIN pairing depends on `bt-agent` from `bluez-tools`. If it is missing, PIN
  pairing exits with an explanatory error; PIN-less pairing still works.
- A device that refuses to pair even with the correct PIN usually still holds
  a stale pairing of its own — clear it on the device (or factory reset it)
  and try again.
- The plugin id is `better-omarchy-bluetooth`; rename it in `manifest.json` and
  `Panel.qml` (`moduleName` / `ipcTarget`) if you publish under another name.

## License

MIT
