# Roadmap

This file tracks candidate ideas for future icloud-sync versions. Items here
are not promises; they are planning notes until they move into `CHANGELOG.md`.

## Principles

- Keep local folders as the source of truth.
- Keep iCloud Drive as a readable mirror and recovery layer.
- Prefer explicit choices over broad automatic syncing.
- Make sync state easy to inspect before trusting automation.
- Keep safety warnings visible, but let users dismiss warnings they understand.

## v0.2 Candidates

### Better Status GUI

- Improve the dashboard layout and visual hierarchy.
- Make configured sources, recent sync results, automation state, and next
  actions easier to scan.
- Add clearer source-level status instead of relying mostly on raw logs.

### Dismissed Warnings

- Add a way to discard or dismiss warnings that the user has reviewed.
- Persist dismissed warnings in local state, not in source configuration.
- Keep serious safety failures visible even if lower-priority warnings are
  dismissed.
- Consider a way to reset dismissed warnings from the GUI or CLI.

### More Readable Logs

- Make sync and health logs easier to read in the dashboard.
- Group log output by run, source, result, duration, and warning type.
- Highlight failed runs and skipped runs separately from successful runs.
- Keep the raw log available for debugging.

## Later Candidates

### Shorter Onboarding

- Reduce repeated setup text in prompts and docs.
- Keep first install focused on the demo source and the dashboard.

### Source Audit

- Add a command that checks configured sources before sync.
- Warn about Git repos, large folders, missing filters, and common generated
  directories such as `node_modules`, `.venv`, `dist`, and `build`.

### Dry Run

- Add a dry-run mode that previews rsync changes before writing to iCloud.
- Show the dry-run result in a readable summary.

## Idea Inbox

- Improve GUI design.
- Add option to discard warnings.
- Make logs more readable.
- Make the README shorter and easier to read.
