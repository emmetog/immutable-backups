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

# Features

* Works in "immutable storage" situations, when the backup agent only has permission to write, not modify or delete
* Can perform both full backups and incremental backups
* Can restore from both full backups and incremental backups

# Example of permissions in Google Cloud Storage

First a service account should be created with the following permissions:

* storage.objects.create
* storage.objects.get
* storage.objects.list

Give this service account access to the buckets you'll backup to.

If you are considering using different retention periods (eg monthly backups for 12 months, weekly backups for
4 weeks, daily backups for 7 days, etc) then create different buckets for each and apply the retention periods
to enforce the immutability, with lifecycle operations to cleanup once the retention period expires. Incremental
backups should not be cleaned up ever, otherwise you'll lose data, but retention periods are still a good idea
to give that extra immutability guarantee.

# Requirements

rclone must be installed and the remotes must be already configured.

This script is written in bash.

# Installing

    wget -O immutable-backup.sh https://github.com/emmetog/immutable-backups/blob/main/immutable-backups.sh
    chmod 0700 immutable-backup.sh

# Contributing

PRs are very welcome, however since this is pretty mission critical stuff, anything more than bugfixes or very
minor changes are less likely merged.

