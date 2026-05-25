# Logs and status

icloud-sync does not use macOS notification banners or modal dialogs. Every
automated decision is written to local status commands and bounded log files.

## Process

1. `scripts/sync-to-icloud` loads config from
   `$HOME/.config/icloud-sync/icloud-sync.conf`.
2. It reads explicit local source folders from
   `$HOME/.config/icloud-sync/sync-pairs.conf`.
3. It checks battery and free-space guardrails.
4. It takes a lock at `/tmp/icloud-sync.lock` so overlapping syncs do not run.
5. It mirrors each selected source into the matching path under
   `$HOME/icloud`.
6. It writes a successful-sync stamp to
   `$HOME/.local/share/icloud-sync/state/sync.last-run`.

## Status surfaces

- Terminal status: `scripts/status-sync`
- GUI status: `scripts/icloud-sync-gui`
- Sync log: `$HOME/.local/share/icloud-sync/logs/sync.log`
- Health log: `$HOME/.local/share/icloud-sync/logs/sync-health.log`
- Successful-sync stamp:
  `$HOME/.local/share/icloud-sync/state/sync.last-run`

The newest sync run appears at the top of `sync.log`. Health checks append one
line per check, using `status=ok`, `status=error`, or `skipped` wording. The
GUI displays health entries newest-first.

## Dashboard

The installer opens `scripts/icloud-sync-gui` after the first successful
LaunchAgent install. You can run it again at any time.

The dashboard contains:

- Critical notifications: missing sources, rejected sources, low storage,
  missing or stale successful sync, and unloaded LaunchAgents.
- Configured mappings: local source to iCloud destination.
- Status: configured times with readable durations, plus paths and agent info.
- Sync log: newest runs first.
- Health log: newest entries first.

## Source-folder selection

No source is active until the user chooses it. The setup helper offers this
default mapping:

```text
~/projects/ -> ~/icloud/projects/
```

You can add more local development folders with:

```zsh
./scripts/configure-sync-sources
```

Sources outside `$HOME` are rejected.

## Per-source filters

Each configured source folder gets a `.icloud-sync-filter` file if it does not
already exist. The source chooser creates it after selection, and
`scripts/sync-to-icloud` creates it lazily for sources added by hand.

The file uses rsync include/exclude filter syntax. It starts with comments only,
so default behavior is to sync the whole source folder.

Warning: if a configured source is a Git repo, icloud-sync mirrors the whole
repo directory by default, including `.git/`, ignored files, build outputs, and
local untracked files. Exclude those paths in `.icloud-sync-filter` before
syncing if they should not be mirrored.
