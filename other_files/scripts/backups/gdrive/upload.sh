#!/bin/bash

HELPER="/bit_server/other_files/scripts/backups/gdrive/gdrive-toolkit/gdrive-tools.sh"

CLOUD_FOLDER_NAME="DockerRaspberry"

CLOUD_DECONZ="deconz"
CLOUD_HOMEASSISTANT="homeassistant"
CLOUD_PIHOLE="pihole"
CLOUD_SECRETS="secrets"

QUIET=0     # DEBUG=0 quiet
ERROR=1     # DEBUG=1 only error <- default
WARN=2      # DEBUG=2 error and some info
INFO=3      # DEBUG=3 print all
DEBUG=4     # debug=4 will set the -x parameter and disable all manual echo

VERBOSE=${VERBOSE_OVERRIDE:-1}

cleanExit() {
    [[ $VERBOSE -ge $WARN ]] && echo "Upload script finished"
}

trap cleanExit EXIT # setting exit function

# $1 folder path
get-folder-bytes-size() {
    local temp=$(du -s -B 1 "$1/")
    local suffix_starter=$'\t'
    local temp=${temp%%$suffix_starter*}
    # echo "${temp@Q}"
    echo "$temp"
}

# $1 path, $2 parent id
upload(){
    if [[ $# -ne 2 ]]; then
        return 1
    fi

    # cript files
        
    gdrive files upload --parent "$2" "$1" > /dev/null
}

default () {

    [[ $VERBOSE -ge $INFO ]] && echo "Checking variables"

    if [[ -z $HASSIO_LONG_TERM_BACKUP_FOLDER ]]; then
        [[ $VERBOSE -ge $ERROR ]] && echo "HASSIO_LONG_TERM_BACKUP_FOLDER variable is empty or not set"
        exit 0
    fi
    if [[ -z $DECONZ_LONG_TERM_BACKUP_FOLDER ]]; then
        [[ $VERBOSE -ge $ERROR ]] && echo "DECONZ_LONG_TERM_BACKUP_FOLDER variable is empty or not set"
        exit 0
    fi
    if [[ -z $PIHOLE_LONG_TERM_BACKUP_FOLDER ]]; then
        [[ $VERBOSE -ge $ERROR ]] && echo "PIHOLE_LONG_TERM_BACKUP_FOLDER variable is empty or not set"
        exit 0
    fi
    if [[ -z $SECRETS_LONG_TERM_BACKUP_FOLDER ]]; then
        [[ $VERBOSE -ge $ERROR ]] && echo "SECRETS_LONG_TERM_BACKUP_FOLDER variable is empty or not set"
        exit 0
    fi

    local v=$VERBOSE

    [[ $VERBOSE -ge $INFO ]] && echo "Done cheching variables"

    [[ $VERBOSE -ge $INFO ]] && echo "Getting root folder id"

    local root_directory_id=$(bash "$HELPER" --get-id="$CLOUD_FOLDER_NAME" --path="root/${CLOUD_FOLDER_NAME}" --verbose=$v)
    if [[ -z "$root_directory_id" ]]; then
        root_directory_id=$(gdrive files mkdir --print-only-id "$CLOUD_FOLDER_NAME")
    fi

    [[ $VERBOSE -ge $INFO ]] && echo "Root folder id: $root_directory_id"
    [[ $VERBOSE -ge $INFO ]] && echo "Getting services cloud folders ids"

    # not using persistant because we are modifing the drive
    local deconz_id=$(bash "$HELPER" --get-id="$CLOUD_DECONZ" --path="root/${CLOUD_FOLDER_NAME}/${CLOUD_DECONZ}" --verbose=$v)
    if [[ -z "$deconz_id" ]]; then
        deconz_id=$(gdrive files mkdir --parent "$root_directory_id" --print-only-id "$CLOUD_DECONZ")
    fi
    local homeassistant_id=$(bash "$HELPER" --get-id="$CLOUD_HOMEASSISTANT" --path="root/${CLOUD_FOLDER_NAME}/${CLOUD_HOMEASSISTANT}" --verbose=$v)
    if [[ -z "$homeassistant_id" ]]; then
        homeassistant_id=$(gdrive files mkdir --parent "$root_directory_id" --print-only-id "$CLOUD_HOMEASSISTANT")
    fi
    local pihole_id=$(bash "$HELPER" --get-id="$CLOUD_PIHOLE" --path="root/${CLOUD_FOLDER_NAME}/${CLOUD_PIHOLE}" --verbose=$v)
    if [[ -z "$pihole_id" ]]; then
        pihole_id=$(gdrive files mkdir --parent "$root_directory_id" --print-only-id "$CLOUD_PIHOLE")
    fi
    local secrets_id=$(bash "$HELPER" --get-id="$CLOUD_SECRETS" --path="root/${CLOUD_FOLDER_NAME}/${CLOUD_SECRETS}" --verbose=$v)
    if [[ -z "$secrets_id" ]]; then
        secrets_id=$(gdrive files mkdir --parent "$root_directory_id" --print-only-id "$CLOUD_SECRETS")
    fi

    [[ $VERBOSE -ge $INFO ]] && echo "Deconz cloud folder id: $deconz_id"
    [[ $VERBOSE -ge $INFO ]] && echo "HomeAssistant cloud folder id: $homeassistant_id"
    [[ $VERBOSE -ge $INFO ]] && echo "Pihole cloud folder id: $pihole_id"
    [[ $VERBOSE -ge $INFO ]] && echo "Secrets cloud folder id: $secrets_id"

    [[ $VERBOSE -ge $INFO ]] && echo "Retrieving files list inside cloud and on the local machine, then finding the new file to upload"

    # using -p for a little speed-up
    IFS=' ' read -a cloud_deconz_list <<< $(bash "$HELPER" --get-list="$CLOUD_DECONZ" --path="root/${CLOUD_FOLDER_NAME}/${CLOUD_DECONZ}" --name -p --verbose=$v)
    IFS=' ' read -a cloud_homeassistant_list <<< $(bash "$HELPER" --get-list="$CLOUD_HOMEASSISTANT" --path="root/${CLOUD_FOLDER_NAME}/${CLOUD_HOMEASSISTANT}" --name -p --verbose=$v)
    IFS=' ' read -a cloud_pihole_list <<< $(bash "$HELPER" --get-list="$CLOUD_PIHOLE" --path="root/${CLOUD_FOLDER_NAME}/${CLOUD_PIHOLE}" --name -p --verbose=$v)
    IFS=' ' read -a cloud_secrets_list <<< $(bash "$HELPER" --get-list="$CLOUD_SECRETS" --path="root/${CLOUD_FOLDER_NAME}/${CLOUD_SECRETS}" --name -p --verbose=$v)

    # locals list
    local temp=($DECONZ_LONG_TERM_BACKUP_FOLDER/*)
    local local_deconz_list=()
    for elem in "${temp[@]}"; do
        local_deconz_list+=("$(basename "$elem")")
    done
    temp=($HASSIO_LONG_TERM_BACKUP_FOLDER/*)
    local local_homeassistant_list=()
    for elem in "${temp[@]}"; do
        local_homeassistant_list+=("$(basename "$elem")")
    done
    temp=($PIHOLE_LONG_TERM_BACKUP_FOLDER/*)
    local local_pihole_list=()
    for elem in "${temp[@]}"; do
        local_pihole_list+=("$(basename "$elem")")
    done
    temp=($SECRETS_LONG_TERM_BACKUP_FOLDER/*)
    local local_secrets_list=()
    for elem in "${temp[@]}"; do
        local_secrets_list+=("$(basename "$elem")")
    done

    # new files to upload
    local new_deconz=()
    for local_elem in "${local_deconz_list[@]}"; do
        local -i found=0
        for cloud_elem in "${cloud_deconz_list[@]}"; do
            if [[ "$local_elem" == "$cloud_elem" ]]; then
                found=1
                break
            fi
        done
        if [[ $found -eq 0 ]]; then
            new_deconz+=("$local_elem")
        fi
    done
    local new_homeassistant=()
    for local_elem in "${local_homeassistant_list[@]}"; do
        local -i found=0
        for cloud_elem in "${cloud_homeassistant_list[@]}"; do
            if [[ "$local_elem" == "$cloud_elem" ]]; then
                found=1
                break
            fi
        done
        if [[ $found -eq 0 ]]; then
            new_homeassistant+=("$local_elem")
        fi
    done
    local new_pihole=()
    for local_elem in "${local_pihole_list[@]}"; do
        local -i found=0
        for cloud_elem in "${cloud_pihole_list[@]}"; do
            if [[ "$local_elem" == "$cloud_elem" ]]; then
                found=1
                break
            fi
        done
        if [[ $found -eq 0 ]]; then
            new_pihole+=("$local_elem")
        fi
    done
    local new_secrets=()
    for local_elem in "${local_secrets_list[@]}"; do
        local -i found=0
        for cloud_elem in "${cloud_secrets_list[@]}"; do
            if [[ "$local_elem" == "$cloud_elem" ]]; then
                found=1
                break
            fi
        done
        if [[ $found -eq 0 ]]; then
            new_secrets+=("$local_elem")
        fi
    done

    [[ $VERBOSE -ge $WARN ]] && echo "New for Deconz: $new_deconz"
    [[ $VERBOSE -ge $WARN ]] && echo "New for HomeAssistant: $new_homeassistant"
    [[ $VERBOSE -ge $WARN ]] && echo "New for Pihole: $new_pihole"
    [[ $VERBOSE -ge $WARN ]] && echo "New for Secrets: $new_secrets"

    [[ $VERBOSE -ge $INFO ]] && echo "Uploading to the cloud the new files"

    for elem in "${new_deconz[@]}"; do
        upload "${DECONZ_LONG_TERM_BACKUP_FOLDER}/${elem}" "$deconz_id"
    done
    for elem in "${new_homeassistant[@]}"; do
        upload "${HASSIO_LONG_TERM_BACKUP_FOLDER}/${elem}" "$homeassistant_id"
    done
    for elem in "${new_pihole[@]}"; do
        upload "${PIHOLE_LONG_TERM_BACKUP_FOLDER}/${elem}" "$pihole_id"
    done
    for elem in "${new_secrets[@]}"; do
        upload "${SECRETS_LONG_TERM_BACKUP_FOLDER}/${elem}" "$secrets_id"
    done
    
    [[ $VERBOSE -ge $INFO ]] && echo "Upload completed"

    bash "$HELPER" -i --verbose=$v
}

[[ $VERBOSE -ge $INFO ]] && echo "Upload script started"

default

exit 0