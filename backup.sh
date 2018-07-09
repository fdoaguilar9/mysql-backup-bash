#/bin/bash
# Fernando Aguilar
# MySQL/MariaDB backup script
# This script creates a compressed file containing multiple .sql files
# Each .sql file is a DUMP from a database on the server. The script creates a file for each database.
# You can modify the crontab to schedule this script to run as frequently as you want. (Currently running once per day) 
###################################################################################
 
# Set properties in this file
SYSCONFIG="/etc/sysconfig/dbbackup"
 
# User must have SELECT, SHOW VIEW, EVENT, and TRIGGER privileges or... root
# Property file syntax:
#USERNAME="USERNAME"
#PASSWORD="PASSWORD"
 
# Archive path
ARCHIVE_PATH="/var/backups/mariadb"
 
# Archive filename
ARCHIVE_FILE="databases_`date +%F_%H-%M-%S`.tbz2"
 
# Archives older than this will be deleted
ARCHIVE_DAYS="15"
 
# Set or override config variables here
if [ -f $SYSCONFIG ]; then
    source $SYSCONFIG
fi
 
if [ -z "$USERNAME" ] || [ -z "$PASSWORD" ]; then
    echo "You must set USERNAME and PASSWORD in $SYSCONFIG";
    exit
fi
 
# Change working directory
cd $ARCHIVE_PATH
 
# Get all of the databases
for database in `mysql -u $USERNAME -p"$PASSWORD" -h 127.0.0.1 -Bse 'show databases'`; do
        # Skip ones we don't want to back up
        if [ "performance_schema" == "$database" ]; then continue; fi
        if [ "information_schema" == "$database" ]; then continue; fi
 
        # Use Nice to dump the database
        nice mysqldump -u $USERNAME -p"$PASSWORD" -h 127.0.0.1 --events $database > $database.sql
done
 
# Use Nice to create a tar compressed with bzip2
nice tar -czvf $ARCHIVE_FILE *.sql
 
# Remove the SQL files
nice rm -rf *.sql
 
# Remove old archive files
nice find . -mtime +$ARCHIVE_DAYS -exec rm {} \;
