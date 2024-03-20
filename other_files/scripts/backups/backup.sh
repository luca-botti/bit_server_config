#!/bin/bash

# secrets file needed to run ; use '(source <path-to-secret-env-file> && bash <path-to-backup.sh-folder>/backup.sh)' to run (used a sub shell to not poison the normal shell environment)

###### SETTINGS ######

QUIET=0     # DEBUG=0 quiet
ERROR=1     # DEBUG=1 only error <- default
WARN=2      # DEBUG=2 error and some info
INFO=3      # DEBUG=3 print all
DEBUG=4     # debug=4 will set the -x parameter and disable all manual echo

VERBOSE=${V:-1}

# if set to one just do the upload, do not create new backups
ONLY_UPLOAD=${U:-0}



###### GLOBAL VARIABLES ######
args=()
[[ $VERBOSE -ge $DEBUG ]] && set -x && args+=( '-x' ) && VERBOSE=1

DATE=$(date +"%Y-%m-%d-%H-%M-%S")

BACKUP_SCRIPT_FOLDER="/bit_server/other_files/scripts/backups"
TEMP_FOLDER="/bit_server/backups/.temp"
DO_NOT_DELETE_KEY="DO-NOT-DELETE" # default "DO-NOT-DELETE"

###### GLOBAL SECRETS ######

HOST_ADDRESS=${HOST_ADDRESS:-"localhost"}


###### SERVICE SPECIFIC ######


###### HOME ASSISTANT ######

# variables

HASSIO_BACKUP_FOLDER="/bit_server/homeassistant/config/backups"
HASSIO_LONG_TERM_BACKUP_FOLDER="/bit_server/backups/homeassistant"

#  secrets

HASSIO_LONG_TERM_TOKEN=${HASSIO_LT_TOKEN:-""}
HASSIO_PORT=${HASSIO_PORT:-"8123"}

# script

[[ $ONLY_UPLOAD -eq 0 ]] && env \
    VERBOSE_OVERRIDE=$VERBOSE \
    DATE_OVERRIDE=$DATE \
    DO_NOT_DELETE_KEY_OVERRIDE=$DO_NOT_DELETE_KEY \
    HOST_ADDRESS_OVERRIDE=$HOST_ADDRESS \
    HASSIO_PORT_OVERRIDE=$HASSIO_PORT \
    BACKUP_FOLDER=$HASSIO_BACKUP_FOLDER \
    LONG_TERM_BACKUP_FOLDER=$HASSIO_LONG_TERM_BACKUP_FOLDER \
    LONG_TERM_TOKEN=$HASSIO_LONG_TERM_TOKEN \
    TEMP_FOLDER=$TEMP_FOLDER \
    bash "${args[@]}" $BACKUP_SCRIPT_FOLDER/homeassistant-backup.sh
#


###### DECONZ ######

# variables

DECONZ_BACKUP_FOLDER="/bit_server/deconz"
DECONZ_LONG_TERM_BACKUP_FOLDER="/bit_server/backups/deconz"

# secrets

DECONZ_PORT=${DECONZ_WEB_PORT:-""}
API_KEY=${DECONZ_USER_API:-""}

# script

[[ $ONLY_UPLOAD -eq 0 ]] && env \
    VERBOSE_OVERRIDE=$VERBOSE \
    DATE_OVERRIDE=$DATE \
    HOST_ADDRESS_OVERRIDE=$HOST_ADDRESS \
    DECONZ_PORT=$DECONZ_PORT \
    BACKUP_FOLDER=$DECONZ_BACKUP_FOLDER \
    LONG_TERM_BACKUP_FOLDER=$DECONZ_LONG_TERM_BACKUP_FOLDER \
    API_KEY=$API_KEY \
    bash "${args[@]}" $BACKUP_SCRIPT_FOLDER/deconz-backup.sh
#


###### PIHOLE ######

# variables

PIHOLE_BACKUP_FOLDER="/bit_server/pihole/backups"
PIHOLE_LONG_TERM_BACKUP_FOLDER="/bit_server/backups/pihole"

# secrets

# script

[[ $ONLY_UPLOAD -eq 0 ]] && env \
    VERBOSE_OVERRIDE=$VERBOSE \
    DATE_OVERRIDE=$DATE \
    DO_NOT_DELETE_KEY_OVERRIDE=$DO_NOT_DELETE_KEY \
    BACKUP_FOLDER=$PIHOLE_BACKUP_FOLDER \
    LONG_TERM_BACKUP_FOLDER=$PIHOLE_LONG_TERM_BACKUP_FOLDER \
    bash "${args[@]}" $BACKUP_SCRIPT_FOLDER/pihole-backup.sh
#

###### SECRETS FOLDER ######

# variables

SECRETS_FOLDER="/bit_server/other_files/secrets"
SECRETS_LONG_TERM_BACKUP_FOLDER="/bit_server/backups/secrets"

HASSIO_SECRETS_1="/bit_server/homeassistant/config/secrets.yaml"
HASSIO_SECRETS_2="/bit_server/homeassistant/config/*.json"

# secrets

# script

[[ $ONLY_UPLOAD -eq 0 ]] && env \
    VERBOSE_OVERRIDE=$VERBOSE \
    DATE_OVERRIDE=$DATE \
    SECRETS_FOLDER=$SECRETS_FOLDER \
    SECRETS_LONG_TERM_BACKUP_FOLDER=$SECRETS_LONG_TERM_BACKUP_FOLDER \
    HASSIO_SECRETS_1=$HASSIO_SECRETS_1 \
    HASSIO_SECRETS_2=$HASSIO_SECRETS_2 \
    TEMP_FOLDER=$TEMP_FOLDER \
    bash "${args[@]}" $BACKUP_SCRIPT_FOLDER/secrets-backup.sh

###### DRIVE UPLOAD ######

# see /bit_server/other_files/scripts/backups/gdrive/upload.sh for parameters and more info

env VERBOSE_OVERRIDE=$VERBOSE \
    HASSIO_LONG_TERM_BACKUP_FOLDER=$HASSIO_LONG_TERM_BACKUP_FOLDER \
    DECONZ_LONG_TERM_BACKUP_FOLDER=$DECONZ_LONG_TERM_BACKUP_FOLDER \
    PIHOLE_LONG_TERM_BACKUP_FOLDER=$PIHOLE_LONG_TERM_BACKUP_FOLDER \
    SECRETS_LONG_TERM_BACKUP_FOLDER=$SECRETS_LONG_TERM_BACKUP_FOLDER \
    bash "${args[@]}" $BACKUP_SCRIPT_FOLDER/gdrive/upload.sh

exit 0
