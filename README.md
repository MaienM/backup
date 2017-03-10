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
  DESTINATION: the root destination folder. A subfolder in this
    folder will be used for each of the source paths
  ATTIC_PASSPHRASE: the passphrase to use
  KEEP_HOURLY: the amount of hourly backups to keep
  KEEP_DAILY: the amount of daily backups to keep
  KEEP_WEEKLY: the amount of weekly backups to keep
  KEEP_MONTHLY: the amount of monthly backups to keep
  KEEP_YEARLY: the amount of yearly backups to keep
```

## attic.sh

This script is a wrapper around an attic docker container.

```
Usage: ./attic.sh [env file] [path] [arguments...]

env file is a file with the following environment variables:
  DESTINATION: the root destination folder. A subfolder in this
    folder will be used for the backup, depending on the backed up
    path
  ATTIC_PASSPHRASE: the passphrase to use

path is the folder to backup

As attic will be ran inside a docker container, the paths you pass
must the ones inside of the container. These are the following:
  /source: the source directory (passed to this command as path)
  /destination: the destination directory (a subdirectory of
    $DESTINATION based on the source path)
```
