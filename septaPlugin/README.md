# SEPTA Next Train

An xbar plugin that shows the next [SEPTA](https://www.septa.org) Regional Rail train between two stations in your menu bar.

- Menu bar: `🚆 8:05AM` — green when on time, red with `(+5)` when delayed.
- Dropdown: the next few trains with departure time and delay.
- Refreshes every 3 minutes (from the `3m` in the filename).

## Install

1. Install [xbar](https://github.com/matryer/xbar) and `jq`:
   ```sh
   brew install jq
   ```
2. Copy the script into your xbar plugins folder and make it executable:
   ```sh
   cp septa_status.3m.sh ~/Library/Application\ Support/xbar/plugins/
   chmod +x ~/Library/Application\ Support/xbar/plugins/septa_status.3m.sh
   ```
3. Refresh xbar.

## Configure

Click the plugin in the menu bar → *Open in xbar → Settings* (or edit the variables at the top of the script):

| Variable | Default | Meaning |
|----------|---------|---------|
| `VAR_FROM` | `Suburban Station` | Departure station |
| `VAR_TO` | `Devon` | Arrival station |
| `VAR_COUNT` | `3` | Trains to list |

Station names must match SEPTA's spelling (e.g. `Market East`, `30th Street Station`, `Ambler`). Find the exact names on SEPTA's [Regional Rail station list](https://www3.septa.org/VIRegionalRail.html).

## How it works

Calls SEPTA's public [NextToArrive API](https://www3.septa.org/api/NextToArrive/index.php?req1=Suburban%20Station&req2=Devon&req3=3) and formats the JSON with `jq`. No API key needed.

## Troubleshooting

- **`jq missing`** — run `brew install jq`.
- **`🚆 --`** — no upcoming trains, a misspelled station, or SEPTA's API is down.
