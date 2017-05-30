#!/bin/bash

set -o pipefail

# Check arguments
if [[ -z "$1" || ! -f "$1" ]]; then
    echo "Usage: $0 [env file] [paths...]"
    echo
    echo "env file is a file with the following environment variables:"
    echo "  DESTINATION: the root destination folder. A subfolder in this"
    echo "    folder will be used for each of the source paths"
    echo "  BORG_PASSPHRASE: the passphrase to use"
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

# Function that calls the borg script
function borg() {
    "$(realpath "${BASH_SOURCE%/*}")/borg.sh" "$@" | sed 's/^/  /'
}

# Function that processes a directory
function process_directory() {
    echo "== $bdir"
    echo
    borg "$ENV_FILE" "$bdir" init -e keyfile &> /dev/null \
        && echo "Initialized new repository" \
        || echo "Using existing repository"
    echo

    # Create new backups
    echo "=== Backup"
    echo
    borg "$ENV_FILE" "$bdir" create -v -s "::$(date +'%Y-%m-%d_%H:%M:%S')" "/source" || return 1
    echo

    # Cleanup old backups
    echo "=== Cleanup"
    echo
    borg "$ENV_FILE" "$bdir" prune -v -s \
        --keep-hourly="$KEEP_HOURLY" \
        --keep-daily="$KEEP_DAILY" \
        --keep-weekly="$KEEP_WEEKLY" \
        --keep-monthly="$KEEP_MONTHLY" \
        --keep-yearly="$KEEP_YEARLY" \
    || return 1
    echo
}

echo "= Backup report"
echo "$(hostname)"
echo "$(date +'%Y-%m-%d %H.%M')"
echo

declare -A statuses
failed=0
for bdir in "$@"; do
    process_directory "$bdir"
    statuscode=$?

    # If the processing failed, indicate so
    if [[ $statuscode -ne 0 ]]; then
        echo
        echo >&2 "WARNING: Action failed"
        echo
        failed=1
    fi

    # Store the result in the list for the final summary
    statuses["$bdir"]=$statuscode
done

# Final summary
echo "== Summary"
echo
for bdir in "$@"; do
    [ "${statuses["$bdir"]}" -eq 0 ] \
        && echo "- ✓ $bdir" \
        || echo "- ✗ **$bdir**"
done

# Exit with 0 if everything succeeded, and with 1 if anything failed
exit $failed
