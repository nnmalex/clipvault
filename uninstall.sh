#!/bin/zsh
# Stops the watcher and removes ClipVault's binary, history, and Keychain keys.
# The "Clipboard History" shortcut has to be deleted in the Shortcuts app.
set -uo pipefail

LABEL="local.clipvault"
DIR="$HOME/Library/Application Support/ClipVault"
AGENT="$HOME/Library/LaunchAgents/$LABEL.plist"
failed=0

# Stop the watcher first and make sure both the job and process are gone, or it could recreate
# the history and key. Verification also handles a failed or interrupted bootout.
launchctl bootout "gui/$UID/$LABEL" 2>/dev/null
for _ in {1..20}; do
    if ! launchctl print "gui/$UID/$LABEL" >/dev/null 2>&1 && ! pgrep -qf "$DIR/clipvault watch"; then
        break
    fi
    sleep 0.25
done
if launchctl print "gui/$UID/$LABEL" >/dev/null 2>&1 || pgrep -qf "$DIR/clipvault watch"; then
    echo "The watcher or its LaunchAgent is still active, so nothing was removed." >&2
    echo "Stop it and run this again." >&2
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
