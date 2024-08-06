#!/bin/bash

# this will trim each folder to a desired size

###### SETTINGS ######

QUIET=0     # DEBUG=0 quiet
ERROR=1     # DEBUG=1 only error <- default
WARN=2      # DEBUG=2 error and some info
INFO=3      # DEBUG=3 print all
DEBUG=4     # debug=4 will set the -x parameter and disable all manual echo

VERBOSE=${V:-1}


###### GLOBAL VARIABLES ######
args=()
[[ $VERBOSE -ge $DEBUG ]] && set -x && args+=( '-x' ) && VERBOSE=1

DATE=$(date +"%Y-%m-%d-%H-%M-%S")

BACKUP_SCRIPT_FOLDER="/bit_server/other_files/scripts/backups"
TEMP_FOLDER="/bit_server/backups/.temp"
DO_NOT_DELETE_KEY="DO-NOT-DELETE" # default "DO-NOT-DELETE"

# folders
HASSIO_LONG_TERM_BACKUP_FOLDER="/bit_server/backups/homeassistant"
DECONZ_LONG_TERM_BACKUP_FOLDER="/bit_server/backups/deconz"
PIHOLE_LONG_TERM_BACKUP_FOLDER="/bit_server/backups/pihole"
VAULTWARDEN_LONG_TERM_BACKUP_FOLDER="/bit_server/backups/vaultwarden"
SECRETS_LONG_TERM_BACKUP_FOLDER="/bit_server/backups/secrets"

DEFAULT_MAX_SIZE=10485760 # 10MB
# max sizes
HASSIO_MAX_SIZE=1073741824 # 1GB
DECONZ_MAX_SIZE=$DEFAULT_MAX_SIZE
PIHOLE_MAX_SIZE=$DEFAULT_MAX_SIZE
VAULTWARDEN_MAX_SIZE=$DEFAULT_MAX_SIZE
SECRETS_MAX_SIZE=$DEFAULT_MAX_SIZE


# $1 folder path
get-folder-bytes-size() {
    local temp=$(du -s -B 1 "$1/")
    local suffix_starter=$'\t'
    local temp=${temp%%$suffix_starter*}
    # echo "${temp@Q}"
    echo "$temp"
}

# $1 file path
get-file-bytes-size() {
    local temp=$(stat --printf="%s" $1)
    # echo "${temp@Q}"
    echo "$temp"
}

# $1 folder path, $2 max size
trim-folder() {
    local folder=$1
    local max_size=$2
    local size=$(get-folder-bytes-size $folder)

    while [ $size -gt $max_size ]; do
        local oldest_file=$(ls -t1 $folder | tail -1)
        local oldest_file_path="$folder/$oldest_file"
        local oldest_file_size=$(get-file-bytes-size $oldest_file_path)
        rm -f $oldest_file_path
        [[ $VERBOSE -ge $WARN ]] && echo "Deleted $oldest_file from local storage"
        sleep 1
        size=$(get-folder-bytes-size $folder)
    done
}

[[ $VERBOSE -ge $WARN ]] && echo "Deleting old backups from homeassistant"
trim-folder $HASSIO_LONG_TERM_BACKUP_FOLDER $HASSIO_MAX_SIZE

[[ $VERBOSE -ge $WARN ]] && echo "Deleting old backups from deconz"
trim-folder $DECONZ_LONG_TERM_BACKUP_FOLDER $DECONZ_MAX_SIZE

[[ $VERBOSE -ge $WARN ]] && echo "Deleting old backups from pihole"
trim-folder $PIHOLE_LONG_TERM_BACKUP_FOLDER $PIHOLE_MAX_SIZE

[[ $VERBOSE -ge $WARN ]] && echo "Deleting old backups from vaultwarden"
trim-folder $VAULTWARDEN_LONG_TERM_BACKUP_FOLDER $VAULTWARDEN_MAX_SIZE

[[ $VERBOSE -ge $WARN ]] && echo "Deleting old backups from secrets"
trim-folder $SECRETS_LONG_TERM_BACKUP_FOLDER $SECRETS_MAX_SIZE

[[ $VERBOSE -ge $WARN ]] && echo "All done"

