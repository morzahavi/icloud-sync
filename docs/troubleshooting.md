# Troubleshooting

Start with the installed status command:

```zsh
RUNTIME_SCRIPTS_DIR="$HOME/Library/Application Support/iCloud Sync/app/scripts"
"$RUNTIME_SCRIPTS_DIR/status-sync"
```

It reports the active config, mappings, free space, last successful sync, and
both LaunchAgents. The local dashboard shows the same core state plus recent
logs and critical notifications.

## iCloud Drive Path Is Missing

The default config expects `$HOME/icloud` to resolve to an existing directory.
Create the documented default symlink if that path does not already exist:

```zsh
ln -s "$HOME/Library/Mobile Documents/com~apple~CloudDocs" "$HOME/icloud"
```

If you use another path, set `SYNC_ICLOUD_DRIVE_SYMLINK` in
`$HOME/.config/icloud-sync/icloud-sync.conf`.

## Operation Not Permitted

The installer assumes the macOS `/usr/bin/rsync` binary for scheduled sync and
directs Full Disk Access there when macOS blocks iCloud Drive access:

1. Open **System Settings > Privacy & Security > Full Disk Access**.
2. Click `+`.
3. Press `Cmd-Shift-G`, enter `/usr/bin/rsync`, and choose **Open**.
4. Enable the `rsync` entry.

Then restart automation:

```zsh
RUNTIME_SCRIPTS_DIR="$HOME/Library/Application Support/iCloud Sync/app/scripts"
"$RUNTIME_SCRIPTS_DIR/start-automation"
```

## Dashboard Looks Stale

The dashboard HTML reloads every 30 seconds, but that reload does not recompute
status. Sync and health runs regenerate the file, as does reopening it with:

```zsh
RUNTIME_SCRIPTS_DIR="$HOME/Library/Application Support/iCloud Sync/app/scripts"
"$RUNTIME_SCRIPTS_DIR/icloud-sync-gui"
```

The dashboard shows `sync.log` with newest runs first. The health script appends
to `sync-health.log`, and the dashboard reverses those displayed entries so the
newest health result appears first.

## No Sources Are Configured

Sync and health checks skip when `sync-pairs.conf` has no active source lines.
Use the interactive chooser:

```zsh
RUNTIME_SCRIPTS_DIR="$HOME/Library/Application Support/iCloud Sync/app/scripts"
"$RUNTIME_SCRIPTS_DIR/configure-sync-sources"
```

The chooser needs an interactive terminal and replaces the source list with the
folders selected in that session. You can instead edit
`$HOME/.config/icloud-sync/sync-pairs.conf` directly.

## A Source Is Rejected or Missing

Current validation requires the configured path text to begin with `$HOME/`.
The code does not resolve symlinks or canonicalize `..` before this check. Use a
direct path physically below `$HOME`; do not use a symlink source root or `..`
components until path validation is hardened.

A source that is configured but absent cannot receive a generated filter and
will make that source copy fail. Restore the source or remove its line from
`sync-pairs.conf`.

## Automation Is Not Loaded

`status-sync` and the dashboard distinguish unloaded agents, missing plist
files, installed-runtime path mismatches, and nonzero last exit codes.

If both plist files exist, resume automation with:

```zsh
RUNTIME_SCRIPTS_DIR="$HOME/Library/Application Support/iCloud Sync/app/scripts"
"$RUNTIME_SCRIPTS_DIR/start-automation"
```

If the plist files were removed, rerun the installed `install-launchagents`
command. It uses the full three-stage installer and will ask for consent before
running an immediate sync with the configured sources and starting automation.

## Existing Automation Points Elsewhere

The installer refuses to replace an existing icloud-sync LaunchAgent whose
program does not match the installed runtime or supported legacy path. This
prevents one checkout from silently taking over another installation.

Prefer uninstalling the old automation first. If replacing it is intentional,
the current installer supports this explicit override:

```zsh
ICLOUD_SYNC_REPLACE_EXISTING=1 ./install
```

## Sync Was Skipped

Inspect the newest block in:

```text
$HOME/.local/share/icloud-sync/logs/sync.log
```

The current sync can skip because:

- battery power is below the configured threshold;
- local or iCloud-target storage is below its configured minimum;
- the iCloud path is unavailable;
- no sources are configured;
- another sync owns `SYNC_LOCK_DIR` (default `/tmp/icloud-sync.lock`).

A skip is recorded in the log and exits without copying source data. A
successful run longer than its configured duration threshold records a
`cost_warning`; that warning is not a failure.

## Last Successful Sync Is Missing or Stale

When sources are configured, the health check reads
`$HOME/.local/share/icloud-sync/state/sync.last-run`. It reports an error if the
file is missing or older than `SYNC_STALE_AFTER_SECONDS`. Run a manual sync and
inspect `sync.log` if the timestamp does not advance.

## Installed Uninstaller Is Missing

The installed uninstaller may be absent after an incomplete installation, a
manual deletion, or an installation from before the repo-independent
uninstaller was added. Re-clone the repository and run:

```zsh
./uninstall
```

Full uninstall preserves real source folders and manually added iCloud mirrors.
It also preserves `$HOME/.config/icloud-sync/` unless
`ICLOUD_SYNC_PURGE_CONFIG=1` is set.
