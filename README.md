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

Each run is written as a separated block, with the newest run at the top of the file. When the current log grows beyond 1 MB, it rotates to `demo-sync.log.1`; the script keeps three rotated logs. The script uses a lock directory at `/tmp/icloud-sync-demo.lock` so two sync runs do not overlap.

The script also updates this heartbeat file on every invocation:

```text
$HOME/.local/share/icloud-sync/state/demo-sync.last-run
```

The health-check script sends a macOS notification if that heartbeat is older than two hours. To avoid notification spam, it sends at most one alert per hour while the sync remains stale. Health-check logs are written to `$HOME/.local/share/icloud-sync/logs/demo-sync-health.log` and use the same 1 MB rotation policy.

Install the LaunchAgent template:

```zsh
cp "$HOME/projects/icloud-sync/launchd/com.mor.icloud-sync-demo.plist" \
  "$HOME/Library/LaunchAgents/com.mor.icloud-sync-demo.plist"
launchctl bootstrap "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.mor.icloud-sync-demo.plist"
launchctl enable "gui/$(id -u)/com.mor.icloud-sync-demo"
launchctl kickstart -k "gui/$(id -u)/com.mor.icloud-sync-demo"
```

Install the health-check LaunchAgent template:

```zsh
cp "$HOME/projects/icloud-sync/launchd/com.mor.icloud-sync-demo-health.plist" \
  "$HOME/Library/LaunchAgents/com.mor.icloud-sync-demo-health.plist"
launchctl bootstrap "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.mor.icloud-sync-demo-health.plist"
launchctl enable "gui/$(id -u)/com.mor.icloud-sync-demo-health"
launchctl kickstart -k "gui/$(id -u)/com.mor.icloud-sync-demo-health"
```

Because the script does not use `--delete`, files that exist only in `$HOME/icloud/projects/demo/` remain untouched.
