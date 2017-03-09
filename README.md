# Backups

This repository contains two script to manage backups using docker and duplicity.

The underlying idea of these scripts is that each folder is backed up separately from the rest,
without underlying dependencies.

## backup.sh

This is the main script to perform backups. It will perform a backup for every file/folder passed to
it as an argument.

Additionally, it uses the following environment variables to customize it's behavior:

- `FULL_IF_OLDER_THAN`: Force a full backup if the last full (non-incremental) backup was longer
  than this time period ago. Defaults to 14D (14 days).
- `REMOVE_OLDER_THAN`: Remove backups older than this time period. Full backups that are still
  needed for incremental backups will be kept as long as they are still needed. Defaults to 3M (3
  months).

## duplicity.sh

This script is a wrapped around a duplicity docker container. It uses gpg for encryption and signing
by default.

It uses the folloring environment variables to customize it's behavior:

- `REMOTE_URL`: A duplicity compatible target url for the backups. Subfolders will be made in this
  location for each of the backed up folders. Defaults to
  'webdavs://user@stack.example.com/remote.php/webdav'. The password should go in the secrets file,
  NOT in this URL.
- `GPG_KEY`: The GPG key signature.
- `DUPLICITY_DIR`: The root directory for duplicity to use. Defaults to `/var/lib/duplicity`. Inside
  of this directory should be the following:
  - `gnupg`: folder with gnupg key and related files (`secring.gpg`, `trustdbd.gpg`)
  - `secrets`: file with secrets in it. See `secrets_example`
  - `archive`: folder that will be used by duplicity for it's local cache

It takes at least one argument: the path to backup. Any additional arguments will be passed to
duplicity, with the following special arguments being expanded:
  - `<path>`: will be expanded to the path, inside the docker container
    DO NOT PASS THE PATH DIRECTLY! This will NOT work
  - `<url>`: will be expanded to the appropriate url for this path
  - `<name>`: will be expanded to the name of this backup
