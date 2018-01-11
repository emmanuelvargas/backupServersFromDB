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
if [ ! -f "$CONF_PATH/qhbDB.conf" ]
then
        echo "qhbDB.conf does not exist: exiting"
        exit 1
fi
source $CONF_PATH/qhbDB.conf
logall "Environment loaded."

#### Retrieve all server from QuantInfra managed by QH with prod and archive at 0
SELECT="SELECT id, name, server_usage"
FROM="FROM Server"
WHERE="WHERE prod = '0' AND archive = '0' AND server_usage NOT LIKE \"NOBACKUP%\" AND (`cat ${CONF_PATH}/qhbackup.local_pop | awk -F":" '{if (NR==1) line=line"name LIKE \\""$1"%\\""; else line=line" OR name LIKE \\""$1"%\\"" ;} END {print line}'`) AND (`cat ${CONF_PATH}/qhbackup.managed_servers_id | awk -F" " '{if (NR==1) line=line"managed_by LIKE \\""$1"%\\""; else line=line" OR  managed_by LIKE \\""$1"%\\"" ;} END {print line}'`);"
${MYSQL} -u$QHBlogin -p$QHBpassword -D$QHBdb -h$QHBip -P$QHBport -Bn --skip-column-names -e "$SELECT $FROM $WHERE;" | while read ID_QUANTINFRA REMOTE_HOST SERVER_USAGE
do
        echo "${ID_QUANTINFRA}/${REMOTE_HOST}/${SERVER_USAGE}"
        read -e -p "Why not backuping the server? (If the server will be available soon, just press Enter):" USAGE < /dev/tty
        echo "USAGE:$USAGE"
        if [ "${USAGE}" = "" ]
        then
                continue
        else
                UPDATE="UPDATE Server SET server_usage = \"NOBACKUP ${USAGE}\" WHERE id = ${ID_QUANTINFRA} AND name LIKE \"$REMOTE_HOST\" LIMIT 1;"
                echo "$UPDATE"
                ${MYSQL} -u$QHBlogin -p$QHBpassword -D$QHBdb -h$QHBip -P$QHBport -Bn --skip-column-names -e "$UPDATE"
        fi
done
