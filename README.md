# mysql-dropbox-backup

Dump MySQL databases, compress & encrypt them, and upload to [Dropbox] for a simple off-site backup.

## Overview

`mysql-dropbox-backup` is a simple shell script that will use `mysqldump` to dump all of your MySQL databases, omitting any that you specify. It will then add them to a compressed and encrypted tarball, and upload them to [Dropbox] for a simple off-site backup solution. By default it will also dump the MySQL `user` table. The script makes use of the [Dropbox-Uploader] project by [Andrea Fabrizi]. Run it as a daily cron job to keep 7 days of backups by default. On each run it will try to delete the backup taken 7 days ago.

## Requirements

* cURL
* OpenSSL
* A [Dropbox] account
* [Dropbox-Uploader]

Most Linux systems will come with cURL and OpenSSL installed. [Dropbox] gives away 2GB of storage for free.

## Installation

First grab a copy of [Dropbox-Uploader], follow its installation instructions, and link it to your [Dropbox] account. I have it installed in my home directory, but it can reside elsewhere.

Next get a copy of `mysql-dropbox-backup.sh` and `mysql-dropbox-backup.conf`, and save them in the same directory as `dropbox_uploader.sh`.

Edit `mysql-dropbox-backup.conf` to add your MySQL connection details. (These are stored in a separate file so that your MySQL credentials are not passed via the CLI and logged.)

Edit the top section of `mysql-dropbox-backup.sh` to specify your MySQL config file location, your chosen encryption password for your backup file, and edit the list of ignored databases if you wish. You can also choose whether to dump the MySQL `user` table or not.

## Usage

`mysql-dropbox-backup` is run from the CLI with no parameters like this:

```
./mysql-dropbox-backup.sh
```

Ideally it will be run as a daily cron job. After uploading the new backup, it will attempt to delete the backup from 7 days previous, so that only one week of backups are retained.

This example crontab entry will run it from your home directory at 1 minute past midnight every day:

```
1 0 * * * ./mysql-dropbox-backup.sh
```

The script is quite verbose and will output which databases were backed up and the names of any files generated etc...

## Restoring a Backup

In the event that you need to restore a backup, once downloaded from [Dropbox] it can be decrypted and the tarball extracted as follows:

```
openssl enc -aes-256-cbc -d -iter 30 -in <backup-file.tar.gz.enc> | tar xz
```

Then the SQL files will be available to restore within the resulting directory.

   [Dropbox]: <https://www.dropbox.com>
   [Dropbox-Uploader]: <https://github.com/andreafabrizi/Dropbox-Uploader>
   [Andrea Fabrizi]: <https://github.com/andreafabrizi>