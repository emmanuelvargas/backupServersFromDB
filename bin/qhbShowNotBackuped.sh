#!/bin/bash

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
logall "Environment loaded."

SELECT="SELECT Server.id"
FROM="FROM Server, Prod_Servers"
WHERE="WHERE Server.id = Prod_Servers.server_id AND (Server.is_backuped = '0' OR Server.is_backuped IS NULL) AND Server.prod = '1' AND Prod_Servers.server_region LIKE \"$REGION\""
if [ -n "$(${MYSQL} ${DBquantInfra} -Bn --skip-column-names -e "$SELECT $FROM $WHERE LIMIT 1;")" ]
then
        echo "===SERVERS NOT BACKUPED==="
        SELECT="SELECT Server.id, Server.name, Server.server_usage, Prod_Servers.server_managed_by, Prod_Servers.server_operating_system"
        ${MYSQL} ${DBquantInfra} $sqlOUTPUT -e "$SELECT $FROM $WHERE;"
fi
