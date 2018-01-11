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
logall "Environment loaded."

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
        if [ "$TEMPLATE" = "" ]
        then
                logall " === Template is empty or not exist - skipping ($DESCRIPTION) ==="
                continue
        fi
        if [ "$TEMPLATE" = "Customized" ]
        then
                logall " === Template is customized - Must be updated manually - skipping ($DESCRIPTION) ==="
                continue
        fi
        logall " === Applying template \"snapshot.conf.${TEMPLATE}\" ($DESCRIPTION) ==="
        cp "${APP_PATH}/templates/snapshot.conf.${TEMPLATE}" "${SNAPSHOT_DST}/${REMOTE_HOST}/conf/snapshot.conf"
done
