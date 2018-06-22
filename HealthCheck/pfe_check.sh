#!/bin/bash
# Purpose:  Provides a check of the Linuxserver for use with monitoring / health check activities
#           Part of the LinuxMSSQL-Toolbox - https://github.com/Matticusau/LinuxMSSQL-Toolbox
# Author:   Matticusau / MLavery (PFE)
# Date:     19/06/2018
# Version:  0.1.2
#
# Version   When          Who       What
# 0.1.1     20/06/2018    MLavery   Added log file clean up, SQL scripts, work file logging
# 0.1.2     21/06/2018    MLavery   Added Top Waits check
# 0.1.3     22/06/2018    MLavery   Added VLFs, DB Space
#
# make sure you have execute rights
# chmod +rwx pfe_check.sh
#
# make sure sqlcmd (mssql-tools) is installed and the bin folder is in the path variable
# PATH=$PATH:/opt/mssql-tools/bin
#
# schedule with a cron job
# run "crontab -e" while logged in as the user with execute permissions on the script
# use vi to add this line to schedule every 15 mins
# */30 * * jun * /home/<user>/pfecheck/pfe_check.sh > /dev/null 2>&1
#

NOW=$(date +%Y_%m_%d_%H_%M_%S)
SCRIPT_FILE_DIR=/home/<user>/pfecheck
LOG_FILE_DIR=/home/<user>/pfecheck/log
LOG_FILE="$LOG_FILE_DIR/$(hostname)_$NOW.log";
LOG_FILE_RETENTION=7;
DISK_MNT_FILTER="/log|/data|/backup|/var";
SQL_LOG_LINES=25;
SQL_USER=
SQL_PWD=
CHECK_SQL=1;
CHECK_SQL_AG=1;
CHECK_PACEMAKER=1;

# set the working directory
cd $LOG_FILE_DIR;

# clean up an old log files
COUNT=$(find $LOG_FILE_DIR/*.log -mtime +$LOG_FILE_RETENTION | wc -c);
if [ $COUNT -gt 0 ];
then
    echo "Cleaning up $COUNT old log files...";
    find "$LOG_FILE_DIR/*.log" -mtime +$LOG_FILE_RETENTION -exec rm -f {} \; 
fi

# set the work file name
WORK_FILE="$LOG_FILE.work"

# initialise the file each time
echo -e "" > $WORK_FILE;

# header
echo -e "**************************************************************\nPFE Check" >> $WORK_FILE;
echo -e $(hostname) >> $WORK_FILE;
echo -e $NOW >> $WORK_FILE;
echo -e "**************************************************************" >> $WORK_FILE;

# cpu usage
echo -e "\n-------------------------------\nCPU (top)\n-------------------------------" >> $WORK_FILE;
top -b -n1 | head -n 20 >> $WORK_FILE;

# cpu usage
echo -e "\n-------------------------------\nCPU IO (iostat)\n-------------------------------" >> $WORK_FILE;
iostat >> $WORK_FILE;

# disk IO
echo -e "\n-------------------------------\nDisk IO\n-------------------------------" >> $WORK_FILE;
dstat -tdD total --output $WORK_FILE 30 5

# disk space
echo -e "\n-------------------------------\nDisk Space\n-------------------------------" >> $WORK_FILE;
echo -e "Date\tSize\tUsed\tAvail\tUsePct\tMnt" >> $WORK_FILE;
df -h | grep -E "($DISK_MNT_FILTER)" | awk -v out_file="$WORK_FILE" ' BEGIN { OFS="\t"; ORS="\n" } { print strftime("[%Y-%m-%d %H:%M:%S]"), $2, $3, $4,  $5, $6 >> out_file}'
# df -h | awk -v out_file="$WORK_FILE" ' BEGIN { OFS="\t"; ORS="\n" } { print strftime("[%Y-%m-%d %H:%M:%S]"), $2, $3, $4,  $5, $6 >> out_file}'

# SQL checks
if [ $CHECK_SQL -eq 1 ];
then
    # SQL ErrorLog
    echo -e "\n-------------------------------\nSQL ERRORLOG ($SQL_LOG_LINES lines)\n-------------------------------" >> $WORK_FILE;
    sudo tail -n $SQL_LOG_LINES /var/opt/mssql/log/errorlog  >> $WORK_FILE;

    # SQL ErrorLog Errors
    echo -e "\n-------------------------------\nSQL ERRORLOG Errors\n-------------------------------" >> $WORK_FILE;
    sudo cat /var/opt/mssql/log/errorlog | grep error >> $WORK_FILE;

    # VLFs
    echo -e "\n-------------------------------\nUser DB File Free Space\n-------------------------------" >> $WORK_FILE;
    /opt/mssql-tools/bin/sqlcmd -S. -U$SQL_USER -P$SQL_PWD -i $SCRIPT_FILE_DIR/MonitorDBSpace.sql -W -s "," >> $WORK_FILE;

    # SQL ErrorLog Errors
    echo -e "\n-------------------------------\nLog File Reuse\n-------------------------------" >> $WORK_FILE;
    /opt/mssql-tools/bin/sqlcmd -S. -U$SQL_USER -P$SQL_PWD -Q "SELECT name, log_reuse_wait_desc FROM sys.databases ORDER BY name" -W -s "," >> $WORK_FILE;

    # SQL Top Waits
    echo -e "\n-------------------------------\nTop Waits\n-------------------------------" >> $WORK_FILE;
    /opt/mssql-tools/bin/sqlcmd -S. -U$SQL_USER -P$SQL_PWD -i $SCRIPT_FILE_DIR/MonitorTopWaits.sql -W -s "," >> $WORK_FILE;

    # VLFs
    echo -e "\n-------------------------------\nVLFs (>1000)\n-------------------------------" >> $WORK_FILE;
    /opt/mssql-tools/bin/sqlcmd -S. -U$SQL_USER -P$SQL_PWD -i $SCRIPT_FILE_DIR/MonitorVLFs.sql -W -s "," >> $WORK_FILE;

fi

# Availability Group checks
if [ $CHECK_SQL_AG -eq 1 ];
then
    # AG Replica Roles
    echo -e "\n-------------------------------\nAG Replica Roles\n-------------------------------" >> $WORK_FILE;
    /opt/mssql-tools/bin/sqlcmd -S. -U$SQL_USER -P$SQL_PWD -i $SCRIPT_FILE_DIR/MonitorAGReplicaRoles.sql -W -s "," >> $WORK_FILE;

    # AG Health
    echo -e "\n-------------------------------\nAG Replica Health\n-------------------------------" >> $WORK_FILE;
    /opt/mssql-tools/bin/sqlcmd -S. -U$SQL_USER -P$SQL_PWD -i $SCRIPT_FILE_DIR/MonitorAGReplicaHealth.sql -W -s "," >> $WORK_FILE;

     # AG Database Health
    echo -e "\n-------------------------------\nAG Database Health\n-------------------------------" >> $WORK_FILE;
    /opt/mssql-tools/bin/sqlcmd -S. -U$SQL_USER -P$SQL_PWD -i $SCRIPT_FILE_DIR/MonitorAGDbHealth.sql -W -s "," >> $WORK_FILE;

fi

# Pacemaker checks
if [ $CHECK_PACEMAKER -eq 1 ];
then
    # PCS status
    echo -e "\n-------------------------------\nPCS Status\n-------------------------------" >> $WORK_FILE;
    sudo pcs status >> $WORK_FILE;

    # PCS Location Constraints 
    echo -e "\n-------------------------------\nPCS Location Constraints\n-------------------------------" >> $WORK_FILE;
    sudo pcs constraint list --full >> $WORK_FILE;
fi

# rename the work file to the log file
mv $WORK_FILE $LOG_FILE;

# footer
# echo -e "\n**************************************************************\nPFE Monitor Complete\n**************************************************************\n\n\n" >> $WORK_FILE;

