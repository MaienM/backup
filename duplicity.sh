#!/bin/bash

# Options
[ -f ./env ] && source ./env
REMOTE_URL="${REMOTE_URL:-webdavs://user@stack.example.com/remote.php/webdav}"
GPG_KEY="${GPG_KEY:-01234567}"
DUPLICITY_DIR="${DUPLICITY_DIR:-/var/lib/duplicity}"

# Check permissions
if [ ! -r "$DUPLICITY_DIR" ]; then
    echo "You do not have permission to access the duplicity directory ($DUPLICITY_DIR)."
    echo "Please try again as root."
    exit 1
fi
if [ "$(stat "$DUPLICITY_DIR/secrets" --printf=%a)" != "600" ]; then
    echo "Invalid permissions on the secrets file ("$DUPLIC_TY_DIR/secrets")."
    echo "Please chmod 0600 it."
    exit 1
fi

# Check arguments
if [[ -z "$1" || ! -d "$1" ]]; then
    echo "Usage: $0 [path] [arguments...]"
    echo "Special arguments:"
    echo "  <path>: will be expanded to the path, inside the docker container"
    echo "          DO NOT PASS THE PATH DIRECTLY! This will NOT work"
    echo "  <url>: will be expanded to the appropriate url for this path"
    echo "  <name>: will be expanded to the name of this backup"
    exit 1
fi

# Process the path into a name without path separators
DIR="$1"
shift
NAME="${DIR//\//_}"

# Copy the remaining arguments, processing the special tags if present
args=()
for arg in "$@"; do
    case "$arg" in
        "<path>") arg="/workingdir/";;
        "<url>")  arg="$REMOTE_URL/$NAME/";;
        "<name>") arg="$NAME";;
    esac
    args+=("$arg")
done

# Run the duplicity command
docker run \
    --rm \
    -h "$HOSTNAME-duplicity" \
    -v "$DUPLICITY_DIR/gnupg":/root/.gnupg \
    -v "$DUPLICITY_DIR/archive":/root/.cache/duplicity \
    -v "$DIR":/workingdir:ro \
    --env-file "$DUPLICITY_DIR/secrets" \
    camptocamp/duplicity \
        --allow-source-mismatch \
        --encrypt-sign-key="$GPG_KEY" \
        --name="$NAME" \
        "${args[@]}"
