#!/bin/bash

# Options
FULL_IF_OLDER_THAN="${FULL_IF_OLDER_THAN:-14D}"
REMOVE_OLDER_THAN="${REMOVE_OLDER_THAN:-3M}"

function duplicity() {
    "$(realpath "${BASH_SOURCE%/*}")/duplicity.sh" "$@" || die
}

function die() {
    echo "==================== Results ===================="
    echo
    echo >&2 "Action failed, aborting"
    exit 1
}

for bdir in "$@"; do
    echo "==================== $bdir ===================="

    # Create new backups
    echo "===== Backup ====="
    echo
    duplicity "$bdir" --full-if-older-than="$FULL_IF_OLDER_THAN" "<path>" "<url>" || die

    # Cleanup old backups
    echo "===== Cleanup ====="
    echo
    duplicity "$bdir" remove-older-than "$REMOVE_OLDER_THAN" --force "<url>" || die

    echo
done

echo "==================== Results ===================="
echo
echo "Backups completed!"
