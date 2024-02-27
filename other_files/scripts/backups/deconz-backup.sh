#!/bin/bash

set -e

DEBUG=${DEBUG_OVERRIDE:-0}

cleanExit() {
    [[ $DEBUG > 0 ]] && echo "Deconz auto backup script - ENDING ..."
}

trap cleanExit EXIT # setting exit function

[[ $DEBUG > 0 ]] && echo "Deconz auto backup script - STARTING ..."

DATE=${DATE_OVERRIDE:-$(date +"%Y-%m-%d-%H-%M-%S")}
HOST_ADDRESS=${HOST_ADDRESS_OVERRIDE:-"localhost"}

[[ $DEBUG > 0 ]] && echo "Checking input variables"

if [[ -z $BACKUP_FOLDER ]]; then
    [[ $DEBUG > 0 ]] && echo "BACKUP_FOLDER variable is empty or not set"
    exit 0
fi

if [[ -z $LONG_TERM_BACKUP_FOLDER ]]; then
    [[ $DEBUG > 0 ]] && echo "LONG_TERM_BACKUP_FOLDER variable is empty or not set"
    exit 0
fi

if [[ -z $API_KEY ]]; then
    [[ $DEBUG > 0 ]] && echo "API_KEY variable is empty or not set"
    exit 0
fi

if [[ -z $DECONZ_PORT ]]; then
    [[ $DEBUG > 0 ]] && echo "DECONZ_PORT variable is empty or not set"
    exit 0
fi

[[ $DEBUG > 0 ]] && echo "All variables inserted"
[[ $DEBUG > 0 ]] && echo "Creating backup of deconz"

curl -X POST "http://$HOST_ADDRESS:$DECONZ_PORT/api/$API_KEY/config/export"
sleep 10

BACKUP_FILE_NAME="deCONZ.tar.gz"

if [[ -e "$BACKUP_FOLDER/$BACKUP_FILE_NAME" ]]; then

    [[ $DEBUG > 0 ]] && echo "backup done"

    [[ $DEBUG > 0 ]] && echo "moving $BACKUP_FILE_NAME"

    mv "$BACKUP_FOLDER/$BACKUP_FILE_NAME" "$LONG_TERM_BACKUP_FOLDER/raspbee_gateway_config_$DATE.dat"

    [[ $DEBUG > 0 ]] && echo "done"
fi