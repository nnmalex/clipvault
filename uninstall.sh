#!/bin/zsh
# Stops the watcher and removes ClipVault's binary, history, and Keychain keys.
# The "Clipboard History" shortcut has to be deleted in the Shortcuts app.
set -uo pipefail

LABEL="local.clipvault"
DIR="$HOME/Library/Application Support/ClipVault"
AGENT="$HOME/Library/LaunchAgents/$LABEL.plist"
failed=0

# Stop the watcher first and make sure it's gone, or it could recreate the history and key.
if launchctl print "gui/$UID/$LABEL" >/dev/null 2>&1; then
    launchctl bootout "gui/$UID/$LABEL"
fi
for _ in {1..20}; do
    pgrep -qf "$DIR/clipvault watch" || break
    sleep 0.25
done
if pgrep -qf "$DIR/clipvault watch"; then
    echo "The watcher is still running, so nothing was removed. Quit it and run this again." >&2
    exit 1
fi

rm -f "$AGENT" || failed=1
rm -rf "$DIR" || failed=1

for account in history-key history-key-next; do
    security delete-generic-password -s ClipVault -a "$account" >/dev/null 2>&1
    rc=$?
    # 44 means the item doesn't exist.
    if (( rc != 0 && rc != 44 )); then
        echo "Could not delete Keychain item ClipVault/$account (security exit $rc)." >&2
        failed=1
    fi
done

if (( failed )); then
    echo "ClipVault was only partly removed; see the errors above." >&2
    exit 1
fi
echo "ClipVault removed."
