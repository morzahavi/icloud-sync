icloud-sync is a safety-first macOS tool for one-way local-to-iCloud folder sync.

It mirrors configured local folders into iCloud Drive with `rsync`, does not delete destination-only files by default, and can run on a recurring LaunchAgent schedule.

## Requirements

- macOS with iCloud Drive enabled.
- A local iCloud path at `$HOME/icloud`.
- `rsync`, `zsh`, `launchctl`, `pmset`, and `osascript`.

## Install

Clone the repo and enter it:

```zsh
git clone https://github.com/morzahavi/icloud-sync.git
cd icloud-sync
```

Install the user config files and LaunchAgents:

```zsh
./scripts/install-launchagents
```

The installer creates these files if they do not already exist:

```text
$HOME/.config/icloud-sync/icloud-sync.conf
$HOME/.config/icloud-sync/sync-pairs.conf
```

It also installs and starts these LaunchAgents:

```text
dev.icloud-sync
dev.icloud-sync.health
```

The installer does not overwrite existing config. It cancels installation if local or iCloud target storage is below the configured free-space thresholds.

## Configure

Edit the sync-pairs file:

```zsh
$EDITOR "$HOME/.config/icloud-sync/sync-pairs.conf"
```

Add one local source folder per line:

```text
~/projects/example-project/
~/Documents/example-notes/
```

Destinations are derived automatically under iCloud:

```text
~/projects/example-project/ -> ~/icloud/projects/example-project/
~/Documents/example-notes/   -> ~/icloud/Documents/example-notes/
```

The installed example file is commented out, so no folders are synced until you add or uncomment a source.

Edit general settings in:

```zsh
$EDITOR "$HOME/.config/icloud-sync/icloud-sync.conf"
```

Common settings:

```text
SYNC_ICLOUD_ROOT="$HOME/icloud"
SYNC_DELETE_DESTINATION=false
SYNC_INTERVAL_SECONDS=600
SYNC_STALE_AFTER_SECONDS=7200
SYNC_ALERT_MODE=notification
```

`SYNC_ALERT_MODE` supports:

```text
notification
dialog
```

## Run Manually

After configuring at least one source folder, run:

```zsh
./scripts/sync-to-icloud
```

Check the current configuration, mappings, last successful sync, and LaunchAgent state:

```zsh
./scripts/status-sync
```

If no sources are configured, sync and health checks skip cleanly and status reports:

```text
none configured
```

## Automation

The sync LaunchAgent runs every 10 minutes by default.

The health LaunchAgent also runs every 10 minutes and alerts if the last successful sync is older than two hours.

Uninstall both LaunchAgents:

```zsh
./scripts/uninstall-launchagents
```

Uninstalling removes the LaunchAgent plist files. It does not remove your config, logs, state files, source folders, or iCloud destination folders.

## Logs and State

Sync log:

```text
$HOME/.local/share/icloud-sync/logs/sync.log
```

Health-check log:

```text
$HOME/.local/share/icloud-sync/logs/sync-health.log
```

Successful-sync heartbeat:

```text
$HOME/.local/share/icloud-sync/state/sync.last-run
```

Each sync run is written as a separated block, with the newest run at the top of the file. Logs rotate at 1 MB and keep three rotated files.

## Safety

- Destination-only files are kept by default because `SYNC_DELETE_DESTINATION=false`.
- Sources outside `$HOME` are rejected.
- If running on battery and battery is below 30%, the sync is skipped.
- If local or iCloud target storage has less than 2048 MB free, install or sync is skipped.
- If a successful sync takes more than 60 seconds, the script sends an alert.
- Override thresholds per run with `ICLOUD_SYNC_MIN_BATTERY_PERCENT` and `ICLOUD_SYNC_MAX_RUN_SECONDS`.
- Do not configure folders containing secrets unless you intend to sync them to iCloud.

## Optional Test Folder

To test with disposable data, create a local folder and add it to `sync-pairs.conf` yourself:

```zsh
mkdir -p "$HOME/projects/icloud-sync-test"
printf 'hello\n' > "$HOME/projects/icloud-sync-test/example.txt"
printf '%s\n' "$HOME/projects/icloud-sync-test/" >> "$HOME/.config/icloud-sync/sync-pairs.conf"
./scripts/sync-to-icloud
```

Then inspect:

```text
$HOME/icloud/projects/icloud-sync-test/
```
