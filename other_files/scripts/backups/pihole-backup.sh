#!/bin/bash

set -e

DEBUG=${DEBUG_OVERRIDE:-0}

cleanExit() {
    [[ $DEBUG > 0 ]] && echo "Pihole auto backup script - ENDING ..."
}

trap cleanExit EXIT # setting exit function

[[ $DEBUG > 0 ]] && echo "Pihole auto backup script - STARTING ..."

DATE=${DATE_OVERRIDE:-$(date +"%Y-%m-%d-%H-%M-%S")}
DO_NOT_DELETE_KEY=${DO_NOT_DELETE_KEY_OVERRIDE:-"DO-NOT-DELETE"}

[[ $DEBUG > 0 ]] && echo "Checking input variables"

if [[ -z $BACKUP_FOLDER ]]; then
    [[ $DEBUG > 0 ]] && echo "BACKUP_FOLDER variable is empty or not set"
    exit 0
fi

if [[ -z $LONG_TERM_BACKUP_FOLDER ]]; then
    [[ $DEBUG > 0 ]] && echo "LONG_TERM_BACKUP_FOLDER variable is empty or not set"
    exit 0
fi

[[ $DEBUG > 0 ]] && echo "All variables inserted"
[[ $DEBUG > 0 ]] && echo "Creating backup of pihole"

docker exec -w "/backups" pihole bash pihole -a -t
sleep 10

if [[ -z "$(ls -A $BACKUP_FOLDER)" ]]; then
    [[ $DEBUG > 0 ]] && echo "backup folder: $BACKUP_FOLDER, is empty"
    exit 0
fi

[[ $DEBUG > 0 ]] && echo "Backup done"
[[ $DEBUG > 0 ]] && echo "Moving backups in long term storage"

for x in $BACKUP_FOLDER/*; do

    FILE_BASEPATH=${x##*/} # basepath
    [[ $DEBUG > 0 ]] && echo "found $FILE_BASEPATH"

    USER="${FILE_BASEPATH:8:12}" # from position 8 for 12 characters
    DAY=${FILE_BASEPATH:32:10}
    TIME=${FILE_BASEPATH:43:8}
    TIME=${TIME/-/:}
    TIME=${TIME/-/:}
    FORMATTED_FILE_DATE=$(date -d "$DAY $TIME" +"%Y-%m-%d-%H-%M-%S")


    if [[ "$FILE_BASEPATH" =~ $DO_NOT_DELETE_KEY ]]; then
        cp "$x" "$LONG_TERM_BACKUP_FOLDER/pihole_backup-$USER-$FORMATTED_FILE_DATE.tar"
    else
        mv "$x" "$LONG_TERM_BACKUP_FOLDER/pihole_backup-$USER-$FORMATTED_FILE_DATE.tar"
    fi

done
