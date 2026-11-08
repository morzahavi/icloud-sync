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

## Previewing Changes

Use the updated installed runtime to preview a sync:

```zsh
"$HOME/Library/Application Support/iCloud Sync/app/scripts/sync-to-icloud" --dry-run
```

For development, `./scripts/sync-to-icloud --dry-run` runs the clone's version
with the same configured sources. Installed commands use a separate runtime
copy: update that copy through the installer before relying on preview support.
Older versions ignore arguments, including `--dry-run`, and perform a real sync.

Preview uses the normal source mappings, archive options, and existing filter
rules, adding rsync's `--dry-run`, `--itemize-changes`, and `--stats` options.
Its clearly labelled output goes to the terminal. Destination-only files remain
untouched and are not proposed for deletion. Statistics describe the local copy
operation, not confirmation of upload to Apple's servers.

Preview does not create or update source or destination files/directories,
filters, logs, last-success state, or the dashboard. If a source has no filter,
it reports that fact and previews all existing contents, matching the default
include-all rules. A normal sync would additionally create and copy the default
filter file itself; preview reports this but does not materialize that file.
A filter path that exists but is not a regular file is an error.

The configured iCloud root must exist. Battery and free-space thresholds for
real copying do not block preview. The normal shared lock is held temporarily
and removed on completion, failure, or a handled HUP, INT, or TERM signal. A
coincident scheduled sync may skip while preview holds the lock. SIGKILL cannot
be handled and may leave a lock, as with a real sync.

Exit status is zero only when all configured sources have been previewed
successfully. An unavailable lock returns 1. Missing/invalid sources, an
unavailable iCloud root, an empty source list, and invalid options return 2.
Rsync failures return a nonzero rsync exit code. Remaining sources are still
inspected after a source failure, and the final result labels that output as
partial. A preview is a view of current files, not a reservation of the changes;
files or filters may change before a later real sync. The source-path validation
limitations documented above also apply to preview.

`sync-to-icloud --help` prints usage without loading configuration or creating
files. Unsupported options and extra arguments fail before configuration is
loaded. No-argument execution retains normal sync behaviour, including its
logging, safety checks, filter creation, and successful-run state updates.

The isolated integration suite uses temporary source, destination, config, and
state directories and a stub dashboard. Run it from the clone with:

```zsh
PATH=/usr/bin:/bin:/usr/sbin:/sbin /bin/zsh tests/test-sync-to-icloud.zsh
/bin/zsh tests/test-sync-to-icloud.zsh
```

The first command checks the system rsync; the second checks the rsync found
through the current environment. The tests do not use the installed runtime,
real iCloud folders, or real user LaunchAgents.

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
