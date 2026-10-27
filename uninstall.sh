#!/bin/zsh
# Stops the watcher and removes ClipVault's binary, history, and Keychain key.
# The "Clipboard History" shortcut has to be deleted in the Shortcuts app.
set -uo pipefail

LABEL="local.clipvault"
launchctl bootout "gui/$UID/$LABEL" 2>/dev/null
rm -f "$HOME/Library/LaunchAgents/$LABEL.plist"
rm -rf "$HOME/Library/Application Support/ClipVault"
security delete-generic-password -s ClipVault -a history-key >/dev/null 2>&1
echo "ClipVault removed."
