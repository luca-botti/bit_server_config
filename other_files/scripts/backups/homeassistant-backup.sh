#!/bin/bash

QUIET=0     # DEBUG=0 quiet
ERROR=1     # DEBUG=1 only error <- default
WARN=2      # DEBUG=2 error and some info
INFO=3      # DEBUG=3 print all
DEBUG=4     # debug=4 will set the -x parameter and disable all manual echo

VERBOSE=${VERBOSE_OVERRIDE:-1}

cleanExit() {
    [[ $VERBOSE -ge $WARN ]] && echo "HomeAssistant auto backup script - ENDING ..."
}

trap cleanExit EXIT # setting exit function

[[ $VERBOSE -ge $INFO ]] && echo "HomeAssistant auto backup script - STARTING ..."

DATE=${DATE_OVERRIDE:-$(date +"%Y-%m-%d-%H-%M-%S")}
DO_NOT_DELETE_KEY=${DO_NOT_DELETE_KEY_OVERRIDE:-"DO-NOT-DELETE"}
HOST_ADDRESS=${HOST_ADDRESS_OVERRIDE:-"localhost"}
HASSIO_PORT=${HASSIO_PORT_OVERRIDE:-"8123"}

[[ $VERBOSE -ge $INFO ]] && echo "Checking input variables"

if [[ -z $BACKUP_FOLDER ]]; then
    [[ $VERBOSE -ge $ERROR ]] && echo "BACKUP_FOLDER variable is empty or not set"
    exit 0
fi

if [[ -z $LONG_TERM_BACKUP_FOLDER ]]; then
    [[ $VERBOSE -ge $ERROR ]] && echo "LONG_TERM_BACKUP_FOLDER variable is empty or not set"
    exit 0
fi

if [[ -z $LONG_TERM_TOKEN ]]; then
    [[ $VERBOSE -ge $ERROR ]] && echo "LONG_TERM_TOKEN variable is empty or not set"
    exit 0
fi

if [[ -z $TEMP_FOLDER ]]; then
    [[ $VERBOSE -ge $WARN ]] && echo "TEMP_FOLDER variable is empty or not set, this will result that only the last alphabetical file is moved to the long term folder, the others are discarded"
    # exit 0
fi


[[ $VERBOSE -ge $INFO ]] && echo "All variables inserted"
[[ $VERBOSE -ge $INFO ]] && echo "Creating backup of homeassistant"

result=$(curl -s -X POST -H "Authorization: Bearer $LONG_TERM_TOKEN" -H "Content-Type: application/json" http://$HOST_ADDRESS:$HASSIO_PORT/api/services/backup/create)
[[ $VERBOSE -ge $WARN ]] && echo "Backup homeassistant result: $result"
sleep 10

if [[ -z "$(ls -A $BACKUP_FOLDER)" ]]; then
    [[ $VERBOSE -ge $ERROR ]] && echo "backup folder: $BACKUP_FOLDER, is empty"
    exit 0
fi

[[ $VERBOSE -ge $INFO ]] && echo "Backup done"

JSON_FILE_NAME="backup.json"
DATE_ATTRIBUTE="date"
SLUG_ATTRIBUTE="slug"


[[ $VERBOSE -ge $INFO ]] && echo "Moving backups in long term storage"

for x in $BACKUP_FOLDER/*; do

    basepath=$(basename $x)
    [[ $VERBOSE -ge $INFO ]] && echo "found $basepath"

    if [[ -z $TEMP_FOLDER ]]; then
        if [[ "$basepath" =~ $DO_NOT_DELETE_KEY ]]; then
            cp "$x" "$LONG_TERM_BACKUP_FOLDER/home_assistant_backup_$DATE.tar"
        else
            mv "$x" "$LONG_TERM_BACKUP_FOLDER/home_assistant_backup_$DATE.tar"
        fi
    else
        [[ $VERBOSE -ge $INFO ]] && echo "decompressing $basepath"

        tar -x -f "$x" -C "$TEMP_FOLDER"

        [[ $VERBOSE -ge $INFO ]] && echo "done"
        [[ $VERBOSE -ge $INFO ]] && echo "moving $basepath"

        file_date=$(jq -r ".$DATE_ATTRIBUTE" "$TEMP_FOLDER/$JSON_FILE_NAME")
        slug=$(jq -r ".$SLUG_ATTRIBUTE" "$TEMP_FOLDER/$JSON_FILE_NAME")
        formatted_file_date=$(date -d "$file_date" +"%Y-%m-%d-%H-%M-%S")

        if [[ "$basepath" =~ $DO_NOT_DELETE_KEY ]]; then
            cp "$x" "$LONG_TERM_BACKUP_FOLDER/home_assistant_backup-$slug-$formatted_file_date.tar"
        else
            mv "$x" "$LONG_TERM_BACKUP_FOLDER/home_assistant_backup-$slug-$formatted_file_date.tar"
        fi
        
        [[ $VERBOSE -ge $INFO ]] && echo "done moving $basepath"
        [[ $VERBOSE -ge $INFO ]] && echo "cleaning temporary files"

        rm -f -r "$TEMP_FOLDER"/*

        [[ $VERBOSE -ge $INFO ]] && echo "done cleaning temporary files"

    fi
done

exit 0
