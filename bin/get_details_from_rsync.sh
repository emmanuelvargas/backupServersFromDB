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

LOGS="/data/snapshot"
NUMBER="001"
SERVER=$1
shift

usage() {
echo "Usage: $0 SERVER [-n NNN]

       SERVER: Print rsync details from SERVER
       NNN: Print rsync details from snapshot.NNN (Default: 001)"
}

while getopts h?n: option
do
  case "${option}" in 
    h|\?) usage 
       exit 0;;
    n) NUMBER=${OPTARG};;
  esac
echo "plop"
done

if [ x"$SERVER" == x ]; then
  echo "Error: SERVER name missing"
  usage
  exit 1
fi

if [ -f ${LOGS}/${SERVER}/snapshot.${NUMBER}/log.gz ]; then
  zgrep -v -e sender -e uptodate  ${LOGS}/${SERVER}/snapshot.${NUMBER}/log.gz
else 
  echo "Error: File ${LOGS}/${SERVER}/snapshot.${NUMBER}/log.gz doesn't exist."
  usage
  exit 1
fi
