#!/bin/bash
############
# Copyright (C) 2018  Emmanuel Vargas <emmanuel.vargas@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

#
# Master script called from crontab to manage the everyday backup work
#
############

startDate="`date +\%F`"
startDoW="`date +\%w`"
qhbackupLogFile="/var/log/backup/all.`date +\%Y\%m\%d`.log"

htmlLogs="/var/www/backup/${HOSTNAME}/${startDate}.html"
urlLogs="https://myserver/backup/${HOSTNAME:0:3}/${startDate}.html"

# Loading General environment
APP_PATH=$(cd `dirname $0`; pwd)
CONF_PATH="$APP_PATH/conf"
if [ ! -f "$CONF_PATH/backup.env" ]
then
        echo "backup.env does not exist: no environment file, exiting"
        exit 1
fi
source $CONF_PATH/backup.env

# Creating html log file
if [ -f ${htmlLogs} ]
then
        htmlLogs="/var/www/backup/${HOSTNAME}/${startDate}_`date +\%H-%M`.html"
fi
echo "<html><head><title>backup/${HOSTNAME}/${startDate}</title></head><body><h1>backup/${HOSTNAME}/${startDate}</h1>" > ${htmlLogs}

## Try to connect to servers and update the QuantInfra Server.prod field (=1)
#./updateProdServer.sh -H >> ${htmlLogs}  # Now done from the jumboxes

# Add up to 10 new servers to the backup process
./qhbAutoActivateBackup.sh -H >> ${htmlLogs}

# Synchronize local configuration from the QuantInfra database
./qhbUpdateLocalConf.sh -H >> ${htmlLogs}

# Return from QuantInfra the servers reachable but with is_backuped undefined
./qhbShowNotBackuped.sh -H | tee -a ${htmlLogs}

if [ ${startDoW} -eq 6 ]
then
        # Once a week, backup configuration from other qhbackup servers
        ./qhbackup -s "${OTHER_BACKUP_SERVER}" > /dev/null
fi

# Main backup processing
./qhbackup  -d  > /dev/null
if [ $? -eq 200 ]
then
        echo "WARNING: Seems to have been an issue on the servers list retrieval from the DB. As a degraded option we launch qhbackup in mode all"
        ./qhbackup  -a  > /dev/null
fi

echo "Number of servers backuped today:$(./qhbNumberBackupedServer.sh -d ${startDate})"
echo "<BR>Number of servers backuped today:$(./qhbNumberBackupedServer.sh -d ${startDate})<BR>" >> ${htmlLogs}

grep "WARNING" ${qhbackupLogFile} | tee -a ${htmlLogs}

# Return from QuantInfra the servers having a difference between last_backup_launched and last_backup_succeed
./qhbShowBackupError.sh -H >> ${htmlLogs}
./qhbShowBackupError.sh

echo "</body></html>" >> ${htmlLogs}

echo "${urlLogs}"
### For debug purpose
df -h | grep data | grep -v repo

echo "Backup status => https://myserver/dj/tools/qhBackupMonito/"
