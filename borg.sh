#!/bin/bash

# Check arguments
if [[ -z "$1" || ! -f "$1" || -z $2 || ! -d "$2" ]]; then
    echo "Usage: $0 [env file] [path] [arguments...]"
    echo
    echo "env file is a file with the following environment variables:"
    echo "  DESTINATION: the root destination folder. A subfolder in this"
    echo "    folder will be used for the backup, depending on the backed up"
    echo "    path"
    echo "  BORG_PASSPHRASE: the passphrase to use"
    echo
    echo "path is the folder to backup"
    echo
    echo "As borg will be ran inside a docker container, the paths you pass"
    echo "must the ones inside of the container. These are the following:"
    echo "  /source: the source directory (passed to this command as path)"
    echo "  /destination: the destination directory (a subdirectory of"
    echo "    \$DESTINATION based on the source path). You shouldn't need to"
    echo "    ever use this, as BORG_REPO is set to this path, so not"
    echo "    specifying the repository name should work"
    exit 1
fi

# Parse arguments
ENV_FILE="$1"
SOURCE="$2"
shift 2

# Options
DESTINATION="${DESTINATION:-/backups}"
OUTER_BORG_KEYS_DIR="${OUTER_BORG_KEYS_DIR:-/var/lib/borgbackup/keys}"
OUTER_BORG_SECURITY_DIR="${OUTER_BORG_SECURITY_DIR:-/var/lib/borgbackup/security}"
OUTER_BORG_CACHE_DIR="${OUTER_BORG_CACHE_DIR:-/var/lib/borgbackup/cache}"
source "$ENV_FILE"

# Make sure the destination directory exists
DESTINATION="$DESTINATION/${SOURCE//\//_}"
mkdir -p "$(dirname $DESTINATION)"

# Run the borg command
docker run \
    --rm \
    -t \
    -h "$HOSTNAME-borg" \
    -w / \
    -v "$SOURCE":/source \
    -v "$DESTINATION":/destination \
    -v "$OUTER_BORG_KEYS_DIR":/borg/keys \
    -v "$OUTER_BORG_SECURITY_DIR":/borg/security \
    -v "$OUTER_BORG_CACHE_DIR":/borg/cache \
    --env-file "$ENV_FILE" \
    -e "BORG_REPO=/destination" \
    -e "BORG_KEYS_DIR=/borg/keys" \
    -e "BORG_SECURITY_DIR=/borg/security" \
    -e "BORG_CACHE_DIR=/borg/cache" \
    maienm/borgbackup "$@"
