#!/bin/bash

################################################################
# Configuration section                                        #
#                                                              #
# Enter your MySQL connection details in the config file shown #
# below, choose an encryption password and specify which       #
# databases should not be backed up                            #
################################################################

# MySQL config file
config=mysql-dropbox-backup.conf

# Backup file encryption password
encryption_pass=yourEncryptionPasssword

# List of databases to ignore (space separated)
db_ignore=(Database information_schema mysql performance_schema)

# Should we backup the MySQL "user" table?
backup_mysql_user_table=true

################################
# End of configuration section #
#                              #
# Nothing to edit below here   #
################################

# Get a list of databases
db_arr=$(echo "show databases;" | mysql --defaults-extra-file=$config)

# Get the current date. Used for file names etc...
current_date=$(date +"%Y-%m-%d")

# Get the date 7 days ago. Used to delete the redundant backup file.
old_date=$(date +"%Y-%m-%d" --date="7 days ago")

# Create a temporary backup directory to hold the SQL files, which will be deleted later
mkdir $current_date

# Backup each database (omitting any in the ignore list)
for dbname in ${db_arr}
do
    for i in "${db_ignore[@]}"
    do
        if ! [[ ${db_ignore[*]} =~ "$dbname" ]] ; then
            sqlfile=$current_date"/"$dbname".sql"
            echo "Dumping $dbname to $sqlfile"
            mysqldump --defaults-extra-file=$config $dbname > $sqlfile
            break
        fi
    done
done

# And finally, if configured, backup the "users" table from the "mysql" database that is omitted by default
if [[ "$backup_mysql_user_table" == true ]]; then
    sqlfile=$current_date"/mysql_users_table.sql"
    echo "Dumping MySql users table to $sqlfile"
    mysqldump --defaults-extra-file=$config mysql user > $sqlfile
fi

# Tar, compress, and encrypt the dumped SQL files
echo "Compressing and encrypting dumped SQL files..."
tar cz $current_date | openssl enc -aes-256-cbc -e -iter 30 -k $encryption_pass > $current_date.tar.gz.enc

# Remove the backups directory
echo "Removing dumped SQL files..."
rm -rf $current_date/

# Upload the backup tarball to Dropbox
echo "Uploading backup tarball to Dropbox..."
./dropbox_uploader.sh upload $current_date.tar.gz.enc $current_date.tar.gz.enc

# Delete the old backup
echo "Deleting old Dropbox backup..."
./dropbox_uploader.sh delete $old_date.tar.gz.enc

# Delete the local copy of the backup tarball that we just created
echo "Deleting local backup tarball..."
rm -f $current_date.tar.gz.enc

echo "Finished"
