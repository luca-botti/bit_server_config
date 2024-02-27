#!/bin/bash

set -e

DEBUG=${DEBUG_OVERRIDE:-0}

cleanExit() {
    [[ $DEBUG > 0 ]] && echo "HomeAssistant auto backup script - ENDING ..."
}

trap cleanExit EXIT # setting exit function

[[ $DEBUG > 0 ]] && echo "HomeAssistant auto backup script - STARTING ..."

DATE=${DATE_OVERRIDE:-$(date +"%Y-%m-%d-%H-%M-%S")}
DO_NOT_DELETE_KEY=${DO_NOT_DELETE_KEY_OVERRIDE:-"DO-NOT-DELETE"}
HOST_ADDRESS=${HOST_ADDRESS_OVERRIDE:-"localhost"}
HASSIO_PORT=${HASSIO_PORT_OVERRIDE:-"8123"}

[[ $DEBUG > 0 ]] && echo "Checking input variables"

if [[ -z $BACKUP_FOLDER ]]; then
    [[ $DEBUG > 0 ]] && echo "BACKUP_FOLDER variable is empty or not set"
    exit 0
fi

if [[ -z $LONG_TERM_BACKUP_FOLDER ]]; then
    [[ $DEBUG > 0 ]] && echo "LONG_TERM_BACKUP_FOLDER variable is empty or not set"
    exit 0
fi

if [[ -z $LONG_TERM_TOKEN ]]; then
    [[ $DEBUG > 0 ]] && echo "LONG_TERM_TOKEN variable is empty or not set"
    exit 0
fi

if [[ -z $TEMP_FOLDER ]]; then
    [[ $DEBUG > 0 ]] && echo "TEMP_FOLDER variable is empty or not set, this will result that only the last alphabetical file is moved to the long term folder, the others are discarded"
    # exit 0
fi


[[ $DEBUG > 0 ]] && echo "All variables inserted"
[[ $DEBUG > 0 ]] && echo "Creating backup of homeassistant"

curl -X POST -H "Authorization: Bearer $LONG_TERM_TOKEN" -H "Content-Type: application/json" http://$HOST_ADDRESS:$HASSIO_PORT/api/services/backup/create
sleep 60

if [[ -z "$(ls -A $BACKUP_FOLDER)" ]]; then
    [[ $DEBUG > 0 ]] && echo "backup folder: $BACKUP_FOLDER, is empty"
    exit 0
fi

[[ $DEBUG > 0 ]] && echo "Backup done"

JSON_FILE_NAME="backup.json"
DATE_ATTRIBUTE="date"
SLUG_ATTRIBUTE="slug"


[[ $DEBUG > 0 ]] && echo "Moving backups in long term storage"

for x in $BACKUP_FOLDER/*; do

    FILE_BASEPATH=${x##*/} # basepath
    [[ $DEBUG > 0 ]] && echo "found $FILE_BASEPATH"

    if [[ -z $TEMP_FOLDER ]]; then
        if [[ "$FILE_BASEPATH" =~ $DO_NOT_DELETE_KEY ]]; then
            cp "$x" "$LONG_TERM_BACKUP_FOLDER/home_assistant_backup_$DATE.tar"
        else
            mv "$x" "$LONG_TERM_BACKUP_FOLDER/home_assistant_backup_$DATE.tar"
        fi
    else
        [[ $DEBUG > 0 ]] && echo "decompressing $FILE_BASEPATH"

        tar -x -f "$x" -C "$TEMP_FOLDER"

        [[ $DEBUG > 0 ]] && echo "done"
        [[ $DEBUG > 0 ]] && echo "moving $FILE_BASEPATH"

        FILE_DATE=$(jq -r ".$DATE_ATTRIBUTE" "$TEMP_FOLDER/$JSON_FILE_NAME")
        SLUG=$(jq -r ".$SLUG_ATTRIBUTE" "$TEMP_FOLDER/$JSON_FILE_NAME")
        FORMATTED_FILE_DATE=$(date -d "$FILE_DATE" +"%Y-%m-%d-%H-%M-%S")

        if [[ "$FILE_BASEPATH" =~ $DO_NOT_DELETE_KEY ]]; then
            cp "$x" "$LONG_TERM_BACKUP_FOLDER/home_assistant_backup-$SLUG-$FORMATTED_FILE_DATE.tar"
        else
            mv "$x" "$LONG_TERM_BACKUP_FOLDER/home_assistant_backup-$SLUG-$FORMATTED_FILE_DATE.tar"
        fi
        
        [[ $DEBUG > 0 ]] && echo "done moving $FILE_BASEPATH"
        [[ $DEBUG > 0 ]] && echo "cleaning temporary files"

        rm -f -r "$TEMP_FOLDER"/*

        [[ $DEBUG > 0 ]] && echo "done cleaning temporary files"

    fi
done
