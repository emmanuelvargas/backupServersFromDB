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

MAX_SERVER_TO_ACTIVATE="100"

FROM="FROM prodTools_server"
WHERE="WHERE server_region LIKE \"$REGION\" AND is_backuped = '0' AND prod = '1' AND (server_usage IS NULL OR server_usage NOT LIKE \"NOBACKUP%\")"

if [ $VERBOSE ]||[ "$sqlOUTPUT" = "-H" ]
then
        SELECT="SELECT id"
        if [ -n "$(${MYSQL} ${DBprodCluster} -Bn --skip-column-names -e "$SELECT $FROM $WHERE LIMIT 1;")" ];
        then
                echo "The following servers will be add in the backup process:"
                #SELECT="SELECT id, name, server_usage, managed_by, operating_system"
                SELECT="SELECT id, idQuantInfra, name, server_usage, managed_by, operating_system"
                ${MYSQL} ${DBprodCluster} -P$QHBport $sqlOUTPUT -e "$SELECT $FROM $WHERE LIMIT ${MAX_SERVER_TO_ACTIVATE};"
        fi
fi

SELECT="SELECT id, idInfra, name, managed_by, used_by, server_usage"
${MYSQL} ${DBprodCluster} -Bn --skip-column-names -e "$SELECT $FROM $WHERE LIMIT ${MAX_SERVER_TO_ACTIVATE};" | while read ID_PRODTOOLS ID_QUANTINFRA REMOTE_HOST MANAGED_BY USED_BY USAGE
do
        if [[ "$USAGE" == "NULL" ]]
        then
                USAGE=""
        fi
        if [[ "$USAGE" =~ "NULL" ]]
        then
                USAGE=""
        fi
        USAGE=${USAGE#autoQH }
        USAGE=${USAGE#autoQH }
        USAGE=${USAGE#autoQH}
        USAGE=${USAGE#NULL }
        USAGE=${USAGE#NULL}
        USAGE=${USAGE#autoQHserver }
        USAGE=${USAGE#autoQHserver}
        FREQUENCY="weekly"
        PRIORITY="3"
        if [[  "${MANAGED_BY}" = "Prod" ]]
        then
                FREQUENCY="daily"
                PRIORITY="5"
                if [[ "${USED_BY}" = "Prod_prod" ]]
                then
                        PRIORITY="7"
                fi
        fi
        if [ "${USAGE}" == "" ]
        then
                USAGE="${USED_BY}"
        fi

        UPDATE="UPDATE Server SET is_backuped = \"1\", server_usage=\"autoQH $USAGE\", backup_frequency=\"$FREQUENCY\", backup_priority=\"$PRIORITY\", backup_template=\"Generic\" WHERE id = ${ID_QUANTINFRA} AND name LIKE \"$REMOTE_HOST\" LIMIT 1;"
        ${MYSQL} ${DBquantInfra} -Bn --skip-column-names -e "$UPDATE"

done

