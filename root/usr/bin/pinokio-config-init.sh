#!/bin/bash
set -euo pipefail

# Config file created by the app
CONFIG_FILE="${CONFIG_FILE:-/config/pinokio/ENVIRONMENT}"

# State file that persists across restarts; tracks which keys were already set
STATE_FILE="${STATE_FILE:-/config/pinokio/.pinokio_env_applied}"

# Requires bash (for associative arrays and ${!PREFIX_@} expansion)
declare -A applied
declare -A values
declare -a pending_keys=()

# Load already-applied keys from previous runs
if [[ -f "$STATE_FILE" ]]; then
  while IFS= read -r key; do
    [[ -n "$key" ]] && applied["$key"]=1
  done < "$STATE_FILE"
fi

# Collect all env vars starting with PINOKIO_
for var in ${!PINOKIO_@}; do
  key="$var"
  val="${!var}"

  # Optional: skip internal vars if you have any (example)
  # case "$key" in
  #   PINOKIO_INTERNAL_* ) continue ;;
  # esac

  # Skip keys we've already applied in a previous container run
  if [[ -n "${applied[$key]+x}" ]]; then
    continue
  fi

  values["$key"]="$val"
  pending_keys+=("$key")
done

# If there’s nothing to do, exit
((${#pending_keys[@]} == 0)) && exit 0

# Escape value for use in sed replacement
escape_sed() {
  # escape \, &, and | (we use | as sed delimiter)
  printf '%s' "$1" | sed 's/[\/&|\\]/\\&/g'
}

# Main loop: wait for config file and keys to appear, then set them once
while :; do
  # All pending keys handled → done
  ((${#pending_keys[@]} == 0)) && break

  # Wait until the config file exists
  [[ -f "$CONFIG_FILE" ]] || { sleep 1; continue; }

  new_pending=()

  for key in "${pending_keys[@]}"; do
    # Might have been applied in a previous iteration
    if [[ -n "${applied[$key]+x}" ]]; then
      continue
    fi

    # Only touch keys that already exist in the config file
    if grep -q "^${key}=" "$CONFIG_FILE"; then
      val="${values[$key]}"
      val_escaped="$(escape_sed "$val")"

      sed -i "s|^${key}=.*|${key}=${val_escaped}|" "$CONFIG_FILE"

      # Record as applied so we never touch this key again on future starts
      applied["$key"]=1
      echo "$key" >> "$STATE_FILE"
    else
      # Keep this key for the next loop iteration
      new_pending+=("$key")
    fi
  done

  pending_keys=("${new_pending[@]}")

  sleep 0.5
done