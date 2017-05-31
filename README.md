# Backups

This repository contains two script to manage backups using docker and attic.

The underlying idea of these scripts is that each folder is backed up separately from the rest,
without underlying dependencies.

## backup.sh

This is the main script to perform backups. It will perform a backup for every file/folder passed to
it as an argument.

```
Usage: ./backup.sh [env file] [paths...]

env file is a file with the following environment variables:
  DESTINATION: the root destination folder. A subfolder in this folder will be
    used for each of the source paths
  TARGETS: the paths to backup. Combined with the paths passed as arguments
  KEEP_HOURLY: the amount of hourly backups to keep [48]
  KEEP_DAILY: the amount of daily backups to keep [14]
  KEEP_WEEKLY: the amount of weekly backups to keep [8]
  KEEP_MONTHLY: the amount of monthly backups to keep [-1]
  KEEP_YEARLY: the amount of yearly backups to keep [-1]

Of course, all of these can also just be set in the environment, as long as they
are not overridden in the env file

paths are the paths to backup. Is combined with $TARGETS

This script uses borg.sh internally, with the same env file, and thus supports
all environment variables it does. In particular, DESTINATION and
BORG_PASSPHRASE are important. Please run borg.sh to see it's help information
```

## borg.sh

This script is a wrapper around an borg docker container.

```
Usage: ./borg.sh [env file] [path] [arguments...]

env file is a file with the following environment variables:
  DESTINATION: the root destination folder. A subfolder in this folder will be
    used for the backup, depending on the backed up path [/backups]
  BORG_PASSPHRASE: the passphrase to use
  OUTER_BORG_KEYS_DIR: the path on the host where the borg keys are/should be
    stored [/var/lib/borgbackup/keys]
  OUTER_BORG_SECURITY_DIR: the path on the host where the borg security
    information is/should be stored [/var/lib/borgbackup/security]
  OUTER_BORG_CACHE_DIR: the path on the host where the borg cache are/should be
    stored [/var/lib/borgbackup/cache]
  BORG_DOCKER_FLAGS: extra flags to pass to the docker command []

Of course, all of these can also just be set in the environment, as long as they
are not overridden in the env file

path is the folder to backup

As borg will be ran inside a docker container, the paths you pass must the ones
inside of the container. These are the following:
  /source: the source directory (passed to this command as path)
  /destination: the destination directory (a subdirectory of $DESTINATION based
    on the source path). You shouldn't need to ever use this, as BORG_REPO is
    set to this path, so not specifying the repository name should work
```
