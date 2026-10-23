#!/usr/bin/env bash
set -uo pipefail

if [[ $# -lt 1 || ! -f "$1" ]]; then
  echo "usage: $(basename "$0") Spec.tla [extra TLC args...]" >&2
  exit 2
fi

spec=$1
shift

cd "$(dirname "$spec")" || exit 2
spec=$(basename "$spec")

SECONDS=0
out=$(java -XX:+UseParallelGC tlc2.TLC -coverage 1 -workers 1 "$@" "$spec" 2>&1)
rc=$?
elapsed=$SECONDS

if [[ $rc -ne 0 ]]; then
  printf '%s\n' "$out" | awk '/^The coverage statistics/{skip=1} !skip; /^End of statistics/{skip=0}'
  echo
  echo "TLC exited with code $rc"
  echo
fi

printf '%s\n' "$out" | awk -v t="$elapsed" '
  /states generated, .* distinct states found, .* states left on queue/ {
    found = $1; distinct = $(NF-8); queue = $(NF-4)
  }
  /^Progress\(/ { match($0, /[0-9]+/); diam = substr($0, RSTART, RLENGTH) }
  /depth of the complete state graph search is/ { diam = $NF; sub(/\.$/, "", diam) }
  /^<[A-Za-z0-9_]+ line .* of module [A-Za-z0-9_]+>: [0-9]+:[0-9]+$/ {
    action = substr($1, 2)
    mod = $0; sub(/.* of module /, "", mod); sub(/>.*/, "", mod)
    split($NF, c, ":")
    rows[++n] = sprintf("%-14s %-14s %10s %10s", mod, action, c[2], c[1])
  }
  END {
    print "States:"
    printf "%-10s %10s %10s %10s %10s\n", "Time", "Diameter", "Found", "Distinct", "Queue"
    printf "%02d:%02d:%02d %10s %10s %10s %10s\n", t/3600, (t%3600)/60, t%60, diam, found, distinct, queue
    print ""
    print "Coverage:"
    printf "%-14s %-14s %10s %10s\n", "Module", "Action", "Total", "Distinct"
    for (i = 1; i <= n; i++) print rows[i]
  }
'

exit $rc
