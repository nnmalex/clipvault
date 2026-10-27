#!/bin/zsh
# Builds ClipVault and starts the clipboard watcher.
set -euo pipefail
cd "${0:A:h}"

DIR="$HOME/Library/Application Support/ClipVault"
LABEL="local.clipvault"
AGENT="$HOME/Library/LaunchAgents/$LABEL.plist"

umask 077
mkdir -p "$DIR" build
chmod 700 "$DIR"

echo "Building clipvault…"
swiftc -O clipvault.swift -o build/clipvault
install -m 700 build/clipvault "$DIR/clipvault"

echo "Installing LaunchAgent…"
launchctl bootout "gui/$UID/$LABEL" 2>/dev/null || true
cat > "$AGENT" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>$DIR/clipvault</string>
    <string>watch</string>
  </array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>LimitLoadToSessionType</key><string>Aqua</string>
  <key>ProcessType</key><string>Background</string>
  <key>StandardErrorPath</key><string>$DIR/watcher.log</string>
</dict>
</plist>
EOF
chmod 644 "$AGENT"
launchctl bootstrap "gui/$UID" "$AGENT"

echo "Done. The watcher is running. See README.md to create the picker shortcut."
