#!/bin/zsh

set -e
set -u
set -o pipefail

TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
test_root="$(mktemp -d "${TMPDIR:-/tmp}/icloud-sync-tests.XXXXXX")"
trap 'rm -rf -- "$test_root"' EXIT

# Copy only the runtime under test. The dashboard stub prevents tests from
# consulting the real user's LaunchAgents or opening a browser.
test_runtime="$test_root/runtime"
mkdir -p "$test_runtime/lib"
cp "$TEST_DIR/../scripts/sync-to-icloud" "$test_runtime/sync-to-icloud"
cp "$TEST_DIR/../scripts/lib/icloud-sync-config" "$test_runtime/lib/icloud-sync-config"
cat > "$test_runtime/icloud-sync-gui" <<'EOF'
#!/bin/zsh
: > "$HOME/dashboard-refreshed"
EOF
chmod +x "$test_runtime/icloud-sync-gui"

case_count=0
passed=0
output=''

new_fixture() {
  (( case_count += 1 ))
  case_root="$test_root/case-$case_count"
  fixture_home="$case_root/home"
  source_dir="$fixture_home/projects/source with spaces"
  destination_dir="$fixture_home/icloud/projects/source with spaces"
  fixture_config="$fixture_home/config/icloud-sync.conf"
  fixture_pairs="$fixture_home/config/sync-pairs.conf"
  fixture_lock="$case_root/sync.lock"
  test_path="$PATH"

  mkdir -p "$source_dir" "$fixture_home/icloud" "$fixture_home/config"
  cat > "$fixture_config" <<EOF
SYNC_ICLOUD_DRIVE_SYMLINK="\$HOME/icloud"
SYNC_SKIP_ON_LOW_BATTERY=false
SYNC_MIN_FREE_LOCAL_MB=0
SYNC_MIN_FREE_ICLOUD_MB=0
SYNC_LOCK_DIR="$fixture_lock"
EOF
  printf '%s\n' "$source_dir" > "$fixture_pairs"
  output=''
}

run_sync() {
  # HOME is overridden only for this child process, never for the test shell.
  if output="$(env HOME="$fixture_home" PATH="$test_path" \
    ICLOUD_SYNC_CONFIG_DIR="$fixture_home/config" \
    ICLOUD_SYNC_CONFIG_FILE="$fixture_config" \
    ICLOUD_SYNC_PAIRS_FILE="$fixture_pairs" \
    ICLOUD_SYNC_MIN_BATTERY_PERCENT=30 ICLOUD_SYNC_MAX_RUN_SECONDS=60 \
    /bin/zsh "$test_runtime/sync-to-icloud" "$@" 2>&1)"; then
    run_status=0
  else
    run_status=$?
  fi
}

fail() {
  print -u2 -- "FAIL: $*"
  print -u2 -- "$output"
  exit 1
}

assert_status() {
  [[ "$run_status" == "$1" ]] || fail "expected exit $1, got $run_status"
}

assert_contains() {
  [[ "$output" == *"$1"* ]] || fail "output does not contain: $1"
}

assert_absent() {
  [[ "$output" != *"$1"* ]] || fail "unexpected output: $1"
}

assert_no_lock() {
  [[ ! -e "$fixture_lock" ]] || fail 'preview left its lock behind'
}

snapshot_home() {
  local entry_path
  # Include hidden entries, contents, modes, sizes, mtimes, ctimes and symlink
  # targets. Ignore access times, which legitimate read-only inspection changes.
  for entry_path in "$fixture_home" "$fixture_home"/**/*(DN); do
    printf '%s\n' "${entry_path#$fixture_home}"
    stat -f '%p %z %m %c' "$entry_path"
    if [[ -L "$entry_path" ]]; then
      readlink "$entry_path"
    elif [[ -f "$entry_path" ]]; then
      shasum -a 256 "$entry_path"
    fi
  done
}

assert_unchanged() {
  [[ "$(snapshot_home)" == "$before_snapshot" ]] || fail 'preview changed the fixture filesystem'
}

pass() {
  (( passed += 1 ))
  print -- "ok $passed - $1"
}

new_fixture
print -- ': > "$HOME/config-was-loaded"' >> "$fixture_config"
before_snapshot="$(snapshot_home)"
run_sync --help
assert_status 0
assert_contains 'Usage: sync-to-icloud'
assert_unchanged
assert_no_lock
pass 'help does not load config or change the filesystem'

for rejected_option in --dry-rnu --dry-run=1 source-folder -n; do
  run_sync "$rejected_option"
  assert_status 2
  assert_unchanged
  assert_no_lock
done
pass 'unknown options and positional arguments fail before config is loaded'

run_sync --dry-run --help
assert_status 2
assert_unchanged
run_sync --dry-run --dry-run
assert_status 2
assert_unchanged
pass 'extra arguments cannot accidentally run a sync'

new_fixture
print -- 'new content' > "$source_dir/new.txt"
mkdir -p "$source_dir/.git" "$source_dir/nested"
print -- 'included by default' > "$source_dir/.git/example"
print -- 'also included' > "$source_dir/nested/generated.tmp"
before_snapshot="$(snapshot_home)"
run_sync --dry-run
assert_status 0
assert_contains 'run: dry-run'
assert_contains 'filter: missing'
assert_contains 'new.txt'
assert_contains '.git/example'
assert_contains 'nested/generated.tmp'
assert_contains 'Number of files'
assert_contains 'result: preview complete'
assert_unchanged
assert_no_lock
[[ ! -e "$destination_dir" ]] || fail 'preview created a nested destination'
[[ ! -e "$source_dir/.icloud-sync-filter" ]] || fail 'preview created a filter'
pass 'missing-filter preview includes all existing files without creating destination or runtime state'

new_fixture
mkdir -p "$destination_dir" "$source_dir/excluded dir" \
  "$fixture_home/.local/share/icloud-sync/logs" "$fixture_home/.local/share/icloud-sync/state/gui"
printf '%s\n' '- *.tmp' '- excluded dir/' > "$source_dir/.icloud-sync-filter"
print -- 'new' > "$source_dir/new.txt"
print -- 'updated and longer' > "$source_dir/update.txt"
print -- 'old' > "$destination_dir/update.txt"
print -- 'same' > "$source_dir/unchanged.txt"
cp -p "$source_dir/unchanged.txt" "$destination_dir/unchanged.txt"
print -- 'excluded' > "$source_dir/excluded.tmp"
print -- 'excluded' > "$source_dir/excluded dir/inside.txt"
print -- 'keep this' > "$destination_dir/destination-only.txt"
print -- 'old log' > "$fixture_home/.local/share/icloud-sync/logs/sync.log"
print -- 'old success' > "$fixture_home/.local/share/icloud-sync/state/sync.last-run"
print -- 'old dashboard' > "$fixture_home/.local/share/icloud-sync/state/gui/status.html"
before_snapshot="$(snapshot_home)"
run_sync --dry-run
assert_status 0
assert_contains 'new.txt'
assert_contains 'update.txt'
assert_contains '>f'
assert_absent 'unchanged.txt'
assert_absent 'excluded.tmp'
assert_absent 'inside.txt'
assert_absent 'destination-only.txt'
assert_absent '*deleting'
assert_unchanged
assert_no_lock
pass 'preview respects filters, shows creates and updates, and preserves existing data, logs and state'

new_fixture
print -- "$fixture_home/missing-source" > "$fixture_pairs"
before_snapshot="$(snapshot_home)"
run_sync --dry-run
assert_status 2
assert_contains 'cannot preview missing source'
assert_unchanged
assert_no_lock
pass 'missing source fails without creating a destination'

new_fixture
mkdir -p "$case_root/outside-source"
print -- "$case_root/outside-source" > "$fixture_pairs"
before_snapshot="$(snapshot_home)"
run_sync --dry-run
assert_status 2
assert_contains 'rejecting source outside HOME'
assert_unchanged
assert_no_lock
pass 'source outside the configured HOME is rejected'

new_fixture
print -- 'SYNC_ICLOUD_DRIVE_SYMLINK="$HOME/missing-icloud"' >> "$fixture_config"
before_snapshot="$(snapshot_home)"
run_sync --dry-run
assert_status 2
assert_contains 'iCloud Drive symlink does not exist'
assert_unchanged
assert_no_lock
pass 'unavailable iCloud root fails without writes'

new_fixture
print -- '# No active sources' > "$fixture_pairs"
before_snapshot="$(snapshot_home)"
run_sync --dry-run
assert_status 2
assert_contains 'no sync sources configured'
assert_unchanged
assert_no_lock
pass 'empty source list reports that no preview is available'

new_fixture
mkdir "$fixture_lock"
print -- 'other owner' > "$fixture_lock/owner"
before_snapshot="$(snapshot_home)"
run_sync --dry-run
assert_status 1
assert_contains 'sync lock unavailable'
assert_unchanged
[[ "$(cat "$fixture_lock/owner")" == 'other owner' ]] || fail 'preview modified another owner lock'
pass 'contended lock is preserved and reported as failure'

new_fixture
print -- 'not-a-valid-filter-rule' > "$source_dir/.icloud-sync-filter"
before_snapshot="$(snapshot_home)"
run_sync --dry-run
(( run_status != 0 )) || fail 'invalid rsync filter unexpectedly succeeded'
assert_contains 'result: preview failed'
assert_unchanged
assert_no_lock
pass 'real rsync filter error propagates and releases the lock'

new_fixture
mkdir "$source_dir/.icloud-sync-filter"
before_snapshot="$(snapshot_home)"
run_sync --dry-run
assert_status 2
assert_contains 'filter is not a regular file'
assert_unchanged
assert_no_lock
pass 'non-file filter cannot silently become an include-all preview'

new_fixture
printf '%s\n' "$fixture_home/missing-source" "$source_dir" > "$fixture_pairs"
print -- 'valid source after the missing one' > "$source_dir/still-previewed.txt"
before_snapshot="$(snapshot_home)"
run_sync --dry-run
assert_status 2
assert_contains 'still-previewed.txt'
assert_contains 'output may be partial'
assert_unchanged
assert_no_lock
pass 'later valid sources are inspected without hiding an earlier failure'

new_fixture
mkdir "$case_root/bin"
cat > "$case_root/bin/rsync" <<'EOF'
#!/bin/zsh
print -u2 -- 'simulated rsync I/O failure'
exit 23
EOF
chmod +x "$case_root/bin/rsync"
test_path="$case_root/bin:$PATH"
before_snapshot="$(snapshot_home)"
run_sync --dry-run
assert_status 23
assert_contains 'simulated rsync I/O failure'
assert_unchanged
assert_no_lock
pass 'rsync exit code is returned without writes or a stale lock'

new_fixture
mkdir "$case_root/bin"
cat > "$case_root/bin/rsync" <<'EOF'
#!/bin/zsh
kill -TERM "$PPID"
exit 0
EOF
chmod +x "$case_root/bin/rsync"
test_path="$case_root/bin:$PATH"
before_snapshot="$(snapshot_home)"
run_sync --dry-run
assert_status 143
assert_unchanged
assert_no_lock
pass 'terminated preview releases its lock'

new_fixture
print -- 'real sync' > "$source_dir/new.txt"
run_sync
assert_status 0
[[ "$(cat "$destination_dir/new.txt")" == 'real sync' ]] || fail 'normal sync did not copy data'
[[ -f "$source_dir/.icloud-sync-filter" ]] || fail 'normal sync did not create its filter'
cmp -s "$source_dir/.icloud-sync-filter" "$destination_dir/.icloud-sync-filter" || fail 'normal sync did not copy its filter'
[[ -s "$fixture_home/.local/share/icloud-sync/state/sync.last-run" ]] || fail 'normal sync did not record success'
[[ -f "$fixture_home/dashboard-refreshed" ]] || fail 'normal sync did not refresh the dashboard'
output="$(cat "$fixture_home/.local/share/icloud-sync/logs/sync.log")"
assert_contains 'result: success'
assert_contains 'destination_only_files: kept'
assert_no_lock
pass 'normal sync still creates destination, filter, success state, log and dashboard'

new_fixture
mkdir -p "$destination_dir" "$fixture_home/.local/share/icloud-sync/logs"
print -- '- *.tmp' > "$source_dir/.icloud-sync-filter"
print -- 'excluded' > "$source_dir/excluded.tmp"
print -- 'updated data' > "$source_dir/update.txt"
print -- 'old' > "$destination_dir/update.txt"
print -- 'retain me' > "$destination_dir/destination-only.txt"
print -- 'previous run marker' > "$fixture_home/.local/share/icloud-sync/logs/sync.log"
run_sync
assert_status 0
[[ ! -e "$destination_dir/excluded.tmp" ]] || fail 'normal sync ignored its filter'
[[ "$(cat "$destination_dir/update.txt")" == 'updated data' ]] || fail 'normal sync did not update a file'
[[ "$(cat "$destination_dir/destination-only.txt")" == 'retain me' ]] || fail 'normal sync deleted destination-only data'
output="$(cat "$fixture_home/.local/share/icloud-sync/logs/sync.log")"
assert_contains 'previous run marker'
assert_contains 'result: success'
assert_no_lock
pass 'normal sync still respects filters, updates files, retains destination-only data and keeps prior logs'

new_fixture
mkdir "$fixture_lock"
print -- 'other owner' > "$fixture_lock/owner"
run_sync
assert_status 0
[[ ! -e "$destination_dir" ]] || fail 'contended normal sync copied data'
[[ -f "$fixture_lock/owner" ]] || fail 'normal sync removed another owner lock'
output="$(cat "$fixture_home/.local/share/icloud-sync/logs/sync.log")"
assert_contains 'previous sync still running'
pass 'normal sync still logs a clean skip on lock contention'

new_fixture
print -- "$fixture_home/missing-source" > "$fixture_pairs"
run_sync
assert_status 2
[[ ! -e "$fixture_home/.local/share/icloud-sync/state/sync.last-run" ]] || fail 'failed normal sync recorded success'
output="$(cat "$fixture_home/.local/share/icloud-sync/logs/sync.log")"
assert_contains 'result: failed with exit code 2'
assert_no_lock
pass 'normal source failure still logs failure without recording success'

new_fixture
print -- '# no sources' > "$fixture_pairs"
run_sync
assert_status 0
output="$(cat "$fixture_home/.local/share/icloud-sync/logs/sync.log")"
assert_contains 'no sync sources configured'
[[ ! -e "$fixture_home/.local/share/icloud-sync/state/sync.last-run" ]] || fail 'skipped normal sync recorded success'
assert_no_lock
pass 'normal sync still logs a clean skip when no sources are configured'

print -- "Passed $passed integration checks using $(command -v rsync)."
