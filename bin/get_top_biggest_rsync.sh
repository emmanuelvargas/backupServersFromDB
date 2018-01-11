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

LOGS="/var/log/backup"
LIMIT="10"

while getopts h?l:d: option
do
  case "${option}" in 
    h|\?) echo "Usage: $0 [-l LIMIT] [-d YYYYMMDD]

       LIMIT: Print the first lines (Default: 10)
       YYYYMMDD: Check in specific log file (Default: Last file)"
       exit 0;;
    l) LIMIT=${OPTARG};;
    d) DATE=${OPTARG};;
  esac
done

if [ x"$DATE" == x ]; then 
  LOG=`ls -Art $LOGS/all* | tail -n 1`
  DATE=`echo $LOG | sed -ne 's/.*all.\([0-9]\{8\}\).log/\1/p'`
  echo -e "\\033[1;32m Date: ${DATE}\\033[0;39m"
else 
  LOG="${LOGS}/all.${DATE}.log"
  echo -e "\\033[1;32m Date: ${DATE}\\033[0;39m"
fi



grep "[0-9]\." $LOG | sort -nr -k 14 | head -n $LIMIT
