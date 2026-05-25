icloud-sync is a safety-first macOS tool for one-way local-to-iCloud folder sync.

It mirrors configured local folders into iCloud Drive with `rsync`, does not delete destination-only files by default, and can run on a recurring LaunchAgent schedule.

## Requirements

- macOS with iCloud Drive enabled.
- A local iCloud path at `$HOME/icloud`.
- `rsync`, `zsh`, `launchctl`, `pmset`, and `open`.

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

On first install, the installer opens the local status dashboard after the LaunchAgents are installed.

The installer creates these files if they do not already exist:

```text
$HOME/.config/icloud-sync/icloud-sync.conf
$HOME/.config/icloud-sync/sync-pairs.conf
```

If no source folders are configured yet, the installer requires you to choose at least one explicitly before automation is installed. It offers this default mapping:

```text
~/projects/ -> ~/icloud/projects/
```

You can accept that default and add more local development folders during setup.

It also installs and starts these LaunchAgents:

```text
dev.icloud-sync
dev.icloud-sync.health
```

The installer does not overwrite existing config. It cancels installation if local or iCloud target storage is below the configured free-space thresholds.

## Source Folders

No source folder is active until you choose it. If no source folders are configured yet, the installer runs the source-folder chooser before installing automation.

Run the source-folder chooser manually:

```zsh
./scripts/configure-sync-sources
```

The chooser offers this default mapping:

```text
~/projects/ -> ~/icloud/projects/
```

You can accept that default and add more local development folders.

You can also edit the sync-pairs file directly:

```zsh
$EDITOR "$HOME/.config/icloud-sync/sync-pairs.conf"
```

Add one local source folder per line:

```text
~/projects/
~/dev/
```

Destinations are derived automatically under iCloud:

```text
~/projects/ -> ~/icloud/projects/
~/dev/      -> ~/icloud/dev/
```

The installed example file contains no active source. No folder is synced until you choose or add a source.

Each configured source folder gets a filter file named `.icloud-sync-filter` if it does not already exist. The source chooser creates it immediately, and `./scripts/sync-to-icloud` also creates it lazily for sources added by hand.

The filter file uses rsync include/exclude syntax. By default it contains only comments, so the whole source directory is mirrored.

```text
# Examples:
- .git/
- node_modules/
- *.tmp
+ important-output/
- scratch/
```

Warning: if a configured source is a Git repo, icloud-sync syncs the whole repo directory by default, including `.git/`, working-tree files, ignored files, build outputs, and local untracked files. Add exclusions to that source folder's `.icloud-sync-filter` before syncing if you do not want the full repo mirrored.

## Settings

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
SYNC_FILTER_FILE_NAME=".icloud-sync-filter"
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

Open the simple status GUI:

```zsh
./scripts/icloud-sync-gui
```

The GUI opens a local HTML dashboard and refreshes every 30 seconds. It includes:

- Critical notifications at the top.
- Configured mappings.
- Status split into configured times and paths/other info.
- Sync log with newest runs first.
- Health log with newest entries first.

Critical notifications include missing sources, rejected source paths, configured Git repo sources, low storage, missing or stale successful sync, and unloaded LaunchAgents. Use `./scripts/configure-sync-sources` to change source folders and `./scripts/sync-to-icloud` to run a sync manually.

If no sources are configured, sync and health checks skip cleanly and status reports:

```text
none configured
```

## Automation

The sync LaunchAgent runs every 10 minutes by default.

The health LaunchAgent also runs every 10 minutes and logs whether the last successful sync is fresh, missing, or stale. It does not show macOS notifications.

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

Each sync run is written as a separated block, with the newest run at the top of `sync.log`. Health checks append to `sync-health.log`; the dashboard displays health entries newest-first. Logs rotate at 1 MB and keep three rotated files.

See `docs/logs-and-status.md` for the process and status surfaces.

## Safety

- Destination-only files are kept by default because `SYNC_DELETE_DESTINATION=false`.
- Sources outside `$HOME` are rejected.
- Repo folders are synced completely by default, including `.git/`, unless that source's `.icloud-sync-filter` excludes paths.
- If running on battery and battery is below 30%, the sync is skipped.
- If local or iCloud target storage has less than 2048 MB free, install or sync is skipped.
- If a successful sync takes more than 60 seconds, the run records a `cost_warning` in the sync log.
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
