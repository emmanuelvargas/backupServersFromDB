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

SELECT="SELECT COUNT(id)"
FROM="FROM Server, Prod_Servers"
WHERE="WHERE Prod_Servers.server_id = Server.id AND Prod_Servers.server_region LIKE \"${REGION}\" AND Server.is_backuped = '1'"
${MYSQL} ${DBquantInfra} -Bn --skip-column-names -e "${SELECT} ${FROM} ${WHERE} ${FILTERbyBACKUPdate};"
