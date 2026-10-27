#!/bin/zsh
# Builds a locally signed Shortcut that can be imported into Shortcuts.app.
set -euo pipefail

ROOT="${0:A:h}"
SOURCE="$ROOT/shortcut/Clipboard History.plist"
OUTPUT="$ROOT/build/Clipboard History.shortcut"

if (( $# > 1 )) || { (( $# == 1 )) && [[ $1 != --open ]]; }; then
    echo "usage: ./create-shortcut.sh [--open]" >&2
    exit 1
fi

command -v shortcuts >/dev/null || {
    echo "The macOS shortcuts command is required." >&2
    exit 1
}

plutil -lint "$SOURCE" >/dev/null
mkdir -p "$ROOT/build"

# The signer requires its input to have a .shortcut extension even though the
# source is an ordinary XML property list.
TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/clipvault-shortcut.XXXXXX")"
UNSIGNED="$TEMP_DIR/Clipboard History.shortcut"
trap 'rm -f "$UNSIGNED"; rmdir "$TEMP_DIR"' EXIT
cp "$SOURCE" "$UNSIGNED"

shortcuts sign \
    --mode people-who-know-me \
    --input "$UNSIGNED" \
    --output "$OUTPUT"

echo "Created $OUTPUT"
if (( $# == 1 )); then
    open "$OUTPUT"
else
    echo "Run './create-shortcut.sh --open' or double-click the file to import it."
fi
