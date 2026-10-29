#!/usr/bin/env bash

# <xbar.title>SEPTA Next Train</xbar.title>
# <xbar.version>v1.0</xbar.version>
# <xbar.author>vaisakh032</xbar.author>
# <xbar.author.github>vaisakh806</xbar.author.github>
# <xbar.desc>Shows the next SEPTA Regional Rail trains between two stations, with live delays.</xbar.desc>
# <xbar.dependencies>jq,curl</xbar.dependencies>
# <xbar.abouturl>https://github.com/vaisakh806/XBarPlugins</xbar.abouturl>
# <xbar.image>https://raw.githubusercontent.com/vaisakh806/XBarPlugins/main/septaPlugin/screenshot.png</xbar.image>
#
# <xbar.var>string(VAR_FROM="Suburban Station"): Departure station (SEPTA name).</xbar.var>
# <xbar.var>string(VAR_TO="Devon"): Arrival station (SEPTA name).</xbar.var>
# <xbar.var>number(VAR_COUNT=3): Number of trains to list.</xbar.var>

# xbar's PATH is minimal; add Homebrew (Apple Silicon + Intel) so jq is found.
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

FROM="${VAR_FROM:-Suburban Station}"
TO="${VAR_TO:-Devon}"
COUNT="${VAR_COUNT:-3}"

if ! command -v jq >/dev/null 2>&1; then
  echo "🚆 jq missing | color=red"
  echo "---"
  echo "Install with: brew install jq"
  exit 0
fi

resp=$(curl -fsS -m 10 -G "https://www3.septa.org/api/NextToArrive/index.php" \
  --data-urlencode "req1=$FROM" --data-urlencode "req2=$TO" --data-urlencode "req3=$COUNT" 2>&1)

# A valid reply is a non-empty JSON array; anything else is an error.
if ! jq -e 'type == "array" and length > 0' >/dev/null 2>&1 <<<"$resp"; then
  echo "🚆 -- | color=gray"
  echo "---"
  echo "$FROM → $TO"
  echo "No trains found, or SEPTA API unreachable"
  echo "Refresh | refresh=true"
  exit 0
fi

# One line per train: "<train>\t<time>\t<delay text, empty if on time>"
# Delay is "+5 min" for numeric delays; anything else (e.g. "Canceled") is shown as-is.
rows=$(jq -r '.[] | [.orig_train, .orig_departure_time,
  (if .orig_delay == "On time" then ""
   elif (.orig_delay | test("^[0-9]")) then "+" + .orig_delay
   else .orig_delay end)] | @tsv' <<<"$resp")

IFS=$'\t' read -r _ t d <<<"$(head -n 1 <<<"$rows")"
if [[ -n "$d" ]]; then echo "🚆 $t ($d) | color=red"; else echo "🚆 $t | color=green"; fi

echo "---"
echo "$FROM → $TO"
while IFS=$'\t' read -r train time delay; do
  if [[ -n "$delay" ]]; then
    echo "Train $train: $time ($delay) | color=red"
  else
    echo "Train $train: $time | color=green"
  fi
done <<<"$rows"
echo "---"
echo "Refresh | refresh=true"
