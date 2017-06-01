#!/bin/bash

set -o pipefail -o errexit

DEFAULT_KEEP_HOURLY=48
DEFAULT_KEEP_DAILY=14
DEFAULT_KEEP_WEEKLY=8
DEFAULT_KEEP_MONTHLY=-1
DEFAULT_KEEP_YEARLY=-1
DEFAULT_RETRY=1
DEFAULT_RETRY_SLEEP=10

# Check arguments
if [[ -z "$1" || ! -f "$1" ]]; then
    echo "Usage: $0 [env file] [paths...]"
    echo
    echo "env file is a file with the following environment variables:"
    echo "  DESTINATION: the root destination folder. A subfolder in this folder will be"
    echo "    used for each of the source paths"
    echo "  TARGETS: the paths to backup. Combined with the paths passed as arguments"
    echo "  KEEP_HOURLY: the amount of hourly backups to keep [$DEFAULT_KEEP_HOURLY]"
    echo "  KEEP_DAILY: the amount of daily backups to keep [$DEFAULT_KEEP_DAILY]"
    echo "  KEEP_WEEKLY: the amount of weekly backups to keep [$DEFAULT_KEEP_WEEKLY]"
    echo "  KEEP_MONTHLY: the amount of monthly backups to keep [$DEFAULT_KEEP_MONTHLY]"
    echo "  KEEP_YEARLY: the amount of yearly backups to keep [$DEFAULT_KEEP_YEARLY]"
    echo "  RETRY: the amount of times to re-attempt a command if it fails [$DEFAULT_RETRY]"
    echo "  RETRY_SLEEP: the amount of time to wait between attempts, in seconds [$DEFAULT_RETRY_SLEEP]"
    echo
    echo "Of course, all of these can also just be set in the environment, as long as they"
    echo "are not overridden in the env file"
    echo
    echo "paths are the paths to backup. Is combined with \$TARGETS"
    echo
    echo "This script uses borg.sh internally, with the same env file, and thus supports"
    echo "all environment variables it does. In particular, \$DESTINATION and"
    echo "\$BORG_PASSPHRASE are important. Please run borg.sh to see it's help information"
    exit 1
fi

# Parse arguments
ENV_FILE="$1"
shift 1

# Options
KEEP_HOURLY="${KEEP_HOURLY:-$DEFAULT_KEEP_HOURLY}"
KEEP_DAILY="${KEEP_DAILY:-$DEFAULT_KEEP_DAILY}"
KEEP_WEEKLY="${KEEP_WEEKLY:-$DEFAULT_KEEP_WEEKLY}"
KEEP_MONTHLY="${KEEP_MONTHLY:-$DEFAULT_KEEP_MONTHLY}"
KEEP_YEARLY="${KEEP_YEARLY:-$DEFAULT_KEEP_YEARLY}"
RETRY="${RETRY:-$DEFAULT_RETRY}"
RETRY_SLEEP="${RETRY_SLEEP:-$DEFAULT_RETRY_SLEEP}"
source "$ENV_FILE"

# Function that calls the borg script
function borg() {
    "$(realpath "${BASH_SOURCE%/*}")/borg.sh" "$@" | sed 's/^/  /'
}

# Function that tries a command, with support for retrying
function do_with_retry() {
    attempt=0
    while true; do
        retval=0
        eval "$@" || retval=$?

        if [[ $retval -gt 0 ]]; then
            if [[ $attempt -lt $RETRY ]]; then
                attempt=$((attempt+1))
                echo >&2 "Retrying [$attempt/$RETRY]"
                sleep $RETRY_SLEEP
            else
                return $retval
            fi
        else
            return 0
        fi
    done
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
    do_with_retry borg "$ENV_FILE" "$bdir" create -v -s "::$(date +'%Y-%m-%d_%H:%M:%S')" "/source"
    echo

    # Cleanup old backups
    echo "=== Cleanup"
    echo
    do_with_retry borg "$ENV_FILE" "$bdir" prune -v -s \
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
for bdir in "$TARGETS" "$@"; do
    # If this folder has already been processed, skip
    if [[ ${statuses["$bdir"]+isset} ]]; then
        echo
        echo "Folder has already been backed up this run, skipping"
        echo
        continue
    fi

    # Backup the directory
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
