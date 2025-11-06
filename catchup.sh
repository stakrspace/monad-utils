#!/bin/bash

MPT_STORAGE="/dev/triedb"
RPC_URL="http://localhost:8080"
SLEEP_INTERVAL=1  # seconds between checks

while true; do
  # Get local latest block, suppress warning by redirecting stderr
  local_latest=$(monad-mpt --storage "$MPT_STORAGE" 2>/dev/null | grep "latest is" | awk '{print $NF}' | tr -d '.')

  # Get remote latest block hex
  remote_latest_hex=$(curl -s -X POST "$RPC_URL" \
    -H 'Content-Type: application/json' \
    --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' | jq -r '.result')

  # Proceed only if both values were retrieved
  if [[ -z "$local_latest" || -z "$remote_latest_hex" ]]; then
    echo "Error retrieving block info. Retrying..."
    sleep $SLEEP_INTERVAL
    continue
  fi

  # Strip 0x prefix and convert hex to dec
  remote_latest_hex=${remote_latest_hex#0x}
  remote_latest=$((16#$remote_latest_hex))

  diff=$((remote_latest - local_latest))

  # Clear screen for updated output (optional)
  clear
  echo "Local latest block:  $local_latest"
  echo "Remote latest block: $remote_latest"
  echo "Block difference:    $diff"

if (( diff == 0 )); then
  echo "Node is fully synced."
elif (( diff > 0 && diff <= 2 )); then
  echo "Node is slightly behind by $diff blocks (within acceptable range)."
elif (( diff > 2 )); then
  echo "Node is behind by $diff blocks."
elif (( diff < 0 && diff >= -2 )); then
  echo "Node is slightly ahead by $((-diff)) blocks (within acceptable range)."
else
  echo "Local node ahead by $((-diff)) blocks (more than 2 blocks). Check for consistency."
fi

  sleep $SLEEP_INTERVAL
done
