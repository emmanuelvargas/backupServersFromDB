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
if [ ! -f "$APP_PATH/qhbFunctions.sh" ]
then
        echo "qhbFunctions.sh does not exist: exiting"
        exit 1
fi
source $APP_PATH/qhbFunctions.sh
logall "Environment loaded."

# Update prod field in QantInfra DB for Server in the same Region
SELECT="SELECT Server.id, Server.name"
FROM="FROM Server, Prod_Servers"
WHERE="WHERE Prod_Servers.server_id = Server.id AND Prod_Servers.server_region LIKE \"$REGION\" AND Server.name NOT LIKE \"reserved%\" AND (Server.prod = '0' OR Server.prod IS NULL) AND (Server.archive = '0' OR Server.archive IS NULL) AND Prod_Servers.server_managed_by LIKE \"QuantHouse%\" AND Prod_Servers.server_managed_by NOT LIKE \"QuantHouse_Network\" AND Prod_Servers.server_operating_system LIKE \"Debian%\";"
${MYSQL} ${DBquantInfra} -Bn --skip-column-names -e "$SELECT $FROM $WHERE" | while read ID_QUANTINFRA REMOTE_HOST
do
        if $VERBOSE
        then
                echo "${ID_QUANTINFRA}/${REMOTE_HOST}"
        fi
        ssh -n -o ConnectTimeout=10 -p 22 -i ${APP_PATH}/../.ssh/rsakeys -l root ${REMOTE_HOST} 'sleep 1' > /dev/null 2>&1
        if [ $? -eq 0 ] || [ "${REMOTE_HOST}" = "${BACKUP_SERVER}" ]
        then
                UPDATE="UPDATE Server SET prod = \"1\" WHERE id = ${ID_QUANTINFRA} AND name LIKE \"$REMOTE_HOST\" LIMIT 1;"
                echo "$UPDATE"
                ${MYSQL} ${DBquantInfra} -Bn --skip-column-names -e "$UPDATE"
        fi
done

# Update reachable_from_. in prodCluster DB for all Servers
if [[ -z "${prodClusterDBhost}" ]]
then
        echo "prodClusterDB not configured."
        exit 1
fi
SELECT="SELECT id, name, reachable_from_${HOSTNAME:0:3}"
FROM="FROM Server"
WHERE="WHERE name NOT LIKE \"reserved%\" AND archive = '0'"
if [[ $(date +%u) -ne 6 ]]
then
        WHERE="${WHERE} AND server_region LIKE \"$REGION\" AND reachable_from_${HOSTNAME:0:3} = '0' AND managed_by LIKE \"QuantHouse%\" AND operating_system LIKE \"Debian%\""
fi
${MYSQL} -u$prodClusterDBlogin -p$prodClusterDBpassword -D$prodClusterDBname -h$prodClusterDBhost -Bn --skip-column-names -e "$SELECT $FROM $WHERE;" | while read ID_QUANTINFRA REMOTE_HOST REACHABLE
do
        if $VERBOSE
        then
                echo "${ID_QUANTINFRA}/${REMOTE_HOST}"
        fi
        if [[ "${REMOTE_HOST}" = "${BACKUP_SERVER}" ]]&&[[ "${REACHABLE}" != '1' ]]
        then
                UPDATE="UPDATE Server SET reachable_from_${HOSTNAME:0:3} = \"1\" WHERE id = ${ID_QUANTINFRA} AND name LIKE \"$REMOTE_HOST\" LIMIT 1;"
                echo "$UPDATE"
                ${MYSQL} -u$prodClusterDBlogin -p$prodClusterDBpassword -D$prodClusterDBname -h$prodClusterDBhost -Bn --skip-column-names -e "$UPDATE;"
                continue
        fi
        ssh -n -o ConnectTimeout=10 -p 22 -i ${APP_PATH}/../.ssh/rsakeys -l root ${REMOTE_HOST} 'sleep 1' > /dev/null 2>&1
        if [[ $? -eq 0 ]]
        then
                UPDATE_STATUS='1'
        else
                UPDATE_STATUS='0'
        fi
        if [[ "${REACHABLE}" != "${UPDATE_STATUS}" ]]
        then
                UPDATE="UPDATE Server SET reachable_from_${HOSTNAME:0:3} = \"${UPDATE_STATUS}\" WHERE id = ${ID_QUANTINFRA} AND name LIKE \"$REMOTE_HOST\" LIMIT 1;"
                echo "$UPDATE"
                ${MYSQL} -u$prodClusterDBlogin -p$prodClusterDBpassword -D$prodClusterDBname -h$prodClusterDBhost -Bn --skip-column-names -e "$UPDATE;"
        fi
done

