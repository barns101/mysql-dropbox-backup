#!/bin/bash

################################################################
# Configuration section                                        #
#                                                              #
# Enter your MySQL connection details, choose an encryption    #
# password and specify which databases should not be backed up #
################################################################

# MySQL database connection details
mysql_host=localhost
mysql_user=root
mysql_passwd=yourRootPassword

# Backup file encryption password
encryption_pass=yourEncryptionPasssword

# List of databases to ignore (space separated)
db_ignore=(Database information_schema mysql performance_schema)

################################
# End of configuration section #
#                              #
# Nothing to edit below here   #
################################

# Get a list of databases
db_arr=$(echo "show databases;" | mysql -u$mysql_user -p$mysql_passwd -h$mysql_host)

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
            mysqldump -u$mysql_user -p$mysql_passwd -h$mysql_host $dbname > $sqlfile
            break
        fi
    done
done

# Tar, compress, and encrypt the dumped SQL files
echo "Compressing and encrypting dumped SQL files..."
tar cz $current_date | openssl enc -aes-256-cbc -e -k $encryption_pass > $current_date.tar.gz.enc

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
