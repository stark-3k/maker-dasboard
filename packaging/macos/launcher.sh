#!/bin/bash
# Launcher for the Maker Dashboard .app bundle.
#
# A double-clicked .app runs with the working directory set to "/", so the
# server's default *relative* frontend path (frontend/build/client) would not
# resolve. This script points the server at the assets bundled inside the .app
# using absolute paths, then execs the real binary.

set -e

# Directory of this script: <App>.app/Contents/MacOS
HERE="$(cd "$(dirname "$0")" && pwd)"
RESOURCES="$HERE/../Resources"

# A double-clicked .app runs with the working directory set to "/", which on
# modern macOS is a sealed, READ-ONLY system volume. Any dependency that writes
# to a path relative to the CWD (e.g. embedded Tor, coinswap data) would then
# fail with "Read-only file system (os error 30)". cd into a writable directory
# so stray relative writes land somewhere safe.
cd "$HOME" || cd /tmp

# Serve the frontend that ships inside the bundle.
export MAKER_DASHBOARD_FRONTEND_PATH="$RESOURCES/frontend"
export MAKER_DASHBOARD_SPA_INDEX="$RESOURCES/frontend/index.html"

# ---------------------------------------------------------------------------
# To change the port the dashboard listens on, uncomment and edit the line
# below, then re-open the app. (Default is 3000.)
# export MAKER_DASHBOARD_PORT=8080
# ---------------------------------------------------------------------------

exec "$HERE/maker-dashboard"
