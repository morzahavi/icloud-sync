# icloud-sync

icloud-sync copies selected local macOS folders into iCloud Drive with `rsync`.
It is a one-way copy from each configured source to its derived iCloud
destination.

Destination-only files are retained, so this is **not an exact mirror**. It is
also not a replacement for Git, Time Machine, or a complete backup system.

## Requirements

- macOS with iCloud Drive enabled.
- Git to clone the repository.
- The standard macOS `rsync`, `zsh`, `launchctl`, `pmset`, `plutil`, and `open`
  commands.

The default config expects an existing iCloud Drive directory at `$HOME/icloud`,
normally created as this symlink:

```zsh
ln -s "$HOME/Library/Mobile Documents/com~apple~CloudDocs" "$HOME/icloud"
```

The installer checks this path but does not create it.

## Install

```zsh
git clone https://github.com/morzahavi/icloud-sync.git
cd icloud-sync
./install
```

The installer uses three separate consent stages. It asks you to type `agree`
before it:

1. creates or keeps config and installs the runtime, preparing the demo source
   on a default first install;
2. runs an immediate sync using the configured sources, which are demo-only on
   a default first install;
3. installs and starts two LaunchAgents, then opens the status dashboard.

On a first install, the only configured source is:

```text
~/projects/icloud-sync-demo/ -> ~/icloud/projects/icloud-sync-demo/
```

It does not automatically sync all of `~/projects`. Add real sources only after
choosing them explicitly and reviewing their `.icloud-sync-filter` files.

## Daily Use

After installation, commands run from the installed runtime:

```zsh
RUNTIME_SCRIPTS_DIR="$HOME/Library/Application Support/iCloud Sync/app/scripts"
```

| Action | Command |
| --- | --- |
| Sync now | `"$RUNTIME_SCRIPTS_DIR/sync-to-icloud"` |
| Show status | `"$RUNTIME_SCRIPTS_DIR/status-sync"` |
| Configure sources | `"$RUNTIME_SCRIPTS_DIR/configure-sync-sources"` |
| Pause automation | `"$RUNTIME_SCRIPTS_DIR/abort-automation"` |
| Resume automation | `"$RUNTIME_SCRIPTS_DIR/start-automation"` |
| Open dashboard | `"$RUNTIME_SCRIPTS_DIR/icloud-sync-gui"` |
| Remove automation | `"$RUNTIME_SCRIPTS_DIR/uninstall-launchagents"` |
| Full uninstall from the clone | `./uninstall` |

Pause unloads both LaunchAgents but keeps their plist files, config, logs, and
state. Resume loads the existing plist files and immediately kickstarts both
agents. Installed runtime commands keep working if the cloned repository is
later deleted.

## Source Folders

The interactive source chooser rewrites:

```text
$HOME/.config/icloud-sync/sync-pairs.conf
```

You can also edit that file directly. Add one local source per line. With the
default iCloud path, `~/dev/` maps to `~/icloud/dev/`.

Each source gets a `.icloud-sync-filter` file containing rsync filter rules. A
new filter contains comments only, so every included item is copied. A Git
repository source therefore includes `.git/`, ignored files, untracked files,
and build outputs unless its filter excludes them.

Current source validation checks only that the configured path text begins
under `$HOME/`. It does not canonicalize `..` components or resolve symlinks
before that check. Treat this as input validation, not a hardened security
boundary. Until path validation is hardened, use direct source paths under
`$HOME`; do not configure source roots that contain `..` or are symlinks.

## Essential Safety Behaviour

- Destination-only files are retained; source deletion does not create an exact
  destination mirror.
- First install configures only the demo source.
- On battery power, sync is skipped below 30% by default.
- Sync is skipped when local or iCloud target free space is below 2048 MB by
  default. The installer checks free space before the demo sync and automation,
  although it may already have created config and the installed runtime.
- Existing icloud-sync LaunchAgents pointing elsewhere are not replaced unless
  `ICLOUD_SYNC_REPLACE_EXISTING=1` is explicitly set.
- Source filters default to copying everything. Do not configure folders that
  contain secrets unless you intend to copy them to iCloud.

## Uninstall Boundaries

Removing automation with `uninstall-launchagents` removes the two LaunchAgent
plist files and their named wrappers, while retaining the installed runtime,
config, logs, state, source folders, and iCloud destinations.

Full uninstall removes the LaunchAgents, installed runtime, logs, state, and the
default demo source and demo mirror. It keeps
`$HOME/.config/icloud-sync/` by default. Manually added real source folders and
their iCloud mirrors are preserved.

If the clone is gone, use the installed full uninstaller:

```zsh
"$HOME/Library/Application Support/iCloud Sync/uninstall"
```

## More Detail

- [Operations](docs/operations.md): config, automation, logs, safety defaults,
  reinstall, and exact uninstall behaviour.
- [Troubleshooting](docs/troubleshooting.md): permissions, paths, agents,
  dashboard refresh, and skipped or failed runs.
- [Roadmap](ROADMAP.md): nonbinding candidates for future feature branches.

## Maintenance and License

This repository is published as-is for personal use and reference. Issues,
discussions, and support requests are not monitored.

icloud-sync is free software licensed under the GNU General Public License v3.0
or later. See [LICENSE](LICENSE).
