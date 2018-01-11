#!/bin/bash

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

# Loading General environment
APP_PATH=$(cd `dirname $0`; pwd)
source $APP_PATH/qhbOptions.sh
CONF_PATH="$APP_PATH/conf"
if [ ! -f "$CONF_PATH/backup.env" ]
then
        echo "backup.env does not exist: no environment file, exiting"
        exit 1
fi
source $CONF_PATH/backup.env
source $APP_PATH/qhbFunctions.sh
if [ ! -f "$CONF_PATH/qhbDB.conf" ]
then
        echo "qhbDB.conf does not exist: exiting"
        exit 1
fi
source $CONF_PATH/qhbDB.conf

SELECT="SELECT COUNT(Server.id)"
FROM="FROM Server, Prod_Servers"
WHERE="WHERE Server.id = Prod_Servers.server_id AND Server.is_backuped = '1' AND Prod_Servers.server_region LIKE \"$REGION\" AND Server.last_backup_launched <> Server.last_backup_succeed"
OUTPUT=$(${MYSQL} ${DBquantInfra} --skip-column-names -e "$SELECT $FROM $WHERE;")

if [[ ${OUTPUT} -ne 0 ]]&&[[ ${sqlOUTPUT} != '-H' ]]
then
        echo "Failed backup for the server(s):"
fi
SELECT="SELECT Server.id, Server.name, Server.server_usage, Prod_Servers.server_managed_by, Prod_Servers.server_operating_system, Server.backup_frequency, Server.last_backup_launched, Server.last_backup_succeed, Server.archive"
${MYSQL} ${DBquantInfra} $sqlOUTPUT -e "$SELECT $FROM $WHERE;"
if [[ ${OUTPUT} -ne 0 ]]&&[[ ${sqlOUTPUT} != '-H' ]]
then
        echo "Full list of failed backup: https://prod-qh.mhf.mhc/dj-dev/tools/qhBackupMonito/failed/"
        echo "TO DO with the failed backup: https://quantwiki.mhf.mhc/index.php?title=QHBackup#Clean_the_failed_backup"
fi
exit ${OUTPUT}
