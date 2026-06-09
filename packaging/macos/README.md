# macOS .dmg

Package Maker Dashboard as a double-clickable `.app` distributed in a `.dmg`.

## Build

From the project root:

```sh
make dmg
```

This builds the frontend and the release binary, assembles `Maker Dashboard.app`,
and writes `target/maker-dashboard-<version>.dmg`.

Build prerequisites are the same as a normal backend build (see the main
README) — Tor is compiled into the binary via `libtor`, so the resulting app is
self-contained.

## What's inside the bundle

```
Maker Dashboard.app/
  Contents/
    Info.plist                     bundle metadata (executable = launcher)
    MacOS/
      launcher                     sets bundle-relative paths, execs the binary
      maker-dashboard              the release binary
    Resources/
      frontend/                    built frontend assets (index.html, ...)
```

The launcher is required because a double-clicked `.app` runs with the working
directory set to `/`, which would break the server's default *relative*
frontend path. The launcher exports absolute `MAKER_DASHBOARD_FRONTEND_PATH` /
`MAKER_DASHBOARD_SPA_INDEX` values pointing inside the bundle.

## Usage

1. Open the `.dmg` and drag the app to `/Applications` (or run it in place).
2. Double-click the app. The server starts in the background.
3. Open <http://127.0.0.1:3000>.

## Changing the port

The default port is `3000`. To change it without rebuilding, edit the launcher
inside the bundle and uncomment the `MAKER_DASHBOARD_PORT` line:

```sh
nano "/Applications/Maker Dashboard.app/Contents/MacOS/launcher"
# uncomment:  export MAKER_DASHBOARD_PORT=8080
```

Or launch from Terminal with the env var set:

```sh
MAKER_DASHBOARD_PORT=8080 "/Applications/Maker Dashboard.app/Contents/MacOS/launcher"
```

## Notes / limitations

- **Architecture:** `make dmg` builds for the host architecture only. Intel
  Macs need a separate build (or build a universal binary with `lipo`).
- **Code signing:** the app is unsigned. On first launch Gatekeeper will block
  it — right-click the app and choose **Open**, then confirm. For wider
  distribution, sign and notarize with an Apple Developer ID.
- **No window:** this wraps a local web server, not a native GUI. Double-click
  starts it; there is no app window. Quit via Force Quit (or `pkill
  maker-dashboard`). Auto-opening the browser is intentionally not done; open
  the URL above manually.
- **Read-only file system (os error 30):** a double-clicked app runs with its
  working directory set to `/`, which is read-only on modern macOS. The
  launcher `cd`s into `$HOME` before starting the server to avoid this; do not
  remove that line.
