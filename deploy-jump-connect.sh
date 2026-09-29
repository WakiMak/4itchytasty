#!/bin/bash
#
# postinstall: Install Jump Desktop Connect and enroll the Mac in your team
#
# Designed to run as the postinstall script of a custom .pkg deployed through
# Apple Business Essentials (which has no script option, but supports
# preinstall/postinstall scripts inside packages).
#
# Also works standalone:  sudo ./deploy-jump-connect.sh
#
# ---------------------------------------------------------------------------
# EDIT THESE TWO VALUES BEFORE PACKAGING
# ---------------------------------------------------------------------------

# From the Jump Teams dashboard: Add Computers -> Mac OS (PKG) -> copy link.
# This is the PRE-CONFIGURED installer with your Connect Code embedded in the
# filename. Do NOT rename the downloaded file - Connect reads the code from it.
INSTALLER_URL="https://REPLACE-WITH-YOUR-TEAM-INSTALLER-URL.pkg"

# Fallback: your Connect Code with spaces removed (shown in Add Computers as
# e.g. "123 456 789" -> enter "123456789"). Used only if Connect is already
# installed on the Mac.
CONNECTCODE="REPLACE_WITH_CONNECT_CODE"

# ---------------------------------------------------------------------------
# No edits needed below this line
# ---------------------------------------------------------------------------

set -euo pipefail
JDC_APP="/Applications/Jump Desktop Connect.app"
JDC_BIN="${JDC_APP}/Contents/MacOS/JumpConnect"
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

log() { echo "[jump-deploy] $*"; }

# --- Case 1: Connect already installed -> just apply the Connect Code -------
if [[ -x "$JDC_BIN" ]]; then
  log "Jump Desktop Connect already installed; applying Connect Code."
  "$JDC_BIN" --connectcode "$CONNECTCODE"
  log "Done. This Mac is enrolled."
  exit 0
fi

# --- Case 2: Fresh install -> download and run the pre-configured PKG --------
log "Downloading pre-configured installer..."
# -O preserves the filename, which contains the embedded Connect Code.
curl -fsSL -o "$WORKDIR/" -O "$INSTALLER_URL"

PKG_PATH="$(find "$WORKDIR" -name '*.pkg' -print -quit)"
if [[ -z "$PKG_PATH" ]]; then
  log "ERROR: no .pkg found after download. Check INSTALLER_URL."
  exit 1
fi

log "Installing $(basename "$PKG_PATH")..."
installer -pkg "$PKG_PATH" -target /

# --- Verify -------------------------------------------------------------------
if [[ -x "$JDC_BIN" ]]; then
  log "Jump Desktop Connect installed successfully."
else
  log "ERROR: install ran but $JDC_BIN not found."
  exit 1
fi

exit 0
