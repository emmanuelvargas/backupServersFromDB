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
if [ ! -f "$APP_PATH/qhbFunctions.sh" ]
then
        echo "qhbFunctions.sh does not exist: exiting"
        exit 1
fi
source $APP_PATH/qhbFunctions.sh
if [ ! -f "$CONF_PATH/qhbDB.conf" ]
then
        echo "qhbDB.conf does not exist: exiting"
        exit 1
fi
source $CONF_PATH/qhbDB.conf
logall "Environment loaded."

logall "Checking servers to remove."
#### First, we check if any server has been disabled in QuantInfra
# Listing the local backuped servers
SERVERS="`find $SNAPSHOT_DST/* -maxdepth 0 -printf %f' '`"

for REMOTE_HOST in ${SERVERS}
do
        # Loading server configuration
        loadserverconf
        if ! $ACTIVE
        then
                logall " === Server backup is not active - skipping ($DESCRIPTION) ==="
                continue
        fi
        if [ "${ID_QUANTINFRA}" = "" ]
        then
                logall " === No QuantInfra ID - skipping ($DESCRIPTION) ==="
                continue
        fi

        # Request status in QuantInfra DB
        SELECT="SELECT is_backuped"
        #FROM="FROM Server"
        FROM="FROM prodTools_server"
        #WHERE="WHERE id = ${ID_QUANTINFRA} AND name LIKE \"$REMOTE_HOST\""
        WHERE="WHERE idQuantInfra = \"${ID_QUANTINFRA}\" AND name LIKE \"$REMOTE_HOST\""
        [[ $REGION != "" ]] && WHERE="$WHERE AND server_region LIKE \"$REGION\""

        echo "$SELECT $FROM $WHERE;"
        SERVER_STATUS="$(${MYSQL} ${DBprodCluster} -Bn --skip-column-names -e "$SELECT $FROM $WHERE;")"
        if [ $? -ne 0 ]
        then
                logall " === ERROR in DB request, we can not use the result ==="
                continue
        fi
        if [ "$SERVER_STATUS" = "" ]
        then
                logall " === Server is no more in QuantInfra - Deactivating backup ($DESCRIPTION) ==="
                sed -i 's/ACTIVE=true/ACTIVE=false/' "${SNAPSHOT_DST}/${REMOTE_HOST}/conf/server.conf"
                continue
        fi
        if [ "$SERVER_STATUS" = "0" ]
        then
                logall " === Server backuped is disabled in QuantInfra - Deactivating locally ($DESCRIPTION) ==="
                sed -i 's/ACTIVE=true/ACTIVE=false/' "${SNAPSHOT_DST}/${REMOTE_HOST}/conf/server.conf"
                continue
        fi
done

unset REMOTE_HOST
logall "Syncing local conf from DB"
#### Then we sync the local conf
#SELECT="SELECT id, name, backup_template, backup_frequency, prod, managed_by, server_usage"
SELECT="SELECT idQuantInfra, name, backup_template, backup_frequency, prod, managed_by, server_usage"
#FROM="FROM Server"
FROM="FROM prodTools_server"
WHERE="WHERE is_backuped = '1' AND server_region LIKE \"$REGION\""
${MYSQL} ${DBprodCluster} -Bn --skip-column-names -e "$SELECT $FROM $WHERE ORDER BY name;" | while read DB_ID_QUANTINFRA REMOTE_HOST DB_TEMPLATE DB_PERIOD DB_PROD_REACHABLE DB_MANAGED_BY DB_DESCRIPTION
do
        logall "Parsing $REMOTE_HOST"
        # Check if the server directory exist
        if [ ! -d "${SNAPSHOT_DST}/${REMOTE_HOST}" ]
        then
                if [ "$DB_PROD_REACHABLE" != "1" ]
                then
                        logerror " === ERROR: Backup activated in QuantInfra but server not reachable ($DB_DESCRIPTION / $DB_MANAGED_BY) ==="
                        continue
                fi
                logall " === Folder ${SNAPSHOT_DST}/${REMOTE_HOST} does not exist, we have to create it. ==="
                checkRemoteAccess
                if [ $? -eq 0 ]
                then
                        mkdir -p "${SNAPSHOT_DST}/${REMOTE_HOST}/conf"
                else
                        logerror " === ERROR: Unable to authenticate on the server or to copy the qhbackup key ($DB_DESCRIPTION / $DB_MANAGED_BY) ==="
                        continue
                fi
        fi

        # Check if the conf file exist
        if [ ! -f "${SNAPSHOT_DST}/${REMOTE_HOST}/conf/server.conf" ]
        then
                logall " === ${SNAPSHOT_DST}/${REMOTE_HOST}/conf/server.conf does not exist, we have to create it. ==="
                touch "${SNAPSHOT_DST}/${REMOTE_HOST}/conf/server.conf"
        fi

        loadserverconf
        logall " === Updating configuration file ==="
        if [ "$DB_PROD_REACHABLE" != "1" ]
        then
                logerror " === ERROR: Backup activated in QuantInfra but server not reachable ($DB_DESCRIPTION / $DB_MANAGED_BY) ==="
                grep -q "ACTIVE" "${SNAPSHOT_DST}/${REMOTE_HOST}/conf/server.conf"
                if [ $? -eq 0 ]
                then
                        sed -i 's/ACTIVE=.*$/ACTIVE=false/' "${SNAPSHOT_DST}/${REMOTE_HOST}/conf/server.conf"
                else
                        echo "ACTIVE=false" >> "${SNAPSHOT_DST}/${REMOTE_HOST}/conf/server.conf"
                fi
                continue
        fi
        # For ACTIVE, DESCRIPTION, PERIOD, TEMPLATE check if value is defined, then update it or add it
        grep -q "ACTIVE" "${SNAPSHOT_DST}/${REMOTE_HOST}/conf/server.conf"
        if [ $? -eq 0 ]
        then
                # If server has been previously deactivate, we check if we are still able to connect
                if ! $ACTIVE
                then
                        checkRemoteAccess
                        if [ $? -ne 0 ]
                        then
                                logall " === ERROR: Server was deactivate and is still not available ($DB_DESCRIPTION / $DB_MANAGED_BY) ==="
                                continue
                        fi
                fi
                sed -i 's/ACTIVE=.*$/ACTIVE=true/' "${SNAPSHOT_DST}/${REMOTE_HOST}/conf/server.conf"
        else
                echo "ACTIVE=true" >> "${SNAPSHOT_DST}/${REMOTE_HOST}/conf/server.conf"
        fi

        grep -q "ID_QUANTINFRA" "${SNAPSHOT_DST}/${REMOTE_HOST}/conf/server.conf"
        if [ $? -eq 0 ]
        then
                sed -i "s/ID_QUANTINFRA=.*$/ID_QUANTINFRA=${DB_ID_QUANTINFRA}/" "${SNAPSHOT_DST}/${REMOTE_HOST}/conf/server.conf"
        else
                echo "ID_QUANTINFRA=${DB_ID_QUANTINFRA}" >> "${SNAPSHOT_DST}/${REMOTE_HOST}/conf/server.conf"
        fi

        DB_DESCRIPTION="${DB_DESCRIPTION//\//_}"
        grep -q "DESCRIPTION" "${SNAPSHOT_DST}/${REMOTE_HOST}/conf/server.conf"
        if [ $? -eq 0 ]
        then
                sed -i "s/DESCRIPTION=.*$/DESCRIPTION=\"${DB_DESCRIPTION}\"/" "${SNAPSHOT_DST}/${REMOTE_HOST}/conf/server.conf"
        else
                echo "DESCRIPTION=\"${DB_DESCRIPTION}\"" >> "${SNAPSHOT_DST}/${REMOTE_HOST}/conf/server.conf"
        fi

        grep -q "PERIOD" "${SNAPSHOT_DST}/${REMOTE_HOST}/conf/server.conf"
        if [ $? -eq 0 ]
        then
                sed -i "s/PERIOD=.*$/PERIOD=${DB_PERIOD:0:1}/" "${SNAPSHOT_DST}/${REMOTE_HOST}/conf/server.conf"
        else
                echo "PERIOD=${DB_PERIOD:0:1}" >> "${SNAPSHOT_DST}/${REMOTE_HOST}/conf/server.conf"
        fi

        grep -q "TEMPLATE" "${SNAPSHOT_DST}/${REMOTE_HOST}/conf/server.conf"
        if [ $? -eq 0 ]
        then
                sed -i "s/TEMPLATE=.*$/TEMPLATE=${DB_TEMPLATE}/" "${SNAPSHOT_DST}/${REMOTE_HOST}/conf/server.conf"
        else
                echo "TEMPLATE=${DB_TEMPLATE}" >> "${SNAPSHOT_DST}/${REMOTE_HOST}/conf/server.conf"
        fi
        logall " === Apply snapshot template ==="
        if [ "${DB_TEMPLATE}" = "Customized" ]
        then
                logall " === Customized template, we don't update this one ==="
        else
                cp "${APP_PATH}/templates/snapshot.conf.${DB_TEMPLATE}" "${SNAPSHOT_DST}/${REMOTE_HOST}/conf/snapshot.conf"
        fi

        [[ "${REMOTE_HOST}" = "${BACKUP_SERVER}" ]] && continue
        logall " === Check Pre/Post Scripts ==="
        checkPrePostScripts
        PREPOST=$?
        GREPPRE=$(grep -c "PRE_BACKUP" "${SNAPSHOT_DST}/${REMOTE_HOST}/conf/server.conf")
        if [ ${PREPOST} -eq 1 ] || [ ${PREPOST} -eq 3 ]
        then
                logall " === Pre backup script(s) found on remote server, activating option PRE_BACKUP ==="
                if [ ${GREPPRE} -ne 0 ]
                then
                        sed -i "s/PRE_BACKUP=.*$/PRE_BACKUP=true/" "${SNAPSHOT_DST}/${REMOTE_HOST}/conf/server.conf"
                else
                        echo "PRE_BACKUP=true" >> "${SNAPSHOT_DST}/${REMOTE_HOST}/conf/server.conf"
                fi
        else
                if [ ${GREPPRE} -ne 0 ]
                then
                        logall " === No more pre backup script(s) found on remote server, disabling option PRE_BACKUP ==="
                        sed -i "s/PRE_BACKUP=.*$/PRE_BACKUP=false/" "${SNAPSHOT_DST}/${REMOTE_HOST}/conf/server.conf"
                fi
        fi
        GREPPOST=$(grep -c "POST_BACKUP" "${SNAPSHOT_DST}/${REMOTE_HOST}/conf/server.conf")
        if [ ${PREPOST} -eq 2 ] || [ ${PREPOST} -eq 3 ]
        then
                logall " === Post backup script(s) found on remote server, activating option POST_BACKUP ==="
                if [ ${GREPPOST} -ne 0 ]
                then
                        sed -i "s/POST_BACKUP=.*$/POST_BACKUP=true/" "${SNAPSHOT_DST}/${REMOTE_HOST}/conf/server.conf"
                else
                        echo "POST_BACKUP=true" >> "${SNAPSHOT_DST}/${REMOTE_HOST}/conf/server.conf"
                fi
        else
                if [ ${GREPPOST} -ne 0 ]
                then
                        logall " === No more post backup script(s) found on remote server, disabling option POST_BACKUP ==="
                        sed -i "s/POST_BACKUP=.*$/POST_BACKUP=false/" "${SNAPSHOT_DST}/${REMOTE_HOST}/conf/server.conf"
                fi
        fi
done
