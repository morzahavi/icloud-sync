# Roadmap

This roadmap lists possible future work for icloud-sync. Implemented behaviour
is documented in the [README](README.md), [operations guide](docs/operations.md),
and [troubleshooting guide](docs/troubleshooting.md). Everything below is
proposed unless those current documents say otherwise.

These items are candidates, not commitments. Their order is a suggested
sequence for future feature branches, not a promise of delivery or timing.
Candidates within each priority are listed in the order they could be considered.

## Product Principles

- Keep local folders as the source of truth.
- Keep iCloud Drive as a readable copy and recovery layer.
- Prefer explicit source choices over broad automatic syncing.
- Make sync state easy to inspect before trusting automation.
- Keep conservative safety defaults and visible failure information.
- Any future warning-dismissal behaviour should apply only to reviewed
  lower-priority warnings; serious safety failures should remain visible.

## Priority 1: Operational Clarity

- Improve dashboard hierarchy so configured sources, recent results,
  automation state, and next actions are easier to scan.
- Add clearer source-level status instead of relying mainly on raw logs.
- Group sync and health information by run, source, result, duration, and
  warning type while retaining raw logs for diagnosis.
- Allow reviewed lower-priority warnings to be dismissed in local state while
  keeping serious safety failures visible.

## Priority 2: Pre-sync Confidence

- Evaluate a source audit that would identify Git repositories, large folders,
  missing filters, and common generated directories before syncing.
- Explore a dry-run preview that would summarize proposed rsync changes without
  writing to iCloud Drive.
