#!/bin/bash

QUIET=0     # DEBUG=0 quiet
ERROR=1     # DEBUG=1 only error <- default
WARN=2      # DEBUG=2 error and some info
INFO=3      # DEBUG=3 print all
DEBUG=4     # debug=4 will set the -x parameter and disable all manual echo

VERBOSE=${VERBOSE_OVERRIDE:-1}

cleanExit() {
    [[ $VERBOSE -ge $INFO ]] && echo "Pihole auto backup script - ENDING ..."
}

trap cleanExit EXIT # setting exit function

[[ $VERBOSE -ge $INFO ]] && echo "Pihole auto backup script - STARTING ..."

DATE=${DATE_OVERRIDE:-$(date +"%Y-%m-%d-%H-%M-%S")}
DO_NOT_DELETE_KEY=${DO_NOT_DELETE_KEY_OVERRIDE:-"DO-NOT-DELETE"}

[[ $VERBOSE -ge $INFO ]] && echo "Checking input variables"

if [[ -z $BACKUP_FOLDER ]]; then
    [[ $VERBOSE -ge $ERROR ]] && echo "BACKUP_FOLDER variable is empty or not set"
    exit 0
fi

if [[ -z $LONG_TERM_BACKUP_FOLDER ]]; then
    [[ $VERBOSE -ge $ERROR ]] && echo "LONG_TERM_BACKUP_FOLDER variable is empty or not set"
    exit 0
fi

[[ $VERBOSE -ge $INFO ]] && echo "All variables inserted"
[[ $VERBOSE -ge $INFO ]] && echo "Creating backup of pihole"

result=$(docker exec -w "/backups" pihole bash pihole -a -t)
[[ $VERBOSE -ge $INFO ]] && echo "Backup pihole result: $result"
sleep 10

if [[ -z "$(ls -A $BACKUP_FOLDER)" ]]; then
    [[ $VERBOSE -ge $ERROR ]] && echo "backup folder: $BACKUP_FOLDER, is empty"
    exit 0
fi

[[ $VERBOSE -ge $INFO ]] && echo "Backup done"
[[ $VERBOSE -ge $INFO ]] && echo "Moving backups in long term storage"

for x in $BACKUP_FOLDER/*; do

    basepath=$(basename $x)
    [[ $VERBOSE -ge $INFO ]] && echo "found $basepath"

    user="${basepath:8:12}" # from position 8 for 12 characters
    day=${basepath:32:10}
    _time=${basepath:43:8}
    __time=${_time//-/:}
    formatted_file_date=$(date -d "$day $__time" +"%Y-%m-%d-%H-%M-%S")


    if [[ "$basepath" =~ $DO_NOT_DELETE_KEY ]]; then
        cp "$x" "$LONG_TERM_BACKUP_FOLDER/pihole_backup-$user-$formatted_file_date.tar"
    else
        mv "$x" "$LONG_TERM_BACKUP_FOLDER/pihole_backup-$user-$formatted_file_date.tar"
    fi

done

exit 0