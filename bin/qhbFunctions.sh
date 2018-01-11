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

loadserverconf()
{
        LOG_FILE="${LOG_PATH}/${APP_NAME}/${REMOTE_HOST}.log"
        # make sure we have a correct snapshot folder
        if [ ! -d "${SNAPSHOT_DST}/${REMOTE_HOST}" ]
        then
                logall "Sorry, folder ${SNAPSHOT_DST}/${REMOTE_HOST} is missing. Skipping this server..."
                ACTIVE=false
                return
        fi

        source ${CONF_PATH}/qhbackup.conf
        log "General configuration loaded."

        if [ -f "${SNAPSHOT_DST}/${REMOTE_HOST}/conf/server.conf" ]
        then
                source ${SNAPSHOT_DST}/${REMOTE_HOST}/conf/server.conf
                log "Specific server configuration loaded."
        else
                logall "Sorry, configuration file ${SNAPSHOT_DST}/${REMOTE_HOST}/conf/server.conf is missing. Skipping this server..."
                ACTIVE=false
                return
        fi
}

checkRemoteAccess()
{
        if [ "${HOSTNAME}" == "${REMOTE_HOST}" ]
        then
                # The backup server access is not to be tested
                return 0
        fi
        # Try to connect to the server with the qhbackup key
        ssh -q -n -o StrictHostKeyChecking=no -o ConnectTimeout=10 -p ${HOST_PORT} -i ${SSH_KEY} -l root ${REMOTE_HOST} 'sleep 1'
        if [ $? -eq 0 ]
        then
                return 0
        fi
        # Try to push the qhbackup key on the server
        ssh -q -n -o StrictHostKeyChecking=no -o ConnectTimeout=10 -p ${HOST_PORT} -i ${APP_PATH}/../.ssh/id_rsa.prod  -l root ${REMOTE_HOST} 'echo "ssh-rsa 00000000000000000000000000000000000000000000000000000000000000 backup" >> /root/.ssh/authorized_keys'
        if [ $? -ne 0 ]
        then
                return 255
        fi
        # Re-try to connect to the server with the qhbackup key
        ssh -q -n -o StrictHostKeyChecking=no -o ConnectTimeout=10 -p ${HOST_PORT} -i ${SSH_KEY} -l root ${REMOTE_HOST} 'sleep 1'
        if [ $? -eq 0 ]
        then
                return 0
        fi
        return 255
}

checkPrePostScripts()
{
        # Try to connect to the server with the qhbackup key
        [[ -z ${BACKUP_SCRIPTS_LOCATION} ]]&&return 254
        CMD="ls ${BACKUP_SCRIPTS_LOCATION} 2>/dev/null"
        RES="$(ssh -q -n -o StrictHostKeyChecking=no -o ConnectTimeout=10 -p ${HOST_PORT} -i ${SSH_KEY} -l root ${REMOTE_HOST} "${CMD}") 2>/dev/null"
        if [ $? -ne 0 ]
        then
                return 255
        fi
        # If pre only => res = 1
        # If post only => res = 2
        # If pre and post => res = 3
        res=0
        if [ $(echo ${RES}|grep -c '.pre') -ne 0 ]
        then
                let res=res+1
        fi
        if [ $(echo ${RES}|grep -c '.post') -ne 0 ]
        then
                let res=res+2
        fi
        return ${res}
}

log()
{
    TIME_STAMP="`date +%Y-%m-%d_%H:%M:%S`"
    if ${VERBOSE}
    then
        echo ${TIME_STAMP}:${REMOTE_HOST}: - $* | tee -a "${LOG_FILE}"
    else
        echo ${TIME_STAMP}:${REMOTE_HOST}: - $* >> ${LOG_FILE}
    fi
}

logall()
{
    TIME_STAMP="`date +%Y-%m-%d_%H:%M:%S`"
    [[ "${MYPID}" != "" ]] && LOGPID="${MYPID}|" || LOGPID=""
    if [ "{${REMOTE_HOST}}" != "" ]
    then
        #     echo $TIME_STAMP:$REMOTE_HOST: - $* | tee -a "$LOG_FILE"
        [[ -n ${LOG_FILE} ]]&&log $*
        echo ${LOGPID}${TIME_STAMP}:${REMOTE_HOST}: - $* >> ${LOGALL_FILE}
    else
        if ${VERBOSE}
        then
            echo ${LOGPID}${TIME_STAMP}:${REMOTE_HOST}: - $* | tee -a "${LOGALL_FILE}"
        else
            echo ${LOGPID}${TIME_STAMP}:${REMOTE_HOST}: - $* >> ${LOGALL_FILE}
        fi
    fi
}

logerror()
{
    TIME_STAMP="`date +%Y-%m-%d_%H:%M:%S`"
    echo ${TIME_STAMP}:${REMOTE_HOST}: - $*
    logall $*
}
