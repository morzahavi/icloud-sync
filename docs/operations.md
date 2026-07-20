# Operations

This guide describes the current icloud-sync runtime and operational behaviour.
For first installation and the daily command list, start with the
[README](../README.md).

## Installed Runtime

Installation copies repository scripts, config templates, and LaunchAgent
templates into:

```text
$HOME/Library/Application Support/iCloud Sync/app/scripts/
$HOME/Library/Application Support/iCloud Sync/app/config/
$HOME/Library/Application Support/iCloud Sync/app/launchd/
```

It also creates named `/bin/zsh` wrappers for the LaunchAgents under:

```text
$HOME/Library/Application Support/iCloud Sync/bin/
```

The full uninstaller is copied separately to:

```text
$HOME/Library/Application Support/iCloud Sync/uninstall
```

These installed files let normal commands and full uninstall work after the
repository clone is deleted.

## Config and Reinstall

User config lives under:

```text
$HOME/.config/icloud-sync/icloud-sync.conf
$HOME/.config/icloud-sync/sync-pairs.conf
```

The installer creates missing files and keeps an existing general config. When
`sync-pairs.conf` already contains active sources, reinstall asks whether to
keep or reset it. When the file exists but has no active source lines, reinstall
offers `demo`, `reset`, or `cancel` rather than silently restoring the demo.
The installer's immediate-sync stage uses whichever sources are active after
that choice; it is demo-only only with the default first-install config.

The interactive source chooser replaces `sync-pairs.conf` with the selected
sources. Manual edits are also supported: use one source per line, with blank
lines and `#` comments ignored.

Destinations are derived by taking the configured source path relative to
`$HOME` and appending it below `SYNC_ICLOUD_DRIVE_SYMLINK`. Each source uses a
filter named by `SYNC_FILTER_FILE_NAME`. The chooser creates missing filters,
and `sync-to-icloud` also creates one before copying a manually added source.

## Current Path Validation

Configured sources are normalized with a trailing slash and accepted only when
their path text begins with `$HOME/`. The current check does not resolve
symlinks or canonicalize `..` components first.

Until that code is hardened, use direct source roots physically located below
`$HOME`. Do not use a symlink as a source root or include `..` in a configured
source path. This limitation means the current check must not be treated as a
complete containment or security boundary.

## Automation

The installer creates and starts two user LaunchAgents:

```text
dev.icloud-sync
dev.icloud-sync.health
```

Both use `SYNC_INTERVAL_SECONDS` when their plist files are generated. The
default is 600 seconds. Editing the interval in config does not rewrite an
already installed plist; rerun the installed `install-launchagents` command to
regenerate and restart automation. That command runs the full staged installer,
including its consent prompts and immediate-sync stage.

`abort-automation` unloads both agents but leaves their plist files in place.
`start-automation` loads those existing plist files, enables the agents, and
kickstarts them. `uninstall-launchagents` unloads the agents and removes their
plist files and named wrappers while retaining the installed runtime.

## Sync Behaviour

For every configured source, `sync-to-icloud`:

1. verifies the configured path-text prefix;
2. derives and creates the destination directory;
3. ensures the source filter exists;
4. runs `rsync -a -v` with the source filter.

It does not pass rsync's `--delete` option for source copies. Destination-only
files are therefore retained.

A run skips cleanly when no sources are configured, another run owns the lock,
the iCloud path is unavailable, or battery or storage checks fail. A successful
run updates `sync.last-run`. A successful run longer than
`SYNC_MAX_RUN_SECONDS` records a `cost_warning` but still succeeds.

## Status, Dashboard, and Logs

`status-sync` reports config paths, source mappings, destination-only retention,
free-space values, the last successful sync, and LaunchAgent state.

`icloud-sync-gui` generates this local HTML file:

```text
$HOME/.local/share/icloud-sync/state/gui/status.html
```

The page reloads every 30 seconds. Its data is regenerated when the GUI command
runs and after sync or health scripts refresh it; the browser reload alone does
not recompute status.

Runtime files are stored at:

```text
$HOME/.local/share/icloud-sync/logs/sync.log
$HOME/.local/share/icloud-sync/logs/sync-health.log
$HOME/.local/share/icloud-sync/state/sync.last-run
```

`sync.log` prepends each run block, so its newest run is first.
`sync-health.log` appends entries; the dashboard reverses the displayed health
entries so the newest appears first. By default both logs rotate after exceeding
1 MB and retain up to three rotated files.

## Default Safety Settings

| Setting | Default | Effect |
| --- | ---: | --- |
| `SYNC_INTERVAL_SECONDS` | `600` | Generated LaunchAgent interval |
| `SYNC_STALE_AFTER_SECONDS` | `7200` | Health warning threshold |
| `SYNC_MIN_BATTERY_PERCENT` | `30` | Skip below this level on battery power |
| `SYNC_MAX_RUN_SECONDS` | `60` | Successful-run cost warning threshold |
| `SYNC_MIN_FREE_LOCAL_MB` | `2048` | Minimum local free space |
| `SYNC_MIN_FREE_ICLOUD_MB` | `2048` | Minimum iCloud-target free space |
| `SYNC_MAX_LOG_BYTES` | `1048576` | Log rotation threshold |
| `SYNC_MAX_ROTATED_LOGS` | `3` | Number of rotated files retained |

`ICLOUD_SYNC_MIN_BATTERY_PERCENT` and `ICLOUD_SYNC_MAX_RUN_SECONDS` can override
their corresponding values for one sync process.

## Full Uninstall

Run `./uninstall` from a clone, or use the installed uninstaller when the clone
no longer exists:

```zsh
"$HOME/Library/Application Support/iCloud Sync/uninstall"
```

Full uninstall removes:

- both LaunchAgent plist files and named wrappers;
- the installed runtime and installed uninstaller;
- logs and state under `$HOME/.local/share/icloud-sync`;
- `$HOME/projects/icloud-sync-demo`;
- `$HOME/icloud/projects/icloud-sync-demo`.

It preserves `$HOME/.config/icloud-sync/` by default and does not remove real
source folders or iCloud mirrors added manually. To remove config too:

```zsh
ICLOUD_SYNC_PURGE_CONFIG=1 "$HOME/Library/Application Support/iCloud Sync/uninstall"
```
