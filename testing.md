# Testing

Use these commands to reset local install state and test icloud-sync again.

The cleanup commands remove package-created config, logs, state, demo source
data, and demo iCloud mirror data. Review the paths before running them.

## Test Current Checkout

Use this when testing local changes in the current repository checkout.

```zsh
./scripts/uninstall-launchagents

rm -rf "$HOME/.config/icloud-sync"
rm -rf "$HOME/.local/share/icloud-sync"
rm -rf "$HOME/projects/icloud-sync-demo"
rm -rf "$HOME/icloud/projects/icloud-sync-demo"

./scripts/install-launchagents
./scripts/status-sync
```

Expected result:

- config is recreated under `$HOME/.config/icloud-sync`;
- logs and state are recreated under `$HOME/.local/share/icloud-sync`;
- only the demo source is configured by default;
- both LaunchAgents are loaded through wrappers for the current checkout;
- `./scripts/status-sync` shows the demo mapping and matching checkout paths.

## Test Fresh Clone

Use this when testing what a new user gets from GitHub. Commit and push the
changes you want to test before removing the local clone.

```zsh
./scripts/uninstall-launchagents

rm -rf "$HOME/.config/icloud-sync"
rm -rf "$HOME/.local/share/icloud-sync"
rm -rf "$HOME/projects/icloud-sync-demo"
rm -rf "$HOME/icloud/projects/icloud-sync-demo"

cd "$HOME/projects"
rm -rf icloud-sync
git clone https://github.com/morzahavi/icloud-sync.git
cd icloud-sync
git switch dev

./scripts/install-launchagents
./scripts/status-sync
```

Expected result:

- the cloned `dev` branch installs without relying on prior local state;
- config and demo folders are recreated from scratch;
- both LaunchAgent wrappers point to the freshly cloned checkout;
- `./scripts/status-sync` reports `matches this checkout: yes` for both agents.

## Normal Uninstall Only

Use this when you only want to stop automation and remove the LaunchAgent plist
files and wrapper executables while keeping config, logs, state, and synced
data.

```zsh
./scripts/uninstall-launchagents
```

This removes:

```text
$HOME/Library/LaunchAgents/dev.icloud-sync.plist
$HOME/Library/LaunchAgents/dev.icloud-sync.health.plist
$HOME/Library/Application Support/iCloud Sync/bin/iCloud Sync Agent
$HOME/Library/Application Support/iCloud Sync/bin/iCloud Sync Health
```

It does not remove:

```text
$HOME/.config/icloud-sync/
$HOME/.local/share/icloud-sync/
$HOME/projects/icloud-sync-demo/
$HOME/icloud/projects/icloud-sync-demo/
```
