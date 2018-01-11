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

if [ -f "/tmp/qhbackup.pid" ]||[ -f "/tmp/qhbackup.*.pid" ]
then
        echo "<br><b>Backup ${HOSTNAME:0:3} is running:</b> " > /tmp/backup.${HOSTNAME:0:3}
        tail -n 1 /var/log/backup/all.`date +%Y%m%d`.log >> /tmp/backup.${HOSTNAME:0:3}
        scp -i /data/backup/.ssh/rsakeys /tmp/backup.${HOSTNAME:0:3} root@prodserver:/data/centreon_light/www/
else
        if [ -f /tmp/backup.${HOSTNAME:0:3} ]
        then
                echo > /tmp/backup.${HOSTNAME:0:3}
                scp -i /data/backup/.ssh/rsakeys /tmp/backup.${HOSTNAME:0:3} root@prodserver:/data/centreon_light/www/
                rm /tmp/backup.${HOSTNAME:0:3}
        fi
fi
