# Aircon

A menu bar app for the Daikin split units sold in Brazil (the ones paired with the **Daikin Smart AC** app). It talks to them directly over the local network: no cloud, no account.

## How the units talk

Each unit announces itself over Bonjour as `_iota._tcp` and serves plain HTTP on port 15914:

- `GET /acstatus` returns the state; `POST /acstatus` changes it and returns the new state.
- Bodies are `base64(iv ‖ AES-128-CFB(json) ‖ crc16)`. Responses add one length byte after the IV; commands end their JSON with a literal `BZ`.
- The key is per unit. The Daikin app shows it under **Menu → Integrations → Home Assistant**.

This follows Daikin Brasil's own [Home Assistant integration](https://github.com/daikin-br/ha-custom-integration) and [crossworth/daikin](https://github.com/crossworth/daikin).

## Layout

| Path | What |
|---|---|
| `Packages/AirconKit` | Protocol, transport, discovery, storage and the observable `Home`/`Room` models. No UI. |
| `Aircon/App` | AppKit shell: status item, panel, launch options, wiring. |
| `Aircon/UI` | SwiftUI views. `Hero/` is the unit, airflow and ruler; `Design/` holds the tokens. |

## Build and install

Needs Xcode 27 and XcodeGen.

```sh
scripts/install.sh                      # test, build Release, install to /Applications
scripts/install.sh --import units.json  # …and add units to the keychain
```

`units.json` is `[{"name": "Living room", "host": "DAIKIN123ABC.local", "key": "…"}]`. Units can also be added in the app.

## Resource use

- With the panel closed: one status request per unit every 2 minutes, no animation, no timers otherwise.
- With the panel open: a refresh every 4 seconds; the airflow animation runs only while the selected unit is on.

## Development switches

| Variable | Effect |
|---|---|
| `AIRCON_DEMO=1` | Fake units; no network or keychain. |
| `AIRCON_DEVICES_FILE=<path>` | Read units from a file instead of the keychain. |
| `AIRCON_SHOW=controls\|settings` | Open the panel on launch. |
| `AIRCON_ROOM=<name>` | Select that room first. |
| `AIRCON_LIVE=<path>` | Tests: also run against real units (reads all, nudges one setpoint and restores it). |
