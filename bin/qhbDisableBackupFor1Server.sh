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

if [[ "$1" == "" ]]
then
        echo "$0 server_to_deactivate"
        exit 1
fi
SERVER_NAME="$1"
thistty=$(tty)

SELECT="SELECT Server.id, Server.name, Prod_Servers.server_managed_by, Prod_Servers.server_used_by, Server.server_usage"
FROM="FROM Server, Prod_Servers"
WHERE="WHERE Server.id = Prod_Servers.server_id AND Server.prod = '1' AND Server.name LIKE \"${SERVER_NAME}\""
${MYSQL} ${DBquantInfra} -Bn --skip-column-names -e "$SELECT $FROM $WHERE LIMIT 1;" | while read ID_QUANTINFRA REMOTE_HOST MANAGED_BY USED_BY USAGE
do
        echo "${ID_QUANTINFRA} | ${REMOTE_HOST} | ${MANAGED_BY} | ${USED_BY} | ${USAGE}"
        read -n 1 -p "This server will be deactivate, could you confirm [y/N]?" ANSWER < $thistty
        echo ''
        if [[ ${ANSWER} != 'y' ]]
        then
                echo 'Exiting...'
                exit 1
        fi
        echo 'Updating QuantInfra DB'
        UPDATE="UPDATE Server SET is_backuped = \"0\", prod = \"0\" WHERE id = ${ID_QUANTINFRA} AND name LIKE \"$REMOTE_HOST\" LIMIT 1;"
        ${MYSQL} ${DBquantInfra} -Bn --skip-column-names -e "$UPDATE"

done

