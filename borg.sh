#!/bin/bash

# Set strict
set -o errexit -o nounset -o pipefail

DEFAULT_DESTINATION="/backups"
DEFAULT_OUTER_BORG_KEYS_DIR="/var/lib/borgbackup/keys"
DEFAULT_OUTER_BORG_SECURITY_DIR="/var/lib/borgbackup/security"
DEFAULT_OUTER_BORG_CACHE_DIR="/var/lib/borgbackup/cache"

# Check arguments
if [[ -z "$1" || ! -f "$1" || -z $2 || ! -d "$2" ]]; then
    echo "Usage: $0 [ENV_FILE] [PATH] [ARGUMENTS...]"
    echo
    echo "ENV_FILE is a file with the following environment variables:"
    echo "  DESTINATION: the root destination folder. A subfolder in this folder will be"
    echo "    used for the backup, depending on the backed up path [$DEFAULT_DESTINATION]"
    echo "  BORG_PASSPHRASE: the passphrase to use"
    echo "  OUTER_BORG_KEYS_DIR: the path on the host where the borg keys are/should be"
    echo "    stored [$DEFAULT_OUTER_BORG_KEYS_DIR]"
    echo "  OUTER_BORG_SECURITY_DIR: the path on the host where the borg security"
    echo "    information is/should be stored [$DEFAULT_OUTER_BORG_SECURITY_DIR]"
    echo "  OUTER_BORG_CACHE_DIR: the path on the host where the borg cache are/should be"
    echo "    stored [$DEFAULT_OUTER_BORG_CACHE_DIR]"
    echo "  BORG_DOCKER_FLAGS: extra flags to pass to the docker command []"
    echo
    echo "Of course, all of these can also just be set in the environment, as long as they"
    echo "are not overridden in the env file"
    echo
    echo "Additionally, the ENV_FILE is passed to borg, so it can also contain any of the"
    echo "other environment variables recognized by borg, with the exception of"
    echo "\$BORG_REPO, \$BORG_KEYS_DIR, \$BORG_SECURITY_DIR and \$BORG_CACHE_DIR, as these"
    echo "are set automatically based on the environment variables defined above."
    echo
    echo "PATH is the folder to backup"
    echo
    echo "ARGUMENTS are arguments for borg"
    echo
    echo "As borg will be ran inside a docker container, the paths you pass must the ones"
    echo "inside of the container. These are the following:"
    echo "  /source: the source directory (passed to this command as PATH)"
    echo "  /destination: the destination directory (a subdirectory of \$DESTINATION based"
    echo "    on the source path). You shouldn't need to ever use this, as \$BORG_REPO is"
    echo "    set to this path, so not specifying the repository name should work"
    exit 1
fi

# Parse arguments
ENV_FILE="$1"
SOURCE="${2%/}"
shift 2

# Options
DESTINATION="${DESTINATION:-$DEFAULT_DESTINATION}"
OUTER_BORG_KEYS_DIR="${OUTER_BORG_KEYS_DIR:-$DEFAULT_OUTER_BORG_KEYS_DIR}"
OUTER_BORG_SECURITY_DIR="${OUTER_BORG_SECURITY_DIR:-$DEFAULT_OUTER_BORG_SECURITY_DIR}"
OUTER_BORG_CACHE_DIR="${OUTER_BORG_CACHE_DIR:-$DEFAULT_OUTER_BORG_CACHE_DIR}"
source "$ENV_FILE"

# Make sure the destination directory exists
DESTINATION="$DESTINATION/${SOURCE//\//_}"
mkdir -p "$(dirname $DESTINATION)"

# Determine whether to run interactively
BORG_DOCKER_FLAGS="${BORG_DOCKER_FLAGS:-}"
[ -t 1 ] && BORG_DOCKER_FLAGS="$BORG_DOCKER_FLAGS -i"

# Run the borg command
docker run \
    $BORG_DOCKER_FLAGS \
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
