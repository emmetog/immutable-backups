# Immutable Backups
A wrapper around [rclone](https://rclone.org/) to perform immutable backups, both full and incremental, and restore them.

[Born](https://forum.rclone.org/t/rclone-copy-without-modification-deletion-immutable-storage/23839)
out of a need to put greater guarantees of immutability on backups, by restricting the permissions
that the backup agent has as much as possible. With this script the agent only needs:

* Write
* Read

The agent does NOT require Replace or Delete privileges.

In addition to restricting the permissions that the backup agent has, it's recommended to configure
retention policies to further enforce immutability. This tool will be fine in these conditions, as
it doesn't modify or delete anything once written.

Also recommended to use lifecycle actions to remove objects after a time has elapsed if needed, or another process
with DELETE permissions can be used if that's not available.

# Requirements

rclone must be installed and the remotes must be already configured.

This script is written in bash.

# Installing

    wget -O immutable-backup.sh https://github.com/emmetog/immutable-backups/blob/main/immutable-backups.sh
    chmod 0700 immutable-backup.sh

# Contributing

PRs are very welcome, however since this is pretty mission critical stuff, anything more than bugfixes or very
minor changes are less likely merged.

