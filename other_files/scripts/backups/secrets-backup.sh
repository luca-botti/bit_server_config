#!/bin/bash

set -e

DEBUG=${DEBUG_OVERRIDE:-0}

cleanExit() {
    [[ $DEBUG > 0 ]] && echo "Secrets auto backup script - ENDING ..."
}

trap cleanExit EXIT # setting exit function

[[ $DEBUG > 0 ]] && echo "Secrets auto backup script - STARTING ..."

DATE=${DATE_OVERRIDE:-$(date +"%Y-%m-%d-%H-%M-%S")}

[[ $DEBUG > 0 ]] && echo "Checking input variables"

if [[ -z $SECRETS_FOLDER ]]; then
    [[ $DEBUG > 0 ]] && echo "SECRETS_FOLDER variable is empty or not set"
    exit 0
fi

if [[ -z $SECRETS_LONG_TERM_BACKUP_FOLDER ]]; then
    [[ $DEBUG > 0 ]] && echo "SECRETS_LONG_TERM_BACKUP_FOLDER variable is empty or not set"
    exit 0
fi

if [[ -z $HASSIO_SECRETS_1 ]]; then
    [[ $DEBUG > 0 ]] && echo "HASSIO_SECRETS_1 variable is empty or not set"
    exit 0
fi

if [[ -z $HASSIO_SECRETS_2 ]]; then
    [[ $DEBUG > 0 ]] && echo "HASSIO_SECRETS_2 variable is empty or not set"
    exit 0
fi

if [[ -z $TEMP_FOLDER ]]; then
    [[ $DEBUG > 0 ]] && echo "TEMP_FOLDER variable is empty or not set"
    exit 0
fi

[[ $DEBUG > 0 ]] && echo "All variables inserted"

[[ $DEBUG > 0 ]] && echo "Creating backup"
# cp $HASSIO_SECRETS_1 $SECRETS_FOLDER/others           # already done with home assistant backups
# cp $HASSIO_SECRETS_2 $SECRETS_FOLDER/others           # already done with home assistant backups

find "$SECRETS_FOLDER" -type f -exec md5sum "{}" + > "$SECRETS_FOLDER/md5sum.chk"
tar -c -f "$SECRETS_FOLDER/secrets.tar" -C "$SECRETS_FOLDER/.." "secrets"

if [[ -z "$(ls $SECRETS_LONG_TERM_BACKUP_FOLDER)" ]]; then
    mv "$SECRETS_FOLDER/secrets.tar" "$SECRETS_LONG_TERM_BACKUP_FOLDER/secrets-$DATE.tar"
else
    LATEST=$(ls -At "$SECRETS_LONG_TERM_BACKUP_FOLDER" | head -n1)
    [[ $DEBUG > 0 ]] && echo "Latest file for secrets is $LATEST"

    tar -x -f "$SECRETS_LONG_TERM_BACKUP_FOLDER/$LATEST" -C "$TEMP_FOLDER" secrets/md5sum.chk

    set +e # diff returns error value if the file differs
    CHANGED=$(diff -q "$SECRETS_FOLDER/md5sum.chk" "$TEMP_FOLDER/secrets/md5sum.chk")
    set -e

    if [[ -z "$CHANGED" ]]; then
        [[ $DEBUG > 0 ]] && echo "Identical to the previous, just remove"
    else
        [[ $DEBUG > 0 ]] && echo "Changed, moving..."
        mv "$SECRETS_FOLDER/secrets.tar" "$SECRETS_LONG_TERM_BACKUP_FOLDER/secrets-$DATE.tar"
    fi
fi
rm -f "$SECRETS_FOLDER/secrets.tar" "$SECRETS_FOLDER/md5sum.chk"
rm -r -f "$TEMP_FOLDER"/*