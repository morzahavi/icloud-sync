icloud-sync is a safety-first macOS tool for one-way local-to-iCloud folder
sync.

It mirrors configured local folders into iCloud Drive with `rsync`, keeps
destination-only files, and can run on a recurring LaunchAgent schedule.

## Why

Keep active work in local folders such as `~/projects`, where Git, editors,
virtual environments, and build tools behave normally. Use iCloud Drive as a
readable mirror and recovery layer.

icloud-sync is not a replacement for Git, Time Machine, or a full backup
system. It is meant to make important local project snapshots visible from
iCloud without moving live development work into iCloud.

## Requirements

- macOS with iCloud Drive enabled.
- `$HOME/icloud` symlinked to iCloud Drive, unless you change the config.
- `rsync`, `zsh`, `launchctl`, `pmset`, and `open`.

Create the default iCloud symlink:

```zsh
ln -s "$HOME/Library/Mobile Documents/com~apple~CloudDocs" "$HOME/icloud"
```

## Install

```zsh
git clone https://github.com/morzahavi/icloud-sync.git
cd icloud-sync
./install
```

Before installing, the installer explains what it will do and asks you to type
`agree`. It does not create the iCloud symlink for you.

On first install, only this demo source is configured:

```text
~/projects/icloud-sync-demo/ -> ~/icloud/projects/icloud-sync-demo/
```

The default does not sync all of `~/projects`. Add real folders only after you
choose them and review their `.icloud-sync-filter` files.

## Normal Commands

After install, use the installed runtime commands:

```zsh
RUNTIME_SCRIPTS_DIR="$HOME/Library/Application Support/iCloud Sync/app/scripts"
"$RUNTIME_SCRIPTS_DIR/status-sync"
"$RUNTIME_SCRIPTS_DIR/icloud-sync-gui"
"$RUNTIME_SCRIPTS_DIR/sync-to-icloud"
"$RUNTIME_SCRIPTS_DIR/configure-sync-sources"
```

These commands keep working after the cloned repo folder is deleted.

## Source Folders

Use the source-folder chooser:

```zsh
RUNTIME_SCRIPTS_DIR="$HOME/Library/Application Support/iCloud Sync/app/scripts"
"$RUNTIME_SCRIPTS_DIR/configure-sync-sources"
```

Or edit the source list directly:

```zsh
$EDITOR "$HOME/.config/icloud-sync/sync-pairs.conf"
```

Add one local source folder per line:

```text
~/projects/icloud-sync-demo/
~/dev/
```

Destinations are derived automatically:

```text
~/projects/icloud-sync-demo/ -> ~/icloud/projects/icloud-sync-demo/
~/dev/                     -> ~/icloud/dev/
```

Each source gets a `.icloud-sync-filter` file. By default the filter contains
only comments, so the whole source directory is mirrored. Add rsync filter rules
to exclude paths:

```text
- .git/
- node_modules/
- *.tmp
+ important-output/
- scratch/
```

If a configured source is a Git repo, icloud-sync mirrors the whole repo by
default, including `.git/`, ignored files, build outputs, and untracked local
files. Exclude anything you do not want mirrored to iCloud.

## Status Dashboard

Open the local dashboard:

```zsh
RUNTIME_SCRIPTS_DIR="$HOME/Library/Application Support/iCloud Sync/app/scripts"
"$RUNTIME_SCRIPTS_DIR/icloud-sync-gui"
```

The dashboard refreshes every 30 seconds and shows:

- automation controls;
- critical notifications;
- configured mappings;
- config and runtime paths;
- sync and health logs.

Critical notifications include missing sources, rejected source paths, Git repo
sources, low storage, missing or stale successful sync, failing agents, and
unloaded LaunchAgents.

## Automation

The sync LaunchAgent runs every 10 minutes by default. The health LaunchAgent
also runs every 10 minutes and checks whether the last successful sync is fresh,
missing, or stale.

Useful automation commands:

```zsh
RUNTIME_SCRIPTS_DIR="$HOME/Library/Application Support/iCloud Sync/app/scripts"
"$RUNTIME_SCRIPTS_DIR/abort-automation"
"$RUNTIME_SCRIPTS_DIR/start-automation"
"$RUNTIME_SCRIPTS_DIR/install-launchagents"
"$RUNTIME_SCRIPTS_DIR/uninstall-launchagents"
```

Uninstalling LaunchAgents keeps config, logs, state files, source folders,
iCloud destination folders, and the installed runtime.

## Uninstall

From the repo:

```zsh
./uninstall
```

If the repo was deleted, use the installed uninstaller:

```zsh
"$HOME/Library/Application Support/iCloud Sync/uninstall"
```

Full uninstall removes LaunchAgents, the installed runtime, logs, state files,
the installed uninstaller, and the default demo source/mirror. It keeps
`$HOME/.config/icloud-sync/` so source mappings can survive reinstall.

To remove config too:

```zsh
ICLOUD_SYNC_PURGE_CONFIG=1 "$HOME/Library/Application Support/iCloud Sync/uninstall"
```

## Settings

Edit general settings:

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

## Logs and State

```text
$HOME/.local/share/icloud-sync/logs/sync.log
$HOME/.local/share/icloud-sync/logs/sync-health.log
$HOME/.local/share/icloud-sync/state/sync.last-run
```

Sync logs are written newest-first. Logs rotate at 1 MB and keep three rotated
files.

## Safety

- Destination-only files are kept.
- First install syncs only the demo source.
- Sources outside `$HOME` are rejected.
- Existing LaunchAgents pointing elsewhere are not replaced unless
  `ICLOUD_SYNC_REPLACE_EXISTING=1` is set.
- Sync is skipped on low battery by default.
- Install and sync are skipped when local or iCloud target storage is too low.
- Long successful runs record a `cost_warning`.
- Do not configure folders containing secrets unless you intend to sync them to
  iCloud.

## Troubleshooting

If background sync reports `Operation not permitted`, grant Full Disk Access to
`/usr/bin/rsync` in System Settings > Privacy & Security > Full Disk Access,
then restart automation:

```zsh
RUNTIME_SCRIPTS_DIR="$HOME/Library/Application Support/iCloud Sync/app/scripts"
"$RUNTIME_SCRIPTS_DIR/start-automation"
```

If the installed uninstaller is missing, the installed runtime was probably
created before repo-independent uninstall was added. Re-clone the repo and run:

```zsh
./uninstall
```

## Roadmap

Future-version ideas live in [ROADMAP.md](ROADMAP.md).

## Maintenance

This repository is published as-is for personal use and reference. Issues,
discussions, and support requests are not monitored.

## License

icloud-sync is free software licensed under the GNU General Public License v3.0
or later. See [LICENSE](LICENSE).
