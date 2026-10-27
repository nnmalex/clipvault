# ClipVault

An encrypted, text-only clipboard history with a Shortcuts picker.

- A background watcher (`clipvault watch`, run by a LaunchAgent) records each new text copy.
- History is encrypted with AES-256-GCM. The key is a random 256-bit value in your login Keychain
  (item "ClipVault", account `history-key`). Only ciphertext is written to disk:
  `~/Library/Application Support/ClipVault/history.enc` (folder `700`, file `600`).
- Copies tagged as concealed or transient (1Password, Bitwarden, Apple Passwords and other apps
  that follow nspasteboard.org) are never recorded.
- The history keeps at most 50 items and drops anything older than 24 hours. Copying the same
  text again moves it to the top instead of duplicating it.

## Install

```sh
./install.sh
```

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

To use it, press your hotkey, type to filter, press Return, then ⌘V. The picker shows a one-line preview,
but the full original text (including line breaks) is copied.

## Other commands

```sh
CV="$HOME/Library/Application Support/ClipVault/clipvault"
"$CV" list     # previews, newest first
"$CV" clear    # wipe the history now
```

To change the limits, edit the constants at the top of `clipvault.swift` and run `./install.sh` again.

## Uninstall

```sh
./uninstall.sh
```

This removes the agent, the binary, the history and the Keychain key. Delete the shortcut in Shortcuts.

## Limits

- Secrets copied from anywhere that doesn't tag them (a terminal, a text file) **are** recorded,
  encrypted, for up to 24 hours. Run `clear` after copying one.
- Any app running as you can still read the *current* clipboard. That's true on every Mac.
- Each rebuild changes the binary's signature, so macOS may ask once to let `clipvault` use the
  Keychain item. Choose **Always Allow**.
