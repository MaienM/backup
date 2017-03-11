#!/bin/bash

# Check arguments
if [[ -z "$1" || ! -f "$1" ]]; then
    echo "Usage: $0 [env file] [paths...]"
    echo
    echo "env file is a file with the following environment variables:"
    echo "  DESTINATION: the root destination folder. A subfolder in this"
    echo "    folder will be used for each of the source paths"
    echo "  ATTIC_PASSPHRASE: the passphrase to use"
    echo "  KEEP_HOURLY: the amount of hourly backups to keep"
    echo "  KEEP_DAILY: the amount of daily backups to keep"
    echo "  KEEP_WEEKLY: the amount of weekly backups to keep"
    echo "  KEEP_MONTHLY: the amount of monthly backups to keep"
    echo "  KEEP_YEARLY: the amount of yearly backups to keep"
    exit 1
fi

# Parse arguments
ENV_FILE="$1"
shift 1

# Options
KEEP_HOURLY=${KEEP_HOURLY:-48}
KEEP_DAILY=${KEEP_DAILY:-14}
KEEP_WEEKLY=${KEEP_WEEKLY:-8}
KEEP_MONTHLY=${KEEP_MONTHLY:--1}
KEEP_YEARLY=${KEEP_YEARLY:--1}
source "$ENV_FILE"

# Function to easily abort on failure
function die() {
    echo "==================== Results ===================="
    echo
    echo >&2 "Action failed, aborting"
    exit 1
}

# Function that calls the attic script
function attic() {
    "$(realpath "${BASH_SOURCE%/*}")/attic.sh" "$@"
}

for bdir in "$@"; do
    echo "==================== $bdir ===================="

    # Create new backups
    echo "===== Backup ====="
    echo
    attic "$ENV_FILE" "$bdir" init /destination -e passphrase &> /dev/null \
        && echo "Initialized new repository" \
        || echo "Using existing repository"
    attic "$ENV_FILE" "$bdir" create -s "/destination::$(date +'%Y-%m-%d_%H:%M:%S')" "/source" || die

    # Cleanup old backups
    echo "===== Cleanup ====="
    echo
    attic "$ENV_FILE" "$bdir" prune -s /destination \
        --keep-hourly="$KEEP_HOURLY" \
        --keep-daily="$KEEP_DAILY" \
        --keep-weekly="$KEEP_WEEKLY" \
        --keep-monthly="$KEEP_MONTHLY" \
        --keep-yearly="$KEEP_YEARLY" \
    || die

    echo
done

echo "==================== Results ===================="
echo
echo "Backups completed!"
