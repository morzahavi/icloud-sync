icloud-sync is a safety-first macOS tool for one-way local-to-iCloud folder sync.

It mirrors configured local folders into iCloud Drive with `rsync`, keeps destination-only files, and can run on a recurring LaunchAgent schedule.

## Why This Exists

icloud-sync exists because local development work and iCloud backup serve different jobs.

The intended workflow is to keep active development in normal local folders, such as `~/projects`, where Git, editors, virtual environments, build tools, and caches behave predictably. iCloud is used as a readable mirror and recovery layer, not as the live development workspace. The most immediate use case is being able to inspect outputs, notes, generated files, or reports from a phone or another device without moving the live project into iCloud.

The tool is deliberately conservative. First install syncs only a small demo folder. Real project folders must be added explicitly, each source gets its own `.icloud-sync-filter`, destination-only files are kept by default, and the dashboard makes the current state visible before a user trusts the automation.

The practical goal is machine-recovery confidence: if a laptop is lost, stolen, or replaced, important local project snapshots can be inspected from iCloud while Git remotes remain the source of repository history. This is not a replacement for Git, Time Machine, or a full backup system.

## Requirements

- macOS with iCloud Drive enabled.
- A valid iCloud Drive mirror path. By default icloud-sync expects `$HOME/icloud` to exist as a symlink to iCloud Drive.
- `rsync`, `zsh`, `launchctl`, `pmset`, and `open`.

## Install

icloud-sync does not create `$HOME/icloud` automatically. If you use the default
config, create a symlink like this:

```zsh
ln -s "$HOME/Library/Mobile Documents/com~apple~CloudDocs" "$HOME/icloud"
```

Clone the repo and enter it:

```zsh
git clone https://github.com/morzahavi/icloud-sync.git
cd icloud-sync
```

Install the user config files and LaunchAgents:

```zsh
./install
```

The root installer delegates to `./scripts/install-launchagents`.

Before it creates files or starts automation, the installer explains the exact
steps it will take and requires you to type `agree`. After installing and
starting the LaunchAgents, the installer opens the local status dashboard.

The installer creates these files if they do not already exist:

```text
$HOME/.config/icloud-sync/icloud-sync.conf
$HOME/.config/icloud-sync/sync-pairs.conf
```

Default versions of these files live in `config/icloud-sync.conf` and
`config/sync-pairs.conf` in this repo.

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

The installer copies the runnable scripts into an installed runtime, then creates named symlinks to Apple-signed `/bin/zsh` for the LaunchAgents. This keeps the downloaded repo from being runtime-critical while preserving readable macOS Login Items names:

```text
$HOME/Library/Application Support/iCloud Sync/app/scripts/
$HOME/Library/Application Support/iCloud Sync/app/config/
$HOME/Library/Application Support/iCloud Sync/app/launchd/
$HOME/Library/Application Support/iCloud Sync/bin/iCloud Sync Agent
$HOME/Library/Application Support/iCloud Sync/bin/iCloud Sync Health
$HOME/Library/Application Support/iCloud Sync/uninstall
```

The installed `uninstall` command is repo-independent, so full uninstall still
works if you delete the cloned checkout.

After installation, use the installed runtime commands for normal actions:

```zsh
RUNTIME_SCRIPTS_DIR="$HOME/Library/Application Support/iCloud Sync/app/scripts"
"$RUNTIME_SCRIPTS_DIR/status-sync"
"$RUNTIME_SCRIPTS_DIR/icloud-sync-gui"
"$RUNTIME_SCRIPTS_DIR/sync-to-icloud"
"$RUNTIME_SCRIPTS_DIR/install-launchagents"
```

These commands keep working after the cloned repo folder is deleted.

The installer does not overwrite existing config. It cancels installation if the configured iCloud Drive symlink does not exist, or if local or iCloud target storage is below the configured free-space thresholds.

If `$HOME/.config/icloud-sync/sync-pairs.conf` already exists, reinstall asks
whether to keep it or reset it. If the file exists but has no active source
lines, reinstall asks whether to initialize the default demo source, reset the
file, or cancel. This avoids silently re-adding the demo source after a user
removed it from the file.

If an existing LaunchAgent plist points somewhere unexpected, the installer refuses to replace it by default. Set `ICLOUD_SYNC_REPLACE_EXISTING=1` only when you intentionally want this install to take over automation.

## Source Folders

On first install, only the demo source is active:

```text
~/projects/icloud-sync-demo/ -> ~/icloud/projects/icloud-sync-demo/
```

The tool may assume `~/projects` is a good place to keep local development work, but it must not treat `~/projects` itself as a sync source by default.

Run the source-folder chooser manually when you want to add or replace sync sources:

```zsh
RUNTIME_SCRIPTS_DIR="$HOME/Library/Application Support/iCloud Sync/app/scripts"
"$RUNTIME_SCRIPTS_DIR/configure-sync-sources"
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

The installed default source is the demo folder only. You can add real folders later by editing:

```zsh
$EDITOR "$HOME/.config/icloud-sync/sync-pairs.conf"
```

Each configured source folder gets a filter file named `.icloud-sync-filter` if it does not already exist. The source chooser creates it immediately, and the installed `sync-to-icloud` command also creates it lazily for sources added by hand.

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
SYNC_ICLOUD_DRIVE_SYMLINK="$HOME/icloud"
SYNC_INTERVAL_SECONDS=600
SYNC_STALE_AFTER_SECONDS=7200
SYNC_FILTER_FILE_NAME=".icloud-sync-filter"
```

## Run Manually

After configuring at least one source folder, run:

```zsh
RUNTIME_SCRIPTS_DIR="$HOME/Library/Application Support/iCloud Sync/app/scripts"
"$RUNTIME_SCRIPTS_DIR/sync-to-icloud"
```

Check the current configuration, mappings, last successful sync, and LaunchAgent state:

```zsh
RUNTIME_SCRIPTS_DIR="$HOME/Library/Application Support/iCloud Sync/app/scripts"
"$RUNTIME_SCRIPTS_DIR/status-sync"
```

Open the simple status GUI:

```zsh
RUNTIME_SCRIPTS_DIR="$HOME/Library/Application Support/iCloud Sync/app/scripts"
"$RUNTIME_SCRIPTS_DIR/icloud-sync-gui"
```

The GUI opens a local HTML dashboard and refreshes every 30 seconds. It includes:

- Automation controls with commands to abort or start automation.
- Critical notifications at the top.
- Configured mappings.
- Status split into configured times and paths/other info.
- Sync log with newest runs first.
- Health log with newest entries first.

Critical notifications include missing sources, rejected source paths, configured Git repo sources, low storage, missing or stale successful sync, and unloaded LaunchAgents. Use the installed `configure-sync-sources` command to change source folders and the installed `sync-to-icloud` command to run a sync manually.

If background sync fails with `Operation not permitted` while accessing iCloud Drive, grant Full Disk Access to the actual rsync binary. In System Settings > Privacy & Security > Full Disk Access, click `+`, press `Cmd-Shift-G`, paste `/usr/bin/rsync`, choose Open, and enable the `rsync` entry. Restart icloud-sync automation afterward.

If no sources are configured, sync and health checks skip cleanly and status reports:

```text
none configured
```

## Automation

The sync LaunchAgent runs every 10 minutes by default.

The health LaunchAgent also runs every 10 minutes and logs whether the last successful sync is fresh, missing, or stale.

Abort automation without deleting config, logs, or plist files:

```zsh
RUNTIME_SCRIPTS_DIR="$HOME/Library/Application Support/iCloud Sync/app/scripts"
"$RUNTIME_SCRIPTS_DIR/abort-automation"
```

Start automation from existing LaunchAgent plist files:

```zsh
RUNTIME_SCRIPTS_DIR="$HOME/Library/Application Support/iCloud Sync/app/scripts"
"$RUNTIME_SCRIPTS_DIR/start-automation"
```

Install or reinstall automation from the installed runtime:

```zsh
RUNTIME_SCRIPTS_DIR="$HOME/Library/Application Support/iCloud Sync/app/scripts"
"$RUNTIME_SCRIPTS_DIR/install-launchagents"
```

Uninstall both LaunchAgents:

```zsh
RUNTIME_SCRIPTS_DIR="$HOME/Library/Application Support/iCloud Sync/app/scripts"
"$RUNTIME_SCRIPTS_DIR/uninstall-launchagents"
```

Uninstalling LaunchAgents removes the LaunchAgent plist files and named Login
Items symlinks. It keeps the installed runtime and full uninstaller available,
so you can reinstall automation later without the cloned repo. It does not
remove your config, logs, state files, source folders, or iCloud destination
folders.

## Full Uninstall

Run the full uninstall command:

```zsh
./uninstall
```

If you already deleted the cloned repo folder, run the installed uninstaller
instead:

```zsh
"$HOME/Library/Application Support/iCloud Sync/uninstall"
```

This removes:

- the two LaunchAgent plist files;
- the named Login Items symlinks and installed runtime;
- the installed uninstaller;
- icloud-sync logs and state under `$HOME/.local/share/icloud-sync`;
- the default demo source folder at `$HOME/projects/icloud-sync-demo`;
- the default demo iCloud mirror at `$HOME/icloud/projects/icloud-sync-demo`.

It keeps icloud-sync config under `$HOME/.config/icloud-sync`, including
`sync-pairs.conf`, so reinstall can reuse your source mappings. It does not
remove real source folders or iCloud mirror folders that you added manually.
Delete those only if you intentionally want to remove that data.

To also remove icloud-sync config during full uninstall:

```zsh
ICLOUD_SYNC_PURGE_CONFIG=1 "$HOME/Library/Application Support/iCloud Sync/uninstall"
```

## Troubleshooting

If `"$HOME/Library/Application Support/iCloud Sync/uninstall"` is missing, the
installed runtime was probably created before repo-independent uninstall was
added. Re-clone the repo and run:

```zsh
./uninstall
```

If you run `./install` again, existing config files are kept. In particular,
`$HOME/.config/icloud-sync/sync-pairs.conf` is not overwritten unless you
choose `reset` when prompted. If the file has no active source lines, choose
`demo` to initialize the default demo source or `reset` to replace the file with
the packaged default.

If background sync reports `Operation not permitted`, grant Full Disk Access to
`/usr/bin/rsync`, then restart automation:

```zsh
RUNTIME_SCRIPTS_DIR="$HOME/Library/Application Support/iCloud Sync/app/scripts"
"$RUNTIME_SCRIPTS_DIR/start-automation"
```

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

## Safety

- Destination-only files are always kept.
- First install syncs only `~/projects/icloud-sync-demo/` by default, not all of `~/projects`.
- Sources outside `$HOME` are rejected.
- Existing LaunchAgents that point somewhere unexpected are not replaced unless `ICLOUD_SYNC_REPLACE_EXISTING=1` is set.
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
RUNTIME_SCRIPTS_DIR="$HOME/Library/Application Support/iCloud Sync/app/scripts"
"$RUNTIME_SCRIPTS_DIR/sync-to-icloud"
```

Then inspect:

```text
$HOME/icloud/projects/icloud-sync-test/
```

## Maintenance

This repository is published as-is for personal use and reference. Issues,
discussions, and support requests are not monitored.

## License

icloud-sync is free software licensed under the GNU General Public License v3.0
or later. See [LICENSE](LICENSE).
