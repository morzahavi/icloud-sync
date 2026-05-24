icloud-sync contains scripts and notes for reproducible local-to-iCloud sync and machine recovery.

## Minimal Demo

This macOS demo mirrors a local source folder to an iCloud destination without deleting destination-only files.

```text
source      = $HOME/projects/demo/
destination = $HOME/icloud/projects/demo/
```

## Requirements

- macOS with iCloud Drive enabled.
- The `$HOME/icloud` path should point to iCloud Drive.
- `rsync`, `zsh`, `launchctl`, `pmset`, and `osascript` should be available.

## Download

Clone the repo and enter it:

```zsh
git clone https://github.com/morzahavi/icloud-sync.git
cd icloud-sync
```

## Try It Manually

Run a dry run first:

```zsh
rsync -av --dry-run "$HOME/projects/demo/" "$HOME/icloud/projects/demo/"
```

Run the sync script manually:

```zsh
./scripts/sync-demo-to-icloud
```

Check status:

```zsh
./scripts/status-demo-sync
```

## Install Automation

Install both LaunchAgents:

```zsh
./scripts/install-demo-launchagents
```

This installs:

```text
dev.icloud-sync.demo
dev.icloud-sync.demo-health
```

The sync agent runs every 10 minutes. The health agent also runs every 10 minutes and alerts if the sync heartbeat is older than two hours.

Uninstall both LaunchAgents:

```zsh
./scripts/uninstall-demo-launchagents
```

## Logs and State

The sync log is:

```text
$HOME/.local/share/icloud-sync/logs/demo-sync.log
```

The health-check log is:

```text
$HOME/.local/share/icloud-sync/logs/demo-sync-health.log
```

Each sync run is written as a separated block, with the newest run at the top of the file. Logs rotate at 1 MB and keep three rotated files.

The sync script updates this heartbeat file on every invocation:

```text
$HOME/.local/share/icloud-sync/state/demo-sync.last-run
```

## Battery and Alerts

- If running on battery and battery is below 30%, the sync is skipped.
- If a successful sync takes more than 60 seconds, the script sends an alert.
- Override thresholds per run with `ICLOUD_SYNC_MIN_BATTERY_PERCENT` and `ICLOUD_SYNC_MAX_RUN_SECONDS`.
- Set `ICLOUD_SYNC_ALERT_MODE=dialog` for a persistent popup that requires pressing OK; the default is a normal macOS notification banner.
- The health checker sends at most one stale-sync alert per hour while the sync remains stale.

## Safety Notes

- This demo does not use `--delete`, so files that exist only in `$HOME/icloud/projects/demo/` remain untouched.
- This demo copies files to iCloud Drive. Do not put secrets in the demo folder unless you intend to sync them to iCloud.
- This is not a full backup system yet. It is a minimal demo of one-way local-to-iCloud sync with monitoring.
