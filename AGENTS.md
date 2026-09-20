# AGENTS.md — Better Omarchy Bluetooth

Default context for any agent working on this plugin. Read this first.

## What this is

An omarchy shell **bar-widget** plugin: a drop-in replacement for
`omarchy.bluetooth` that adds optional **PIN / passkey entry** when pairing a
device that requires one.

- plugin id: `better-omarchy-bluetooth`
- repo: https://github.com/Akuyumu/better-omarchy-bluetooth (public, `master`)
- git author: Dylan <plasmadylan@gmail.com>; GitHub account: **Akuyumu** (`gh` authed)
- source of truth: `/home/kuyu/Projects/better-omarchy-bluetooth`
- installed copy: `~/.config/omarchy/plugins/better-omarchy-bluetooth`

## Files

| File | Purpose |
|------|---------|
| `manifest.json` | plugin manifest (`bar-widget`, entryPoint `barWidget: Panel.qml`) |
| `Panel.qml` | the panel, based on omarchy's `panels/bluetooth/Panel.qml` |
| `PairPinDialog.qml` | the optional PIN/passkey modal |
| `Model.js` | unchanged helpers copied from `omarchy.bluetooth` |
| `bin/omarchy-bluetooth-pair` | pairing helper; takes `<address> [pin]` |
| `README.md` | user-facing install + capabilities |

## Dev loop

Edit the project, then sync into the installed dir and reload:

```bash
cd /home/kuyu/Projects/better-omarchy-bluetooth
cp Panel.qml PairPinDialog.qml Model.js manifest.json \
  ~/.config/omarchy/plugins/better-omarchy-bluetooth/
omarchy-shell shell rescanPlugins
# restart only if the IPC target or imports changed:
omarchy-restart-shell
```

Validate before committing:

```bash
omarchy plugin validate .
qmllint -I /usr/share/omarchy/shell Panel.qml PairPinDialog.qml
```

Quick smoke test of the panel IPC (opens/closes the popout):

```bash
omarchy-shell better-omarchy-bluetooth open
omarchy-shell better-omarchy-bluetooth close
```

## How it works (and the gotchas)

- Pairing an **unpaired** (discovered) device runs the helper with no PIN first
  (Just Works, like stock omarchy). Only if that fails does the panel open
  `PairPinDialog` to enter a PIN/passkey and retry. A non-empty PIN makes the
  helper start a private `bt-agent -c KeyboardDisplay -p <pinfile>` (which
  requests the default-agent slot) so it can answer `RequestPasskey` /
  `RequestPinCode`. Exit **4** (audio device bonded BLE-only) shows an
  explanation with no PIN field.
- Quickshell 0.3.1's `Quickshell.Bluetooth` exposes **no agent API**, and
  omarchy's `bt-agent` service is stock `-c NoInputNoOutput`. That is why PIN
  handling lives in the external helper, not in QML. Do not rely on overriding
  the system `bt-agent` service; keep the helper self-contained.
- The `IpcHandler { target: ... }` is **hardcoded separately** from the panel's
  `ipcTarget` property — both must read `better-omarchy-bluetooth`.
- `manageIpc: false` so the panel owns its single IpcHandler.
- Third-party plugins may `import qs.Ui` / `import qs.Commons` from the shell.
- Helper path in QML: `decodeURIComponent(Qt.resolvedUrl("bin/omarchy-bluetooth-pair").replace("file://",""))`.
- `PanelKeyCatcher { blocked: root.pairDialogOpen }` so the TextField, not the
  cursor machine, gets keys while the dialog is up.
- The helper must stay executable (`git ls-files -s` → `100755`).

## Environment / test device

- Omarchy 4.0.4, Quickshell 0.3.1, bluez 5.87, PipeWire/WirePlumber.
- Test device: **Divoom Ditoo Pro**. Address changed after a factory reset:
  `B1:21:81:A7:B8:EA` → `B1:21:81:41:0E:09`. **A Divoom reset can randomize the
  address**, so always re-discover rather than reusing an old MAC.
  The device advertises two personalities under the same MAC: `DitooPro-Light`
  (BLE, app/screen) and `DitooPro-Audio` (classic BR/EDR, A2DP speaker). Audio
  needs the classic bond.
- Divoom quirks seen:
  - A stale pairing on the device makes classic pairing fail with
    `org.bluez.Error.AuthenticationRejected` (a corrupt bond gives
    `br-connection-key-missing`). Fix: clear the device's pairing (reset) and
    keep phone Bluetooth off. It then pairs classic via **Just Works** — no PIN.
  - The device only advertises its classic `Audio` side in a fresh/reset state;
    once it has an LE bond it can go `Light`-only. If the panel pairs it while
    it advertises only LE, BlueZ pairs the **BLE** side, which has no A2DP and
    produces no sound. The helper detects this and exits **4** so the panel can
    tell the user to reset the speaker.
  - After pairing classic, `bluetoothctl pair` picks the classic bearer because
    the device advertises `Audio Sink`; no special bearer forcing is needed.

## Current state / TODO

- Ditoo is paired and routing audio; it paired via **Just Works**, so the PIN
  dialog has **not** been exercised against a real PIN-requiring device yet.
  If you get one, verify the private-agent path end to end.
- Revert to stock widget with:
  `omarchy plugin disable better-omarchy-bluetooth && omarchy plugin enable omarchy.bluetooth --section right`.

## Publishing

```bash
git add -A && git commit -m "..."
git push origin master
```

Keep the id `better-omarchy-bluetooth` (do not namespace it).
