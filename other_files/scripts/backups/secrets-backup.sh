#!/bin/bash

QUIET=0     # DEBUG=0 quiet
ERROR=1     # DEBUG=1 only error <- default
WARN=2      # DEBUG=2 error and some info
INFO=3      # DEBUG=3 print all
DEBUG=4     # debug=4 will set the -x parameter and disable all manual echo

VERBOSE=${VERBOSE_OVERRIDE:-1}

cleanExit() {
    [[ $VERBOSE -ge $WARN ]] && echo "Secrets auto backup script - ENDING ..."
}

trap cleanExit EXIT # setting exit function

[[ $VERBOSE -ge $INFO ]] && echo "Secrets auto backup script - STARTING ..."

DATE=${DATE_OVERRIDE:-$(date +"%Y-%m-%d-%H-%M-%S")}

[[ $VERBOSE -ge $INFO ]] && echo "Checking input variables"

if [[ -z $SECRETS_FOLDER ]]; then
    [[ $VERBOSE -ge $ERROR ]] && echo "SECRETS_FOLDER variable is empty or not set"
    exit 0
fi

if [[ -z $SECRETS_LONG_TERM_BACKUP_FOLDER ]]; then
    [[ $VERBOSE -ge $ERROR ]] && echo "SECRETS_LONG_TERM_BACKUP_FOLDER variable is empty or not set"
    exit 0
fi

if [[ -z $HASSIO_SECRETS_1 ]]; then
    [[ $VERBOSE -ge $ERROR ]] && echo "HASSIO_SECRETS_1 variable is empty or not set"
    exit 0
fi

if [[ -z $HASSIO_SECRETS_2 ]]; then
    [[ $VERBOSE -ge $ERROR ]] && echo "HASSIO_SECRETS_2 variable is empty or not set"
    exit 0
fi

if [[ -z $TEMP_FOLDER ]]; then
    [[ $VERBOSE -ge $ERROR ]] && echo "TEMP_FOLDER variable is empty or not set"
    exit 0
fi

[[ $VERBOSE -ge $INFO ]] && echo "All variables inserted"

[[ $VERBOSE -ge $INFO ]] && echo "Creating backup"
# cp $HASSIO_SECRETS_1 $SECRETS_FOLDER/others           # already done with home assistant backups
# cp $HASSIO_SECRETS_2 $SECRETS_FOLDER/others           # already done with home assistant backups

find "$SECRETS_FOLDER" -type f -exec md5sum "{}" + > "$SECRETS_FOLDER/md5sum.chk"
result=$(tar -c -f "$SECRETS_FOLDER/secrets.tar" -C "$SECRETS_FOLDER/.." "secrets")
[[ $VERBOSE -ge $WARN ]] && echo "Backup secrets result: $result"

if [[ -z "$(ls $SECRETS_LONG_TERM_BACKUP_FOLDER)" ]]; then
    mv "$SECRETS_FOLDER/secrets.tar" "$SECRETS_LONG_TERM_BACKUP_FOLDER/secrets-$DATE.tar"
else
    latest=$(ls -At "$SECRETS_LONG_TERM_BACKUP_FOLDER" | head -n1)
    [[ $VERBOSE -ge $INFO ]] && echo "Latest file for secrets is $latest"

    tar -x -f "$SECRETS_LONG_TERM_BACKUP_FOLDER/$latest" -C "$TEMP_FOLDER" secrets/md5sum.chk

    changed=$(diff -q "$SECRETS_FOLDER/md5sum.chk" "$TEMP_FOLDER/secrets/md5sum.chk")

    if [[ -z "$changed" ]]; then
        [[ $VERBOSE -ge $INFO ]] && echo "Identical to the previous, just remove"
    else
        [[ $VERBOSE -ge $INFO ]] && echo "Changed, moving..."
        mv "$SECRETS_FOLDER/secrets.tar" "$SECRETS_LONG_TERM_BACKUP_FOLDER/secrets-$DATE.tar"
    fi
fi
rm -f "$SECRETS_FOLDER/secrets.tar" "$SECRETS_FOLDER/md5sum.chk"
rm -r -f "$TEMP_FOLDER"/*

exit 0