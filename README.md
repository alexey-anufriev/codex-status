# Codex Status for KDE Plasma 6

[![CI][ci-badge]][ci-workflow]
[![KDE Store][kde-store-badge]][kde-store]

[ci-badge]: https://github.com/alexey-anufriev/codex-status/actions/workflows/ci.yml/badge.svg
[ci-workflow]: https://github.com/alexey-anufriev/codex-status/actions/workflows/ci.yml
[kde-store-badge]: https://img.shields.io/badge/KDE%20Store-Install-1d99f3?logo=kde&logoColor=white
[kde-store]: https://store.kde.org/p/2365503/

A compact KDE Plasma panel widget that shows the remaining Codex limits, together with the local reset time.

![image](./docs/widget.png)

## Features

- Adaptive panel width
- Automatic refresh every 30 seconds by default
- Manual refresh by clicking the widget
- Available reset credits and their expiration times in a separated hover-tooltip section
- Orange expiration warning at two days or less and red warning below one day
- Last update time in the hover tooltip
- Daily pace colors anchored to the weekly reset time
- No long-running background service
- No direct access to `~/.codex/auth.json`
- No external wrapper script
- Codex CLI discovery

## How it works

Codex Status stores the Codex executable path and refresh interval in the
standard per-widget Plasma configuration.

On every refresh, the bundled helper:

1. Reads and validates the configured Codex CLI path.
2. Adds the executable's directory to `PATH`.
3. Starts a short-lived `codex app-server` process over stdio.
4. Performs the JSON-RPC initialization handshake.
5. Calls `account/rateLimits/read`.
6. Passes the response to the bundled jq normalizer and prints a small JSON result for the widget.
7. Terminates only the app-server process started by that helper invocation.

The widget does not parse or copy Codex authentication tokens. Authentication remains inside the Codex process.

## Requirements

- KDE Plasma 6
- A recent Codex CLI version that supports `app-server` and `account/rateLimits/read`
- Codex CLI authenticated through ChatGPT
- Bash
- `jq`
- `getent` for login-shell discovery (normally provided by the base system)
- `kpackagetool6`
- `zip` for building a `.plasmoid` package

On Debian, Ubuntu, and Kubuntu:

```bash
sudo apt install jq zip
```

## Install from source

Clone or unpack the project in any directory, then run:

```bash
git clone https://github.com/alexey-anufriev/codex-status.git
cd codex-status
make install
```

The helper is bundled inside the plasmoid, so the installed widget does not depend on the source directory.

### Update a source installation

Pull the latest source and run the same install target again:

```bash
cd codex-status
git pull --ff-only
make install
systemctl --user restart plasma-plasmashell.service
```

`make install` detects the existing widget and upgrades it in place. You do not
need to remove or re-add the widget, and its existing configuration is preserved.

## Install a release

Download the `.plasmoid` file from the
[latest GitHub release](https://github.com/alexey-anufriev/codex-status/releases/latest), then install it with:

```bash
kpackagetool6 --type Plasma/Applet --install com.alexey-anufriev.codexstatus.plasmoid
```

Use `--upgrade` instead of `--install` when updating an existing installation.

## Install the packaged plasmoid

Build it first:

```bash
make package
```

Then install:

```bash
kpackagetool6 \
  --type Plasma/Applet \
  --install build/com.alexey-anufriev.codexstatus.plasmoid
```

For an existing installation, use `--upgrade` instead of `--install`.

## Finish installation

After installing by any method, add the widget:

1. Right-click the Plasma panel.
2. Enter Edit Mode.
3. Select **Add Widgets**.
4. Search for **Codex Status**.
5. Place it beside the system tray.

Then restart Plasma so it loads the current widget files:

```bash
systemctl --user restart plasma-plasmashell.service
```

Finally, open the widget settings, select **Rediscover**, and apply the settings.

When upgrading an existing installation, leave the widget in place, restart Plasma, and continue using it normally.

## Configuration

Open the widget settings to:

- View or edit the configured Codex CLI executable path
- Apply a manually entered absolute path
- Rediscover Codex through the user's interactive login shell
- Change the refresh interval between 30 and 3600 seconds

The runtime helper never searches package-manager directories. When the saved
executable is moved or removed, the widget displays an error requesting
rediscovery.

The panel width is calculated from the rendered content. It has a compact 100 px minimum and no fixed-width setting.
The widget also uses a small outer padding so it sits neatly beside tray icons.

Default:

```text
Refresh interval: 30 seconds
```

## Test the helper directly

From the repository:

```bash
./package/contents/tools/codex-status.sh "$(command -v codex)" | jq
```

Expected response shape with a weekly limit and available reset credit:

```json
{
  "ok": true,
  "weeklyWindow": {
    "remainingPercent": 54,
    "resetsAt": 1784300000
  },
  "rateLimitResetCredits": {
    "availableCount": 1,
    "credits": [
      {
        "title": "Codex rate-limit reset",
        "description": null,
        "expiresAt": 1784386400
      }
    ]
  },
  "fetchedAt": 1783978751
}
```

To use a specific executable:

```bash
./package/contents/tools/codex-status.sh /absolute/path/to/codex | jq
```

## Codex CLI discovery

Run discovery directly to print the executable found through your login shell:

```bash
./package/contents/tools/discover-codex.sh | jq
```

Or open the widget settings and select **Rediscover**. Discovery determines the
login shell from the user account, starts it with login and interactive startup
files enabled, and runs `command -v codex` in the resulting environment. This
supports NVM, fnm, asdf, mise, and similar shell-managed installations without
hard-coding any of their directory layouts into the runtime helper.

The settings page copies the discovered path into the current widget's Plasma
configuration when you apply the changes. The command-line discovery tool only
prints the result and does not modify configuration files.

## Development preview

With `plasma-sdk` installed:

```bash
plasmoidviewer -a package -l bottomedge -f horizontal
```

## Build

```bash
make package
```

Output:

```text
build/com.alexey-anufriev.codexstatus.plasmoid
```

## Uninstall

```bash
make uninstall
```

## Troubleshooting

### `Codex CLI was not found`

Check the terminal installation and run discovery again:

```bash
command -v codex
./package/contents/tools/discover-codex.sh | jq
```

If your shell configuration cannot be initialized without a terminal, enter
the result of this command directly in widget settings:

```bash
command -v codex
```

### Plasma still shows an older version

Install the current version again, then repeat the steps under [Finish installation](#finish-installation).

### Check for leftover app-server processes

After a direct helper run:

```bash
pgrep -af 'codex app-server'
```

The helper never uses `pkill` or `killall`; it only terminates the process ID it started.

## Security notes

- The helper does not read Codex credential files.
- Plasma stores only the absolute Codex executable path for each widget instance.
- No token is exposed to QML or stored by the widget.
- Only limit percentages and timestamps, reset-credit display details, fetch timestamp, and error text are returned.
- Each refresh starts an isolated stdio app-server process and closes it after the response or timeout.
- Existing Codex CLI sessions and separately running app-server processes are not targeted.

## License

MIT. See [LICENSE](LICENSE).
