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

### Check if all args are present ###
if [ "$1" = "" ] || [ "$2" = "" ] || [ "$3" = "" ]
then
        echo "Mysql dump failed, please use $(basename "$0") DB_USER DB_PORT DB_NUMBER_OF_RETENTION_DAYS [DB_PASSWORD]"
        exit
fi

DB_USER="$1"
DB_PORT="$2"
DB_NUMBER_OF_RETENTION_DAYS="$3"
DB_PASSWORD="$4"

if [ "$DB_PASSWORD" != "" ]
then
        DB_PASSWORD="-p$DB_PASSWORD"
fi

DATE=`date +%Y%m%d`
DB_DIR="$(cd `dirname $0`; pwd)"
if [ ! -d "$DB_DIR" ]
then
        mkdir "$DB_DIR"
fi

### Binaries ###
GZIP="$(which gzip)"
MYSQL="$(which mysql)"
MYSQLDUMP="$(which mysqldump)"

### Remove dump older than DB_NUMBER_OF_RETENTION_DAYS ###
echo "Remove dump older than $DB_NUMBER_OF_RETENTION_DAYS days"
find $DB_DIR/ -name '*.sql.gz' -ctime +$DB_NUMBER_OF_RETENTION_DAYS -print
find $DB_DIR/ -name '*.sql.gz' -ctime +$DB_NUMBER_OF_RETENTION_DAYS -exec rm -f {} \;

### Exclude DB
if [ -f $DB_DIR/qhmysqldump.exclude ]
then
        DB_EXCLUDE="`cat $DB_DIR/qhmysqldump.exclude`"
fi

### Get all databases name and dump it ###
DBS="$($MYSQL -u $DB_USER $DB_PASSWORD -h 127.0.0.1 -P $DB_PORT -Bse 'show databases')"
for DB in $DBS
do
        DB_EXCLUDED='false'
        for DB_E in $DB_EXCLUDE
        do
                if [ "$DB" == "$DB_E" ]
                then
                        DB_EXCLUDED='true'
                fi
        done

        if [ "$DB" != "information_schema" ] && [ "$DB_EXCLUDED" != 'true' ]
        then
                if { mysqldump -u $DB_USER $DB_PASSWORD -h 127.0.0.1 -P $DB_PORT --add-lock --lock-all-tables --flush-logs --max_allowed_packet=1G ${DB} | gzip > $DB_DIR/$DB_PORT.$DB.$DATE.sql.gz ; } 2>&1
                then
                        echo "$DATE: $DB base backup OK"
                else
                        echo "$DATE: ERROR : $DB base backup failed"
                fi
        fi
done

