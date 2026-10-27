# ClipVault

An encrypted, text-only clipboard history with a Shortcuts picker.

- A background watcher (`clipvault watch`, run by a LaunchAgent) records each new text copy.
- History is encrypted with AES-256-GCM. The key is a random 256-bit value in your login Keychain
  (item "ClipVault", account `history-key`). Only ciphertext is written to disk:
  `~/Library/Application Support/ClipVault/history.enc` (folder `700`, file `600`). The folder is
  excluded from Time Machine.
- The key is replaced every 24 hours and deleted by `clear`. Any old copy of the ciphertext, such as
  one in an APFS snapshot, can't be decrypted once its key is gone.
- Copies tagged as concealed or transient (1Password, Bitwarden, Apple Passwords and other apps
  that follow nspasteboard.org) are never recorded.
- The history keeps at most 50 items and drops anything older than 24 hours. Copying the same
  text again moves it to the top instead of duplicating it.

## Install

```sh
./install.sh
```

If macOS asks whether `clipvault` may use the "ClipVault" Keychain item, choose **Always Allow**.
That happens after every rebuild, because the binary's signature changes.

Then build the picker shortcut (Shortcuts can't import an unsigned file without iCloud, so this is manual):

1. Open **Shortcuts → Settings → Advanced** and turn on **Allow Running Scripts**.
2. Create a new shortcut named **Clipboard History** with these four actions:
   1. **Run Shell Script**: Shell `zsh`, Input `Nothing`, script:
      ```sh
      "$HOME/Library/Application Support/ClipVault/clipvault" list
      ```
   2. **Split Text** (the Shell Script Result) by **New Lines**
   3. **Choose from List** (Split Text), prompt "Clipboard history"
   4. **Run Shell Script**: Shell `zsh`, Input **Chosen Item**, Pass Input **to stdin**, script:
      ```sh
      "$HOME/Library/Application Support/ClipVault/clipvault" copy
      ```
3. In the shortcut's details (ⓘ), click **Add Keyboard Shortcut** and pick something like ⌥⌘V.
   Optionally enable **Pin in Menu Bar**.

To use it, press your hotkey, type to filter, press Return, then ⌘V. Each line is a one-line preview
followed by the item's id, such as `[3fa9c1]`. The id makes sure the item you picked is the one copied,
even if the history changed while the picker was open. The full original text, including line breaks,
is copied. Previews have control and formatting characters removed.

## Other commands

```sh
CV="$HOME/Library/Application Support/ClipVault/clipvault"
"$CV" list     # previews, newest first
"$CV" clear    # delete the history and its key now
```

`clear` exits with an error if either deletion fails. To change the limits, edit the constants at the
top of `clipvault.swift` and run `./install.sh` again.

## Troubleshooting

The watcher never shows dialogs. If it can't reach the Keychain, it records nothing, writes the
error once to `~/Library/Application Support/ClipVault/watcher.log`, and keeps retrying. Running
`"$CV" list` in Terminal brings up the access prompt.

## Uninstall

```sh
./uninstall.sh
```

This removes the agent, the binary, the history and the Keychain key. Delete the shortcut in Shortcuts.

## Limits

- Secrets copied from anywhere that doesn't tag them (a terminal, a text file) **are** recorded,
  encrypted, for up to 24 hours. Run `clear` after copying one.
- Deleting data isn't the same as erasing it from the SSD. Until the key that encrypted it is
  replaced (at most 24 hours, or right away with `clear`), anyone who has both your unlocked Keychain
  and an old snapshot of the file could decrypt it. Local snapshots also hold an old copy of the login
  Keychain, which is protected by your login password.
- Any app running as you can still read the *current* clipboard. That's true on every Mac.
