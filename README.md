icloud-sync contains scripts and notes for reproducible local-to-iCloud sync and machine recovery.

## Minimal Demo

This demo mirrors a local source folder to an iCloud destination without deleting destination-only files.

```text
source      = $HOME/projects/demo/
destination = $HOME/icloud/projects/demo/
```

Run a dry run first:

```zsh
rsync -av --dry-run "$HOME/projects/demo/" "$HOME/icloud/projects/demo/"
```

Run the sync script manually:

```zsh
"$HOME/projects/icloud-sync/scripts/sync-demo-to-icloud"
```

The script logs to:

```text
$HOME/.local/share/icloud-sync/logs/demo-sync.log
```

It uses a lock directory at `/tmp/icloud-sync-demo.lock` so two sync runs do not overlap.

Install the LaunchAgent template:

```zsh
cp "$HOME/projects/icloud-sync/launchd/com.mor.icloud-sync-demo.plist" \
  "$HOME/Library/LaunchAgents/com.mor.icloud-sync-demo.plist"
launchctl bootstrap "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.mor.icloud-sync-demo.plist"
launchctl enable "gui/$(id -u)/com.mor.icloud-sync-demo"
launchctl kickstart -k "gui/$(id -u)/com.mor.icloud-sync-demo"
```

Because the script does not use `--delete`, files that exist only in `$HOME/icloud/projects/demo/` remain untouched.
