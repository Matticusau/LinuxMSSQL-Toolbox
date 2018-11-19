#!/bin/bash
# Purpose:  Just a script to record commands to prepare/archive/copy a set of log files off a server
#           Part of the LinuxMSSQL-Toolbox - https://github.com/Matticusau/LinuxMSSQL-Toolbox
# Author:   MatticusAu / MLavery (PFE)
# Date:     2018-07-06
# Version:  0.1.0
#
# Version   When          Who       What
# 0.1.0     2018-07-06    MatticusAu   Initial code
#

# switch to root
sudo -s

# navigate to folder and check files
cd /var/opt/mssql/log
ls -lh *AlwaysOn*

# -rw-rw---- 1 mssql mssql 48K Jul  5 16:48 AlwaysOn_health_0_131752345190300000.xel
# -rw-rw---- 1 mssql mssql 47K Jul  5 17:07 AlwaysOn_health_0_131752578014210000.xel
# -rw-rw---- 1 mssql mssql 54K Jul  5 20:02 AlwaysOn_health_0_131752589860950000.xel
# -rw-rw---- 1 mssql mssql 25K Jul  6 00:00 AlwaysOn_health_0_131752730482430000.xel

USERNAME="<user>"

# create a temporary folder
mkdir /home/$USERNAME/AlwaysOn_health

# copy the required logs
cp AlwaysOn_health* /home/$USERNAME/AlwaysOn_health

# set permissions/ownership
chown -R $USERNAME:$USERNAME /home/$USERNAME/AlwaysOn_health

# switch back to normal user
exit

# compress the folder
TARFILENAME="$(hostname)_AlwaysOn_health_20180706"
tar cfj $TARFILENAME.bz2 -C ~/AlwaysOn_health .

# remove the temporary folder
rm -r ~/AlwaysOn_health


