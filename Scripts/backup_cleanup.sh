#!/bin/bash
# Purpose:  Cleans up the MSSQL backups
#           Part of the LinuxMSSQL-Toolbox - https://github.com/Matticusau/LinuxMSSQL-Toolbox
# Author:   Matticusau / MLavery
# Date:     19/06/2018
# Version:  0.1.0
#
# Version   When          Who       What
# 0.1.0     20/06/2018    MLavery   Initial version
# 
# make sure you have execute rights
# chmod +rwx backup_cleanup.sh
#
# schedule with a cron job
# run "sudo crontab -u root -e" while logged in as the user with execute permissions on the script
# use vi to add this line to schedule every 15 mins
# 0 23 * * * /backup/backup_cleanup.sh > /dev/null 2>&1
#

# settings
FULL_BKP_DIR=/backup/full
DIFF_BKP_DIR=/backup/diff
TLOG_BKP_DIR=/backup/log
FULL_BKP_RETENTION=14;
DIFF_BKP_RETENTION=14;
TLOG_BKP_RETENTION=1;

# current time
NOW=$(date +%Y_%m_%d_%H_%M_%S)

echo -e "Clean up starting $(date +%Y_%m_%d_%H_%M_%S)";

# clean up full backups
echo -e "Start cleanup process >> $NOW" >> $FULL_BKP_DIR/cleanup.log;
CMD="find $FULL_BKP_DIR/*.bak -type f -mtime +$FULL_BKP_RETENTION"
COUNT=$($CMD -printf '.' 2>/dev/null | wc -c);
echo -e ">>> $COUNT Diff backups";
$($CMD -exec ls -lrt {} \; 2>/dev/null) >> $FULL_BKP_DIR/cleanup.log
sudo $CMD -exec rm -f {} \;

# clean up differential backups
echo -e "Start cleanup process >> $NOW" >> $DIFF_BKP_DIR/cleanup.log;
CMD="find $DIFF_BKP_DIR/*.bak -type f -mtime +$DIFF_BKP_RETENTION"
COUNT=$($CMD -printf '.' 2>/dev/null | wc -c);
echo -e ">>> $COUNT Diff backups";
$($CMD -exec ls -lrt {} \; 2>/dev/null) >> $DIFF_BKP_DIR/cleanup.log
sudo $CMD -exec rm -f {} \;

# clean up transaction log backups
echo -e "Start cleanup process >> $NOW" >> $TLOG_BKP_DIR/cleanup.log;
CMD="find $TLOG_BKP_DIR/*.trn -type f -mtime +$TLOG_BKP_RETENTION"
COUNT=$($CMD -printf '.' 2>/dev/null | wc -c);
echo -e ">>> $COUNT Transaction Log backups";
$($CMD -exec ls -lrt {} \; 2>/dev/null) >> $TLOG_BKP_DIR/cleanup.log
sudo $CMD -exec rm -f {} \;

echo -e "Clean up finished $(date +%Y_%m_%d_%H_%M_%S)";
