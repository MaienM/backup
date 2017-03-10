#!/bin/bash

# Check arguments
if [[ -z "$1" || ! -f "$1" || -z $2 || ! -d "$2" ]]; then
    echo "Usage: $0 [env file] [path] [arguments...]"
    echo
    echo "env file is a file with the following environment variables:"
    echo "  DESTINATION: the root destination folder. A subfolder in this"
    echo "    folder will be used for the backup, depending on the backed up"
    echo "    path"
    echo "  ATTIC_PASSPHRASE: the passphrase to use"
    echo
    echo "path is the folder to backup"
    echo
    echo "As attic will be ran inside a docker container, the paths you pass"
    echo "must the ones inside of the container. These are the following:"
    echo "  /source: the source directory (passed to this command as path)"
    echo "  /destination: the destination directory (a subdirectory of"
    echo "    \$DESTINATION based on the source path)"
    exit 1
fi

# Parse arguments
ENV_FILE="$1"
SOURCE="$2"
shift 2

# Options
DESTINATION="${DESTINATION:-/backups}"
source "$ENV_FILE"

# Make sure the destination directory exists
DESTINATION="$DESTINATION/${SOURCE//\//_}"
mkdir -p "$(dirname $DESTINATION)"

# Run the attic command
docker run \
    --rm \
    -h "$HOSTNAME-attic" \
    -v "$SOURCE":/source:ro \
    -v "$DESTINATION":/destination \
    --env-file "$ENV_FILE" \
    pataquets/attic "$@"
