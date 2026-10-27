#!/bin/zsh
set -euo pipefail
cd "${0:A:h}"

TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/clipvault-tests.XXXXXX")"
trap 'rm -rf "$TEMP_DIR"' EXIT

swiftc -warnings-as-errors \
    clipvault.swift tests/main.swift -o "$TEMP_DIR/clipvault-tests"
"$TEMP_DIR/clipvault-tests"

swiftc -warnings-as-errors -O clipvault.swift main.swift -o "$TEMP_DIR/clipvault"
if "$TEMP_DIR/clipvault" invalid >"$TEMP_DIR/stdout" 2>"$TEMP_DIR/stderr"; then
    echo "Invalid command unexpectedly succeeded." >&2
    exit 1
fi
grep -qx "usage: clipvault watch | list | copy | clear" "$TEMP_DIR/stderr"

zsh -n install.sh uninstall.sh create-shortcut.sh test.sh
plutil -lint "shortcut/Clipboard History.plist" >/dev/null

echo "All tests passed."
