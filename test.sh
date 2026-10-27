#!/bin/zsh
set -euo pipefail
cd "${0:A:h}"

TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/clipvault-tests.XXXXXX")"
TEST_SERVICE="ClipVaultTest.$$"
WATCHER=""
cleanup() {
    [[ -n $WATCHER ]] && kill "$WATCHER" 2>/dev/null
    security delete-generic-password -s "$TEST_SERVICE" -a history-key >/dev/null 2>&1
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

swiftc -warnings-as-errors \
    clipvault.swift tests/main.swift -o "$TEMP_DIR/clipvault-tests"
"$TEMP_DIR/clipvault-tests"

swiftc -warnings-as-errors -O clipvault.swift main.swift -o "$TEMP_DIR/clipvault"
if "$TEMP_DIR/clipvault" invalid >"$TEMP_DIR/stdout" 2>"$TEMP_DIR/stderr"; then
    echo "Invalid command unexpectedly succeeded." >&2
    exit 1
fi
grep -qx "usage: clipvault watch | list | copy | clear" "$TEMP_DIR/stderr"

# The watcher must fail fast instead of waiting on the login Keychain's "allow access" prompt.
# The item is created by `security`, so the test binary isn't on its access list and reading it
# would normally prompt. The watcher reads the Keychain on its first maintenance pass.
security add-generic-password -A -s "$TEST_SERVICE" -a history-key -w 0123456789abcdef0123456789abcdef
CLIPVAULT_DIR="$TEMP_DIR/data" CLIPVAULT_KEYCHAIN_SERVICE="$TEST_SERVICE" \
    "$TEMP_DIR/clipvault" watch 2>"$TEMP_DIR/watch.log" &
WATCHER=$!
for _ in {1..20}; do
    grep -q "Keychain read failed" "$TEMP_DIR/watch.log" && break
    sleep 0.25
done
kill "$WATCHER"
WATCHER=""
if ! grep -q "Keychain read failed" "$TEMP_DIR/watch.log"; then
    echo "The watcher blocked on a Keychain prompt instead of failing." >&2
    exit 1
fi

zsh -n install.sh uninstall.sh create-shortcut.sh test.sh
plutil -lint "shortcut/Clipboard History.plist" >/dev/null

echo "All tests passed."
