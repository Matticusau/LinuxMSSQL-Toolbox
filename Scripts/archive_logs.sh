#!/bin/bash
# Purpose:  Archives log files based on parameters
# Author:   MLavery (PFE)
# Date:     22/06/2018
# Version:  0.1.0
#
# Version   When          Who       What
# 0.1.0     22/06/2018    MLavery   Initial file
#
# make sure you have execute rights
# chmod +rwx archive_logs.sh
#
# schedule with a cron job
# run "crontab -e" while logged in as the user with execute permissions on the script
# use vi to add this line to schedule every 15 mins
# 45 23 * * * /home/<user>/archive_logs.sh > /dev/null 2>&1
#

NOW=$(date +%Y_%m_%d_%H_%M_%S)
LOG_FILE_DIR=/home/<user>/pfecheck/log
LOG_FILE_RETENTION=1;

# set the working directory
cd $LOG_FILE_DIR;

# create the temporary folder
mkdir $NOW;

# move the log files to the temporary folder
find $LOG_FILE_DIR/* -type f -mtime +$LOG_FILE_RETENTION -exec mv {} ./$NOW \;

# compress the folder
tar cfj $NOW.bz2 -C $NOW .

# remove the temporary folder
rm -r ./$NOW
