#!/usr/bin/env bash

# <xbar.title>Amtrak Next Train</xbar.title>
# <xbar.version>v1.0</xbar.version>
# <xbar.author>vaisakh032</xbar.author>
# <xbar.author.github>vaisakh806</xbar.author.github>
# <xbar.desc>Shows today's remaining Amtrak trains between two stations, with live delays (relies on the unofficial, community-run Amtraker API, not an official Amtrak service).</xbar.desc>
# <xbar.dependencies>jq,curl</xbar.dependencies>
# <xbar.abouturl>https://github.com/vaisakh806/XBarPlugins</xbar.abouturl>
# <xbar.image>https://raw.githubusercontent.com/vaisakh806/XBarPlugins/main/amtrakPlugin/screenshot.png</xbar.image>
#
# <xbar.var>string(VAR_FROM="PHL"): Departure station code (Amtrak 3-letter code).</xbar.var>
# <xbar.var>string(VAR_TO="PAO"): Arrival station code (Amtrak 3-letter code).</xbar.var>
# <xbar.var>number(VAR_COUNT=3): Number of trains to list.</xbar.var>

# xbar's PATH is minimal; add Homebrew (Apple Silicon + Intel) so jq is found.
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

FROM="${VAR_FROM:-PHL}"
TO="${VAR_TO:-PAO}"
COUNT="${VAR_COUNT:-3}"
API="https://api-v3.amtraker.com/v3"
# ponytail: "today" is Eastern time; make it the departure station's tz if used elsewhere.
TODAY=$(TZ=America/New_York date +%F)

fail() { # $1 = message
  echo "🚅 -- | color=gray"
  echo "---"
  echo "Amtrak: $FROM → $TO"
  echo "$1"
  echo "Refresh | refresh=true"
  exit 0
}

if ! command -v jq >/dev/null 2>&1; then
  echo "🚅 jq missing | color=red"
  echo "---"
  echo "Install with: brew install jq"
  exit 0
fi

get() { curl -fsS -m 10 "$API/$1" 2>/dev/null; }

# Trains serving both stations (ids look like "643-29").
from_json=$(get "stations/$FROM") || fail "Amtraker API unreachable"
to_json=$(get "stations/$TO") || fail "Amtraker API unreachable"
ids=$(jq -rn --argjson f "$from_json" --argjson t "$to_json" --arg a "$FROM" --arg b "$TO" \
  '($f[$a].trains // []) - (($f[$a].trains // []) - ($t[$b].trains // [])) | .[]' 2>/dev/null)
[[ -z "$ids" ]] && fail "No trains serve both stations (check the station codes)"

# Fetch each train by number; keep today's, not-yet-departed trains that reach TO after FROM.
# Rows: "<sched dep, sortable>\t<train name>\t<12h time>\t<delay minutes>"
rows=$(
  for id in $ids; do
    get "trains/${id%-*}" | jq -r --arg id "$id" --arg a "$FROM" --arg b "$TO" --arg today "$TODAY" '
      def t: .[0:19] | strptime("%Y-%m-%dT%H:%M:%S") | mktime;
      .[][] | select(.trainID == $id) | . as $tr
      | ([.stations[].code] | index($a)) as $i | ([.stations[].code] | index($b)) as $j
      | select($i != null and $j != null and $i < $j)
      | .stations[$i] | select(.schDep[0:10] == $today and .status != "Departed")
      | [.schDep[0:19], $tr.routeName + " " + $tr.trainNum,
         (.schDep | t | strftime("%I:%M%p") | ltrimstr("0")),
         ((((.dep // .schDep) | t) - (.schDep | t)) / 60 | floor)] | @tsv' 2>/dev/null
  done | sort | head -n "$COUNT"
)
[[ -z "$rows" ]] && fail "No more trains today"

line() { # name time delay -> dropdown line
  if (( $3 > 0 )); then echo "$1: $2 (+$3 min) | color=red"; else echo "$1: $2 | color=green"; fi
}

IFS=$'\t' read -r _ name t d <<<"$(head -n 1 <<<"$rows")"
if (( d > 0 )); then echo "🚅 $t (+$d) | color=red"; else echo "🚅 $t | color=green"; fi

echo "---"
echo "Amtrak: $FROM → $TO"
while IFS=$'\t' read -r _ name time delay; do line "$name" "$time" "$delay"; done <<<"$rows"
echo "---"
echo "Refresh | refresh=true"
