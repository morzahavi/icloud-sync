icloud-sync is a safety-first macOS tool for one-way local-to-iCloud folder sync.

It mirrors configured local folders into iCloud Drive with `rsync`, does not delete destination-only files by default, and can run on a recurring LaunchAgent schedule.

## Why This Exists

icloud-sync exists because local development work and iCloud backup serve different jobs.

The intended workflow is to keep active development in normal local folders, such as `~/projects`, where Git, editors, virtual environments, build tools, and caches behave predictably. iCloud is used as a readable mirror and recovery layer, not as the live development workspace.

The tool is deliberately conservative. First install syncs only a small demo folder. Real project folders must be added explicitly, each source gets its own `.icloud-sync-filter`, destination-only files are kept by default, and the dashboard makes the current state visible before a user trusts the automation.

The practical goal is machine-recovery confidence: if a laptop is lost, stolen, or replaced, important local project snapshots can be inspected from iCloud while Git remotes remain the source of repository history. This is not a replacement for Git, Time Machine, or a full backup system.

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

If no source folders are configured yet, the installer creates and configures only this demo mapping:

```text
~/projects/icloud-sync-demo/ -> ~/icloud/projects/icloud-sync-demo/
```

The default does not sync all of `~/projects`. Add real project folders only after choosing them explicitly and reviewing their filter files.

It also installs and starts these LaunchAgents:

```text
dev.icloud-sync
dev.icloud-sync.health
```

The installer does not overwrite existing config. It cancels installation if local or iCloud target storage is below the configured free-space thresholds.

If an existing LaunchAgent plist points to a different checkout of this repo, the installer refuses to replace it by default. Set `ICLOUD_SYNC_REPLACE_EXISTING=1` only when you intentionally want this checkout to take over automation.

## Source Folders

On first install, only the demo source is active:

```text
~/projects/icloud-sync-demo/ -> ~/icloud/projects/icloud-sync-demo/
```

The tool may assume `~/projects` is a good place to keep local development work, but it must not treat `~/projects` itself as a sync source by default.

Run the source-folder chooser manually when you want to add or replace sync sources:

```zsh
./scripts/configure-sync-sources
```

The chooser offers this demo mapping:

```text
~/projects/icloud-sync-demo/ -> ~/icloud/projects/icloud-sync-demo/
```

You can accept that demo source and add more local development folders explicitly.

You can also edit the sync-pairs file directly:

```zsh
$EDITOR "$HOME/.config/icloud-sync/sync-pairs.conf"
```

Add one local source folder per line:

```text
~/projects/icloud-sync-demo/
~/dev/
```

Destinations are derived automatically under iCloud:

```text
~/projects/icloud-sync-demo/ -> ~/icloud/projects/icloud-sync-demo/
~/dev/                     -> ~/icloud/dev/
```

The installed default source is the demo folder only. No broader project folder is synced unless you add it.

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

- Automation controls with commands to abort or start automation.
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

Abort automation without deleting config, logs, or plist files:

```zsh
./scripts/abort-automation
```

Start automation from existing LaunchAgent plist files:

```zsh
./scripts/start-automation
```

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
- First install syncs only `~/projects/icloud-sync-demo/` by default, not all of `~/projects`.
- Sources outside `$HOME` are rejected.
- Existing LaunchAgents from another checkout are not replaced unless `ICLOUD_SYNC_REPLACE_EXISTING=1` is set.
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
