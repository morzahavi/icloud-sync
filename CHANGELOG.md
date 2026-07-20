# Changelog

All notable changes to icloud-sync will be documented in this file.

This project uses semantic versioning where practical.

## [Unreleased]

### Added

- GNU GPLv3-or-later license.
- Public release changelog.
- Roadmap for future-version ideas.
- Reinstall prompt for keeping, resetting, or demo-initializing an existing `sync-pairs.conf`.

### Changed

- Shortened README for easier setup and usage scanning.
- Full uninstall now preserves `$HOME/.config/icloud-sync/` by default so source pairs survive reinstall; set `ICLOUD_SYNC_PURGE_CONFIG=1` to remove config too.
- LaunchAgent-only uninstall now keeps the installed runtime so automation can be reinstalled after the cloned repo is deleted.
- Post-install docs and status messages now point users to the installed runtime commands under `$HOME/Library/Application Support/iCloud Sync/app/scripts/`.

## [0.1.0] - 2026-05-30

### Added

- Safety-first local-to-iCloud one-way sync for macOS.
- Root `./install` entrypoint.
- Interactive installer with explicit consent before creating config or starting automation.
- Demo-only first install using `~/projects/icloud-sync-demo/`.
- Config files under `$HOME/.config/icloud-sync/`.
- LaunchAgent automation for sync and health checks.
- Named wrapper executables so macOS Login Items show readable background item names.
- Local HTML status dashboard.
- Source-folder configuration helper.
- Per-source `.icloud-sync-filter` support.
- Storage, battery, path, and stale-sync safety checks.
- Manual start, abort, status, and uninstall scripts.
- Documentation for installation, source selection, logs, status, automation, and safety behavior.

### Changed

- Public install flow now requires an existing iCloud Drive symlink instead of creating one silently.
- Sync behavior defaults to keeping destination-only files.

### Security

- Sources outside `$HOME` are rejected.
- Existing LaunchAgents from another checkout are not replaced unless explicitly requested.
