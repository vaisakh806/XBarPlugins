# Amtrak Next Train

An xbar plugin that shows today's remaining [Amtrak](https://www.amtrak.com) trains between two stations in your menu bar.

- Menu bar: `🚅 11:00AM` — green when on time, red with `(+6)` when delayed.
- Dropdown: the next few trains today with scheduled departure and delay.
- Refreshes every 5 minutes (from the `5m` in the filename).

Amtrak has no official public API, so this uses the community-run [Amtraker](https://api-v3.amtraker.com) API. It may change or go away without notice.

## Install

1. Install [xbar](https://github.com/matryer/xbar) and `jq`:
   ```sh
   brew install jq
   ```
2. Copy the script into your xbar plugins folder and make it executable:
   ```sh
   cp amtrak_status.5m.sh ~/Library/Application\ Support/xbar/plugins/
   chmod +x ~/Library/Application\ Support/xbar/plugins/amtrak_status.5m.sh
   ```
3. Refresh xbar.

## Configure

Use the plugin's settings in xbar (or edit the variables at the top of the script):

| Variable | Default | Meaning |
|----------|---------|---------|
| `VAR_FROM` | `PHL` | Departure station code (Philadelphia 30th Street) |
| `VAR_TO` | `PAO` | Arrival station code (Paoli) |
| `VAR_COUNT` | `3` | Trains to list |

Stations are Amtrak's 3-letter codes. Look one up in the [station list](https://api-v3.amtraker.com/v3/stations) (search for the city; the `code` field is what you want).

## How it works

Finds trains serving both stations, fetches each one's live schedule, and keeps those that run today, haven't left the departure station yet, and reach the arrival station after it. Delay is actual minus scheduled departure.

## Troubleshooting

- **`jq missing`** — run `brew install jq`.
- **`🚅 --`** — no more trains today, no train serves both stations (check the codes), or the Amtraker API is unreachable.
