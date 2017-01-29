#!/bin/bash
set -eo pipefail
#
# MongoDB Backup Script
# VER. 0.20
# More Info: http://github.com/micahwedemeyer/automongobackup

# Note, this is a lobotomized port of AutoMySQLBackup
# (http://sourceforge.net/projects/automysqlbackup/) for use with
# MongoDB.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#=====================================================================
#=====================================================================
# Set the following variables to your system needs
# (Detailed instructions below variables)
#=====================================================================

# Database name to specify a specific database only e.g. myawesomeapp
# Unnecessary if backup all databases
# DBNAME=""

# Collections name list to include e.g. system.profile users
# DBNAME is required
# Unecessary if backup all collections
# COLLECTIONS=""

# Collections to exclude e.g. system.profile users
# DBNAME is required
# Unecessary if backup all collections
# EXCLUDE_COLLECTIONS=""

# Username to access the mongo server e.g. dbuser
# Unnecessary if authentication is off
# DBUSERNAME=""

# Password to access the mongo server e.g. password
# Unnecessary if authentication is off
# DBPASSWORD=""

# Database for authentication to the mongo server e.g. admin
# Unnecessary if authentication is off
# DBAUTHDB=""

# Host name (or IP address) of mongo server e.g localhost
DBHOST="127.0.0.1"

# Port that mongo is listening on
DBPORT="27017"

# Backup directory location e.g /backups
BACKUPDIR="/backup/mongodb"

# ============================================================================
# === SCHEDULING AND RETENTION OPTIONS ( Read the doc's below for details )===
#=============================================================================

# Do you want to do hourly backups? How long do you want to keep them?
DOHOURLY="no"
HOURLYRETENTION=24

# Do you want to do daily backups? How long do you want to keep them?
DODAILY="yes"
DAILYRETENTION=7

# Which day do you want weekly backups? (1 to 7 where 1 is Monday)
DOWEEKLY="yes"
WEEKLYDAY=6
WEEKLYRETENTION=4

# Do you want monthly backups? How long do you want to keep them?
DOMONTHLY="yes"
MONTHLYRETENTION=4

# ============================================================
# === ADVANCED OPTIONS ( Read the doc's below for details )===
#=============================================================

# Choose if the uncompressed folder should be deleted after compression has completed
CLEANUP="yes"

# Additionally keep a copy of the most recent backup in a seperate directory.
LATEST="yes"

# Make Hardlink not a copy
LATESTLINK="yes"

# Use oplog for point-in-time snapshotting.
OPLOG="no"

# Choose other Server if is Replica-Set Master
REPLICAONSLAVE="no"

# Allow DBUSERNAME without DBAUTHDB
REQUIREDBAUTHDB="no"

# Maximum files of a single backup used by split - leave empty if no split required
# MAXFILESIZE=""

# Command to run before backups (uncomment to use)
# PREBACKUP=""

# Command run after backups (uncomment to use)
# POSTBACKUP=""

#=====================================================================
# Options documentation
#=====================================================================
# Set DBUSERNAME and DBPASSWORD of a user that has at least SELECT permission
# to ALL databases.
#
# Set the DBHOST option to the server you wish to backup, leave the
# default to backup "this server".(to backup multiple servers make
# copies of this file and set the options for that server)
#
# You can change the backup storage location from /backups to anything
# you like by using the BACKUPDIR setting..
#
# Finally copy automongobackup.sh to anywhere on your server and make sure
# to set executable permission. You can also copy the script to
# /etc/cron.daily to have it execute automatically every night or simply
# place a symlink in /etc/cron.daily to the file if you wish to keep it
# somwhere else.
#
# NOTE: On Debian copy the file with no extention for it to be run
# by cron e.g just name the file "automongobackup"
#
# Thats it..
#
#
# === Advanced options ===
#
# To set the day of the week that you would like the weekly backup to happen
# set the WEEKLYDAY setting, this can be a value from 1 to 7 where 1 is Monday,
# The default is 6 which means that weekly backups are done on a Saturday.
#
# Use PREBACKUP and POSTBACKUP to specify Pre and Post backup commands
# or scripts to perform tasks either before or after the backup process.
#
#
#=====================================================================
# Backup Rotation..
#=====================================================================
#
# Hourly backups are executed if DOHOURLY is set to "yes".
# The number of hours backup copies to keep for each day (i.e. 'Monday', 'Tuesday', etc.) is set with DHOURLYRETENTION.
# DHOURLYRETENTION=0 rotates hourly backups every day (i.e. only the most recent hourly copy is kept). -1 disables rotation.
#
# Daily backups are executed if DODAILY is set to "yes".
# The number of daily backup copies to keep for each day (i.e. 'Monday', 'Tuesday', etc.) is set with DAILYRETENTION.
# DAILYRETENTION=0 rotates daily backups every week (i.e. only the most recent daily copy is kept). -1 disables rotation.
#
# Weekly backups are executed if DOWEEKLY is set to "yes".
# WEEKLYDAY [1-7] sets which day a weekly backup occurs when cron.daily scripts are run.
# Rotate weekly copies after the number of weeks set by WEEKLYRETENTION.
# WEEKLYRETENTION=0 rotates weekly backups every week. -1 disables rotation.
#
# Monthly backups are executed if DOMONTHLY is set to "yes".
# Monthy backups occur on the first day of each month when cron.daily scripts are run.
# Rotate monthly backups after the number of months set by MONTHLYRETENTION.
# MONTHLYRETENTION=0 rotates monthly backups upon each execution. -1 disables rotation.
#
#=====================================================================
# Please Note!!
#=====================================================================
#
# I take no resposibility for any data loss or corruption when using
# this script.
#
# This script will not help in the event of a hard drive crash. You
# should copy your backups offline or to another PC for best protection.
#
# Happy backing up!
#
#=====================================================================
# Restoring
#=====================================================================
# ???
#
#=====================================================================
# Change Log
#=====================================================================
# VER 0.11 - (2016-05-04) (author: Claudio Prato)
#        - Fixed bugs in select_secondary_member() with authdb enabled
#        - Fixed bugs in Compression function by removing the * symbol
#        - Added incremental backup feature
#        - Added option to select the collections to backup
#
# VER 0.10 - (2015-06-22) (author: Markus Graf)
#        - Added option to backup only one specific database
#
# VER 0.9 - (2011-10-28) (author: Joshua Keroes)
#       - Fixed bugs and improved logic in select_secondary_member()
#       - Fixed minor grammar issues and formatting in docs
#
# VER 0.8 - (2011-10-02) (author: Krzysztof Wilczynski)
#       - Added better support for selecting Secondary member in the
#         Replica Sets that can be used to take backups without bothering
#         busy Primary member too much.
#
# VER 0.7 - (2011-09-23) (author: Krzysztof Wilczynski)
#       - Added support for --journal dring taking backup
#         to enable journaling.
#
# VER 0.6 - (2011-09-15) (author: Krzysztof Wilczynski)
#       - Added support for --oplog during taking backup for
#         point-in-time snapshotting.
#       - Added filter for "mongodump" writing "connected to:"
#         on the standard error, which is not desirable.
#
# VER 0.5 - (2011-02-04) (author: Jan Doberstein)
#       - Added replicaset support (don't Backup on Master)
#       - Added Hard Support for 'latest' Copy
#
# VER 0.4 - (2010-10-26)
#       - Cleaned up warning message to make it clear that it can
#         usually be safely ignored
#
# VER 0.3 - (2010-06-11)
#       - Added the DBPORT parameter
#       - Changed USERNAME and PASSWORD to DBUSERNAME and DBPASSWORD
#       - Fixed some bugs with compression
#
# VER 0.2 - (2010-05-27) (author: Gregory Barchard)
#       - Added back the compression option for automatically creating
#         tgz or bz2 archives
#       - Added a cleanup option to optionally remove the database dump
#         after creating the archives
#       - Removed unnecessary path additions
#
# VER 0.1 - (2010-05-11)
#       - Initial Release
#
# VER 0.2 - (2015-09-10)
#       - Added configurable backup rentention options, even for
#         monthly backups.
#
#=====================================================================
#=====================================================================
#=====================================================================
#
# Should not need to be modified from here down!!
#
#=====================================================================
#=====================================================================
#=====================================================================

shellout () {
    [ "${1}" ] || exit 0
    echo "${1}"
    exit 1
}

# External config - override default values set above
for x in default sysconfig; do
  # shellcheck source=/dev/null
  [ -f "/etc/${x}/automongobackup" ] && source /etc/${x}/automongobackup
done

# Include extra config file if specified on commandline, e.g. for backuping several remote dbs from central server
# shellcheck source=/dev/null
[ "${1}" ] && [ -f "${1}" ] && source ${1}

#=====================================================================

PATH=/usr/local/bin:/usr/bin:/bin
DATE=$(date +%Y-%m-%d_%Hh%Mm)                     # Datestamp e.g 2002-09-21
HOD=$(date +%s)                                   # Current timestamp for PITR backup
DOW=$(date +%A)                                   # Day of the week e.g. Monday
DNOW=$(date +%u)                                  # Day number of the week 1 to 7 where 1 represents Monday
DOM=$(date +%d)                                   # Date of the Month e.g. 27
M=$(date +%B)                                     # Month e.g January
W=$(date +%V)                                     # Week Number e.g 37
OPT=""                                            # OPT string for use with mongodump
OPTSEC=""                                         # OPT string for use with mongodump in select_secondary_member function
QUERY=""                                          # QUERY string for use with mongodump
HOURLYQUERY=""                                    # HOURLYQUERY string for use with mongodump

# Do we need to use a username/password?
if [ "${DBUSERNAME}" ] ; then
    OPT="${OPT} --username=${DBUSERNAME} --password=${DBPASSWORD}"
    if [ "${REQUIREDBAUTHDB}" = "yes" ] ; then
        OPT="${OPT} --authenticationDatabase=${DBAUTHDB}"
    fi
fi

# Do we need to use a username/password for ReplicaSet Secondary Members Selection?
if [ "${DBUSERNAME}" ] ; then
    OPTSEC="${OPTSEC} --username=${DBUSERNAME} --password=${DBPASSWORD}"
    if [ "${REQUIREDBAUTHDB}" = "yes" ] ; then
        OPTSEC="${OPTSEC} --authenticationDatabase=${DBAUTHDB}"
    fi
fi

# Do we use oplog for point-in-time snapshotting?
[ "${OPLOG}" = "yes" ] && [ "${DBNAME}" != "yes" ] && OPT="${OPT} --oplog"

# Do we need to backup only a specific database?
[ "${DBNAME}" ] && OPT="${OPT} -d ${DBNAME}"

# Do we need to backup only a specific collections?
if [ "${COLLECTIONS}" ] ; then
  for x in ${COLLECTIONS}; do
    OPT="${OPT} --collection ${x}"
  done
fi

# Do we need to exclude collections?
if [ "${EXCLUDE_COLLECTIONS}" ] ; then
  for x in ${EXCLUDE_COLLECTIONS}; do
    OPT="${OPT} --excludeCollection ${x}"
  done
fi

# Do we use a filter for hourly point-in-time snapshotting?
if [ "${DOHOURLY}" == "yes" ] ; then

  # getting PITR START timestamp
  # shellcheck disable=SC2012
  HOURLYQUERY=$(ls -t ${BACKUPDIR}/hourly | head -n 1 | cut -d '.' -f3)

  # setting the start timestamp to NOW for the first execution
  # limit the documents included in the output of mongodump
  # shellcheck disable=SC2016
  [ "${HOURLYQUERY}" ] && QUERY='{ "ts" : { ${gt} :  Timestamp('${HOURLYQUERY}', 1) } }' || QUERY=""
fi

# Create required directories
mkdir -p ${BACKUPDIR}/{hourly,daily,weekly,monthly} || shellout "failed to create directories '${BACKUPDIR}/{hourly,daily,weekly,monthly}'"

if [ "${LATEST}" = "yes" ] ; then
    rm -rf "${BACKUPDIR}/latest"
    mkdir -p "${BACKUPDIR}/latest" || shellout "failed to create directory '${BACKUPDIR}/latest'"
fi

# Do we use a filter for hourly point-in-time snapshotting?
if [ "${DOHOURLY}" == "yes" ] ; then

  # getting PITR START timestamp
  # shellcheck disable=SC2012
  HOURLYQUERY=$(ls -t ${BACKUPDIR}/hourly | head -n 1 | cut -d '.' -f3)

  # setting the start timestamp to NOW for the first execution
  # limit the documents included in the output of mongodump
  # shellcheck disable=SC2016
  [ "${HOURLYQUERY}" ] && QUERY='{ "ts" : { ${gt} :  Timestamp('${HOURLYQUERY}', 1) } }' || QUERY=""
fi

# Functions

# Database dump function
dbdump()
{
    if [ -n "${QUERY}" ] ; then
        # filter for point-in-time snapshotting and if DOHOURLY=yes
        # shellcheck disable=SC2086
        mongodump --quiet --host="${DBHOST}:${DBPORT}" --out="/tmp/${1##*/}" ${OPT} -q "${QUERY}" || shellout "mongodump failed to create '${1}' with error code ${?}"
      else
        # all others backups type
        # shellcheck disable=SC2086
        mongodump --quiet --host="${DBHOST}:${DBPORT}" --out="/tmp/${1##*/}" ${OPT} || shellout "mongodump failed to create '${1}' with error code ${?}"
    fi
    [ -e "/tmp/${1##*/}" ] && return 0
    echo "ERROR: mongodump failed to create dumpfile: '/tmp/${1##*/}'" >&2
    return 1
}

#
# Select first available Secondary member in the Replica Sets and show its
# host name and port.
#
select_secondary_member()
{
    # We will use indirect-reference hack to return variable from this function.
    local __return=${1}

    # Return list of with all replica set members
    # shellcheck disable=SC2086
    members=( $(mongo --quiet --host ${DBHOST}:${DBPORT} --eval 'rs.conf().members.forEach(function(x){ print(x.host) })' ${OPTSEC} ) )

    # Check each replset member to see if it's a secondary and return it.
    if [ ${#members[@]} -gt 1 ] ; then
        for member in "${members[@]}"; do

            is_secondary=$(mongo --quiet --host "${member}" --eval 'rs.isMaster().secondary' ${OPTSEC} )
            case "${is_secondary}" in
                'true')     # First secondary wins ...
                    secondary="${member}"
                    break
                ;;
                'false')    # Skip particular member if it is a Primary.
                    continue
                ;;
                *)          # Skip irrelevant entries.  Should not be any anyway ...
                    continue
                ;;
            esac
        done
    fi

     Ugly hack to return value from a Bash function ...
    # shellcheck disable=SC2086
        [ -n "${secondary}" ] && eval ${__return}="'${secondary}'"
}

# Compression function plus latest copy
compression()
{
    file="${1##*/}"
    tar -C /tmp -czf "${1}.tgz" "${file}"

    if [ "${LATEST}" = "yes" ] ; then
        [ "${LATESTLINK}" = "yes" ] && COPY="ln" || COPY="cp"
        ${COPY} "${1}.tgz" "${BACKUPDIR}/latest/"
    fi

    [ "${CLEANUP}" = "yes" ] && rm -rf "/tmp/${file}" || echo "Cleaning up folder at '/tmp/${file}' failed."

    return 0
}

# Run command before we begin
[ "${PREBACKUP}" ] && eval "${PREBACKUP}"

# Try to select an available secondary for the backup or fallback to DBHOST.
if [ "${REPLICAONSLAVE}" == "yes" ] ; then
    # Return value via indirect-reference hack ...
    select_secondary_member secondary

    if [ -n "${secondary}" ] ; then
        DBHOST=${secondary%%:*}
        DBPORT=${secondary##*:}
    else
        SECONDARY_WARNING="WARNING: No suitable Secondary found in the Replica Sets.  Falling back to ${DBHOST}."
    fi
fi

[ "${SECONDARY_WARNING}" ] && echo -e "${SECONDARY_WARNING}"

# Monthly Full Backup of all Databases
if [ "${DOM}" = "01" ] && [ ${DOMONTHLY} = "yes" ] ; then
    # Delete old monthly backups while respecting the set rentention policy.
    [ "${MONTHLYRETENTION}" -ge "0" ] && find ${BACKUPDIR}/monthly -not -newermt "${MONTHLYRETENTION} month ago" -type f -delete
    FILE="${BACKUPDIR}/monthly/${DATE}.${M}"
# Weekly Backup
elif [ "${DNOW}" = "${WEEKLYDAY}" ] && [ "${DOWEEKLY}" = "yes" ] ; then
    [ "${WEEKLYRETENTION}" -ge "0" ] && find "${BACKUPDIR}/weekly" -not -newermt "${WEEKLYRETENTION} week ago" -type f -delete
    FILE="${BACKUPDIR}/weekly/week.${W}.${DATE}"
# Daily Backup
elif [ "${DODAILY}" = "yes" ] ; then
        [ "${DAILYRETENTION}" -ge "0" ] && find "${BACKUPDIR}/daily" -not -newermt "${DAILYRETENTION} days ago" -type f -delete
    FILE="${BACKUPDIR}/daily/${DATE}.${DOW}"
# Hourly Backup
elif [ "${DOHOURLY}" = "yes" ] ; then
        [ "${HOURLYRETENTION}" -ge "0" ] && find ${BACKUPDIR}/hourly -not -newermt "${HOURLYRETENTION} hour ago" -type f -delete
    FILE="${BACKUPDIR}/hourly/${DATE}.${DOW}.${HOD}"
fi

# FILE will not be set if no frequency is selected.
[ "${FILE}" ] || { echo -e "ERROR: No backup frequency was chosen.\nPlease set one of DOHOURLY,DODAILY,DOWEEKLY,DOMONTHLY to 'yes'" ; exit 1 ; }

dbdump "${FILE}" || exit 1
compression "${FILE}" || exit 1

# Run command when we're done
[ "${POSTBACKUP}" ] && eval "${POSTBACKUP}"

exit 0
