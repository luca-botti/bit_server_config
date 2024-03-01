#!/bin/bash

QUIET=0     # DEBUG=0 quiet
ERROR=1     # DEBUG=1 only error <- default
WARN=2      # DEBUG=2 error and some info
INFO=3      # DEBUG=3 print all
DEBUG=4     # debug=4 will set the -x parameter and disable all manual echo

VERBOSE=${VERBOSE_OVERRIDE:-1}

cleanExit() {
    [[ $VERBOSE -ge $WARN ]] && echo "Deconz auto backup script - ENDING ..."
}

trap cleanExit EXIT # setting exit function

[[ $VERBOSE -ge $INFO ]] && echo "Deconz auto backup script - STARTING ..."

DATE=${DATE_OVERRIDE:-$(date +"%Y-%m-%d-%H-%M-%S")}
HOST_ADDRESS=${HOST_ADDRESS_OVERRIDE:-"localhost"}

[[ $VERBOSE -ge $INFO ]] && echo "Checking input variables"

if [[ -z $BACKUP_FOLDER ]]; then
    [[ $VERBOSE -ge $ERROR ]] && echo "BACKUP_FOLDER variable is empty or not set"
    exit 0
fi

if [[ -z $LONG_TERM_BACKUP_FOLDER ]]; then
    [[ $VERBOSE -ge $ERROR ]] && echo "LONG_TERM_BACKUP_FOLDER variable is empty or not set"
    exit 0
fi

if [[ -z $API_KEY ]]; then
    [[ $VERBOSE -ge $ERROR ]] && echo "API_KEY variable is empty or not set"
    exit 0
fi

if [[ -z $DECONZ_PORT ]]; then
    [[ $VERBOSE -ge $ERROR ]] && echo "DECONZ_PORT variable is empty or not set"
    exit 0
fi

[[ $VERBOSE -ge $INFO ]] && echo "All variables inserted"
[[ $VERBOSE -ge $INFO ]] && echo "Creating backup of deconz"

result=$(curl -s -X POST "http://$HOST_ADDRESS:$DECONZ_PORT/api/$API_KEY/config/export")
[[ $VERBOSE -ge $WARN ]] && echo "Backup deconz result: $result"
sleep 10

BACKUP_FILE_NAME="deCONZ.tar.gz"

if [[ -e "$BACKUP_FOLDER/$BACKUP_FILE_NAME" ]]; then

    [[ $VERBOSE -ge $INFO ]] && echo "backup done"

    [[ $VERBOSE -ge $INFO ]] && echo "moving $BACKUP_FILE_NAME"

    mv "$BACKUP_FOLDER/$BACKUP_FILE_NAME" "$LONG_TERM_BACKUP_FOLDER/raspbee_gateway_config_$DATE.dat"

    [[ $VERBOSE -ge $INFO ]] && echo "done"
else
    [[ $VERBOSE -ge $ERROR ]] && echo "backup folder: $BACKUP_FOLDER, is empty"
fi

exit 0