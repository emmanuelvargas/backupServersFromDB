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

VERBOSE=false
sqlOUTPUT=""

showOptions()
{
echo "Avaliable options:
        -V      Verbose mode
        -H      HTML output
        -h      Show this
        -d dateInSqlFormat    Used only with qhbNumberBackupedServer.sh. Allow to filter the servers with a last successfully backup date."
exit 0
}

while getopts "VHhd:" options;
do
        case $options in
        V)
                VERBOSE=true
                ;;
        H)
                sqlOUTPUT="-H"
                ;;
        h)
                showOptions
                ;;
        d)
                FILTERbyBACKUPdate="AND last_backup_succeed LIKE \"${OPTARG}\""
                ;;
        esac
done

