#!/usr/bin/env bash
# Sends a request every 100ms through the ingress for DURATION seconds and
# fails if even one of them errors. CI runs this during a rolling update.
set -euo pipefail

url="$1"
host="$2"
duration="${3:-60}"

end=$((SECONDS + duration))
total=0
failed=0
while [ "$SECONDS" -lt "$end" ]; do
  if ! curl -fsS -o /dev/null --max-time 2 -H "Host: $host" "$url"; then
    failed=$((failed + 1))
  fi
  total=$((total + 1))
  sleep 0.1
done

echo "requests sent: $total, failed: $failed"
[ "$failed" -eq 0 ]
