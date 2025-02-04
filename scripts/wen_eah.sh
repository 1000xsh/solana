#!/bin/bash

RPC_URL="https://api.mainnet-beta.solana.com"

get_epoch_info() {
  curl -s -X POST -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","id":1,"method":"getEpochInfo"}' \
    $RPC_URL
}

calculate_slot_times() {
  local epoch_start_slot=$1
  local epoch_start_time=$2
  local slots_per_epoch=432000
  local slot_duration_ms=400

  local start_offset=$((slots_per_epoch / 4))
  local stop_offset=$((slots_per_epoch * 3 / 4))

  local start_slot=$((epoch_start_slot + start_offset))
  local stop_slot=$((epoch_start_slot + stop_offset))

  local start_time=$(date -u -d "@$((epoch_start_time + (start_offset * slot_duration_ms / 1000)))" +"%Y-%m-%d %H:%M:%S")
  local stop_time=$(date -u -d "@$((epoch_start_time + (stop_offset * slot_duration_ms / 1000)))" +"%Y-%m-%d %H:%M:%S")

  echo "$start_slot $start_time $stop_slot $stop_time"
}


main() {
  epoch_info=$(get_epoch_info)
  current_epoch=$(echo $epoch_info | jq -r '.result.epoch')
  current_slot=$(echo $epoch_info | jq -r '.result.absoluteSlot')
  slot_index=$(echo $epoch_info | jq -r '.result.slotIndex')
  slots_in_epoch=$(echo $epoch_info | jq -r '.result.slotsInEpoch')

  epoch_start_slot=$((current_slot - slot_index))
  current_time=$(date -u +"%s")
  epoch_start_time=$((current_time - (slot_index * 400 / 1000)))

  read current_start_slot current_start_time current_stop_slot current_stop_time < <(calculate_slot_times $epoch_start_slot $epoch_start_time)

  next_epoch_start_slot=$((epoch_start_slot + slots_in_epoch))
  next_epoch_start_time=$((epoch_start_time + (slots_in_epoch * 400 / 1000)))

  read next_start_slot next_start_time next_stop_slot next_stop_time < <(calculate_slot_times $next_epoch_start_slot $next_epoch_start_time)

  echo "current epoch: $current_epoch"
  echo "eah start slot: $current_start_slot"
  echo "eah start time (utc): $current_start_time"
  echo "eah stop slot: $current_stop_slot"
  echo "eah stop time (utc): $current_stop_time"
  echo ""
  echo "next epoch: $((current_epoch + 1))"
  echo "eah start slot: $next_start_slot"
  echo "eah start time (utc): $next_start_time"
  echo "eah stop slot: $next_stop_slot"
  echo "eah stop time (utc): $next_stop_time"

  echo "good luck in the jungle"
}

main
