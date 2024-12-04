#!/bin/bash

HELPER="/bit_server/other_files/scripts/backups/gdrive/gdrive-toolkit/gdrive-tools.sh"

CLOUD_FOLDER_NAME="DockerRaspberry"

CLOUD_DECONZ="deconz"
CLOUD_HOMEASSISTANT="homeassistant"
CLOUD_PIHOLE="pihole"
CLOUD_SECRETS="secrets"
CLOUD_VAULTWARDEN="vaultwarden"

QUIET=0     # DEBUG=0 quiet
ERROR=1     # DEBUG=1 only error <- default
WARN=2      # DEBUG=2 error and some info
INFO=3      # DEBUG=3 print all
DEBUG=4     # debug=4 will set the -x parameter and disable all manual echo

VERBOSE=${VERBOSE_OVERRIDE:-1}

FILES_TO_KEEP=5

cleanExit() {
    [[ $VERBOSE -ge $WARN ]] && echo "Upload script finished"
}

trap cleanExit EXIT # setting exit function

# $1 path, $2 parent id
upload(){
    if [[ $# -ne 2 ]]; then
        return 1
    fi

    # encrypt

    gpg --batch --passphrase "$PASSPHRASE" --symmetric "$1"
    touch -r "$1" "$1.gpg"

    filename="$1.gpg"
        
    gdrive files upload --parent "$2" "$filename" > /dev/null

    [[ $VERBOSE -ge $INFO ]] && echo "Uploaded $filename"

    # removing gpg file

    rm -f "$filename"
}

# $1 max new file to upload for service
default () {

    if [[ $# -ne 1 ]]; then
        local keep=100
    else
        local keep=$1
    fi

    [[ $VERBOSE -ge $INFO ]] && echo "Checking variables"

    # if [[ -z $GDRIVE_ACCOUNT ]]; then
    #     [[ $VERBOSE -ge $ERROR ]] && echo "GDRIVE_ACCOUNT variable is empty or not set"
    #     exit 0
    # fi
    # if [[ -z $GDRIVE_CREDENTIALS_PATH ]]; then
    #     [[ $VERBOSE -ge $ERROR ]] && echo "GDRIVE_CREDENTIALS_PATH variable is empty or not set"
    #     exit 0
    # fi
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
    if [[ -z $VAULTWARDEN_LONG_TERM_BACKUP_FOLDER ]]; then
        [[ $VERBOSE -ge $ERROR ]] && echo "VAULTWARDEN_LONG_TERM_BACKUP_FOLDER variable is empty or not set"
        exit 0
    fi
    if [[ -z $SECRETS_LONG_TERM_BACKUP_FOLDER ]]; then
        [[ $VERBOSE -ge $ERROR ]] && echo "SECRETS_LONG_TERM_BACKUP_FOLDER variable is empty or not set"
        exit 0
    fi



    if [[ $VERBOSE -ge $DEBUG ]]; then
        local v=3
    else
        local v=0
    fi

    [[ $VERBOSE -ge $INFO ]] && echo "Done cheching variables"

    # gdrive account import "$GDRIVE_CREDENTIALS_PATH"
    # gdrive account list
    # gdrive account switch "$GDRIVE_ACCOUNT"

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
    local vaultwarden_id=$(bash "$HELPER" --get-id="$CLOUD_VAULTWARDEN" --path="root/${CLOUD_FOLDER_NAME}/${CLOUD_VAULTWARDEN}" --verbose=$v)
    if [[ -z "$vaultwarden_id" ]]; then
        vaultwarden_id=$(gdrive files mkdir --parent "$root_directory_id" --print-only-id "$CLOUD_VAULTWARDEN")
    fi
    local secrets_id=$(bash "$HELPER" --get-id="$CLOUD_SECRETS" --path="root/${CLOUD_FOLDER_NAME}/${CLOUD_SECRETS}" --verbose=$v)
    if [[ -z "$secrets_id" ]]; then
        secrets_id=$(gdrive files mkdir --parent "$root_directory_id" --print-only-id "$CLOUD_SECRETS")
    fi

    [[ $VERBOSE -ge $INFO ]] && echo "Deconz cloud folder id: $deconz_id"
    [[ $VERBOSE -ge $INFO ]] && echo "HomeAssistant cloud folder id: $homeassistant_id"
    [[ $VERBOSE -ge $INFO ]] && echo "Pihole cloud folder id: $pihole_id"
    [[ $VERBOSE -ge $INFO ]] && echo "Vaultwarden cloud folder id: $vaultwarden_id"
    [[ $VERBOSE -ge $INFO ]] && echo "Secrets cloud folder id: $secrets_id"

    [[ $VERBOSE -ge $INFO ]] && echo "Retrieving files list inside cloud and on the local machine, then finding the new file to upload"

    # using -p for a little speed-up
    IFS=' ' read -a cloud_deconz_list <<< $(bash "$HELPER" --get-list="$CLOUD_DECONZ" --path="root/${CLOUD_FOLDER_NAME}/${CLOUD_DECONZ}" --name -p --verbose=$v)
    IFS=' ' read -a cloud_homeassistant_list <<< $(bash "$HELPER" --get-list="$CLOUD_HOMEASSISTANT" --path="root/${CLOUD_FOLDER_NAME}/${CLOUD_HOMEASSISTANT}" --name -p --verbose=$v)
    IFS=' ' read -a cloud_pihole_list <<< $(bash "$HELPER" --get-list="$CLOUD_PIHOLE" --path="root/${CLOUD_FOLDER_NAME}/${CLOUD_PIHOLE}" --name -p --verbose=$v)
    IFS=' ' read -a cloud_voultwarden_list <<< $(bash "$HELPER" --get-list="$CLOUD_VAULTWARDEN" --path="root/${CLOUD_FOLDER_NAME}/${CLOUD_VAULTWARDEN}" --name -p --verbose=$v)
    IFS=' ' read -a cloud_secrets_list <<< $(bash "$HELPER" --get-list="$CLOUD_SECRETS" --path="root/${CLOUD_FOLDER_NAME}/${CLOUD_SECRETS}" --name -p --verbose=$v)

    # locals list with at most $1 files
    local local_deconz_list=($(ls -t $DECONZ_LONG_TERM_BACKUP_FOLDER | head -n $keep))
    local local_homeassistant_list=($(ls -t $HASSIO_LONG_TERM_BACKUP_FOLDER | head -n $keep))
    local local_pihole_list=($(ls -t $PIHOLE_LONG_TERM_BACKUP_FOLDER | head -n $keep))
    local local_vaultwarden_list=($(ls -t $VAULTWARDEN_LONG_TERM_BACKUP_FOLDER | head -n $keep))
    local local_secrets_list=($(ls -t $SECRETS_LONG_TERM_BACKUP_FOLDER | head -n $keep))

    # new files to upload
    local new_deconz=()
    for local_elem in "${local_deconz_list[@]}"; do
        local -i found=0
        for cloud_elem in "${cloud_deconz_list[@]}"; do
            if [[ "$local_elem.gpg" == "$cloud_elem" ]]; then
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
            if [[ "$local_elem.gpg" == "$cloud_elem" ]]; then
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
            if [[ "$local_elem.gpg" == "$cloud_elem" ]]; then
                found=1
                break
            fi
        done
        if [[ $found -eq 0 ]]; then
            new_pihole+=("$local_elem")
        fi
    done
    local new_vaultwarden=()
    for local_elem in "${local_vaultwarden_list[@]}"; do
        local -i found=0
        for cloud_elem in "${cloud_voultwarden_list[@]}"; do
            if [[ "$local_elem.gpg" == "$cloud_elem" ]]; then
                found=1
                break
            fi
        done
        if [[ $found -eq 0 ]]; then
            new_vaultwarden+=("$local_elem")
        fi
    done
    local new_secrets=()
    for local_elem in "${local_secrets_list[@]}"; do
        local -i found=0
        for cloud_elem in "${cloud_secrets_list[@]}"; do
            if [[ "$local_elem.gpg" == "$cloud_elem" ]]; then
                found=1
                break
            fi
        done
        if [[ $found -eq 0 ]]; then
            new_secrets+=("$local_elem")
        fi
    done

    [[ $VERBOSE -ge $WARN ]] && echo "${#new_deconz[@]} New for Deconz: $new_deconz"
    [[ $VERBOSE -ge $WARN ]] && echo "${#new_homeassistant[@]} New for HomeAssistant: $new_homeassistant"
    [[ $VERBOSE -ge $WARN ]] && echo "${#new_pihole[@]} New for Pihole: $new_pihole"
    [[ $VERBOSE -ge $WARN ]] && echo "${#new_vaultwarden[@]} New for Vaultwarden: $new_vaultwarden"
    [[ $VERBOSE -ge $WARN ]] && echo "${#new_secrets[@]} New for Secrets: $new_secrets"

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
    for elem in "${new_vaultwarden[@]}"; do
        upload "${VAULTWARDEN_LONG_TERM_BACKUP_FOLDER}/${elem}" "$vaultwarden_id"
    done
    for elem in "${new_secrets[@]}"; do
        upload "${SECRETS_LONG_TERM_BACKUP_FOLDER}/${elem}" "$secrets_id"
    done
    
    [[ $VERBOSE -ge $INFO ]] && echo "Upload completed"
}

# $1 string of type id,name
delete-file () {
    if [[ $# -ne 1 ]]; then
        return 1
    fi
    IFS="," read -a temp <<< "$1"
    gdrive files delete "${temp[0]}" > /dev/null

    [[ $VERBOSE -ge $INFO ]] && echo "Deleted ${temp[1]}"
}

# $1 file to keep
remove-drive-old-files () {

    if [[ $# -ne 1 ]]; then
        [[ $VERBOSE -ge $ERROR ]] && echo "remove-drive-old-files wrong number of parameters"
        return 0
    fi

    local keep=$1

    [[ $VERBOSE -ge $INFO ]] && echo "Checking variables"

    # if [[ -z $GDRIVE_ACCOUNT ]]; then
    #     [[ $VERBOSE -ge $ERROR ]] && echo "GDRIVE_ACCOUNT variable is empty or not set"
    #     exit 0
    # fi
    # if [[ -z $GDRIVE_CREDENTIALS_PATH ]]; then
    #     [[ $VERBOSE -ge $ERROR ]] && echo "GDRIVE_CREDENTIALS_PATH variable is empty or not set"
    #     exit 0
    # fi
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
    if [[ -z $VAULTWARDEN_LONG_TERM_BACKUP_FOLDER ]]; then
        [[ $VERBOSE -ge $ERROR ]] && echo "VAULTWARDEN_LONG_TERM_BACKUP_FOLDER variable is empty or not set"
        exit 0
    fi
    if [[ -z $SECRETS_LONG_TERM_BACKUP_FOLDER ]]; then
        [[ $VERBOSE -ge $ERROR ]] && echo "SECRETS_LONG_TERM_BACKUP_FOLDER variable is empty or not set"
        exit 0
    fi



    if [[ $VERBOSE -ge $DEBUG ]]; then
        local v=3
    else
        local v=0
    fi

    [[ $VERBOSE -ge $INFO ]] && echo "Done cheching variables"

    # gdrive account import "$GDRIVE_CREDENTIALS_PATH"
    # gdrive account list
    # gdrive account switch "$GDRIVE_ACCOUNT"

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
    local vaultwarden_id=$(bash "$HELPER" --get-id="$CLOUD_VAULTWARDEN" --path="root/${CLOUD_FOLDER_NAME}/${CLOUD_VAULTWARDEN}" --verbose=$v)
    if [[ -z "$vaultwarden_id" ]]; then
        vaultwarden_id=$(gdrive files mkdir --parent "$root_directory_id" --print-only-id "$CLOUD_VAULTWARDEN")
    fi
    local secrets_id=$(bash "$HELPER" --get-id="$CLOUD_SECRETS" --path="root/${CLOUD_FOLDER_NAME}/${CLOUD_SECRETS}" --verbose=$v)
    if [[ -z "$secrets_id" ]]; then
        secrets_id=$(gdrive files mkdir --parent "$root_directory_id" --print-only-id "$CLOUD_SECRETS")
    fi

    [[ $VERBOSE -ge $INFO ]] && echo "Deconz cloud folder id: $deconz_id"
    [[ $VERBOSE -ge $INFO ]] && echo "HomeAssistant cloud folder id: $homeassistant_id"
    [[ $VERBOSE -ge $INFO ]] && echo "Pihole cloud folder id: $pihole_id"
    [[ $VERBOSE -ge $INFO ]] && echo "Vaultwarden cloud folder id: $vaultwarden_id"
    [[ $VERBOSE -ge $INFO ]] && echo "Secrets cloud folder id: $secrets_id"

    [[ $VERBOSE -ge $INFO ]] && echo "Retrieving files list inside cloud and then remove the oldest ones"

    # complete list
    IFS=' ' read -a cloud_deconz_list_all <<< $(bash "$HELPER" --get-list="$CLOUD_DECONZ" --path="root/${CLOUD_FOLDER_NAME}/${CLOUD_DECONZ}" -p --verbose=$v)
    IFS=' ' read -a cloud_homeassistant_list_all <<< $(bash "$HELPER" --get-list="$CLOUD_HOMEASSISTANT" --path="root/${CLOUD_FOLDER_NAME}/${CLOUD_HOMEASSISTANT}" -p --verbose=$v)
    IFS=' ' read -a cloud_pihole_list_all <<< $(bash "$HELPER" --get-list="$CLOUD_PIHOLE" --path="root/${CLOUD_FOLDER_NAME}/${CLOUD_PIHOLE}" -p --verbose=$v)
    IFS=' ' read -a cloud_voultwarden_list_all <<< $(bash "$HELPER" --get-list="$CLOUD_VAULTWARDEN" --path="root/${CLOUD_FOLDER_NAME}/${CLOUD_VAULTWARDEN}" -p --verbose=$v)
    IFS=' ' read -a cloud_secrets_list_all <<< $(bash "$HELPER" --get-list="$CLOUD_SECRETS" --path="root/${CLOUD_FOLDER_NAME}/${CLOUD_SECRETS}" -p --verbose=$v)

    # just $1 new files

    IFS=' ' read -a cloud_deconz_list_to_keep <<< $(bash "$HELPER" --get-list="$CLOUD_DECONZ" --path="root/${CLOUD_FOLDER_NAME}/${CLOUD_DECONZ}" -p --options "--order-by;"createdTime\ desc";--max;$keep" --verbose=$v)
    IFS=' ' read -a cloud_homeassistant_list_to_keep <<< $(bash "$HELPER" --get-list="$CLOUD_HOMEASSISTANT" --path="root/${CLOUD_FOLDER_NAME}/${CLOUD_HOMEASSISTANT}" -p --options "--order-by;"createdTime\ desc";--max;$keep" --verbose=$v)
    IFS=' ' read -a cloud_pihole_list_to_keep <<< $(bash "$HELPER" --get-list="$CLOUD_PIHOLE" --path="root/${CLOUD_FOLDER_NAME}/${CLOUD_PIHOLE}" -p --options "--order-by;"createdTime\ desc";--max;$keep" --verbose=$v)
    IFS=' ' read -a cloud_voultwarden_list_to_keep <<< $(bash "$HELPER" --get-list="$CLOUD_VAULTWARDEN" --path="root/${CLOUD_FOLDER_NAME}/${CLOUD_VAULTWARDEN}" -p --options "--order-by;"createdTime\ desc";--max;$keep" --verbose=$v)
    IFS=' ' read -a cloud_secrets_list_to_keep <<< $(bash "$HELPER" --get-list="$CLOUD_SECRETS" --path="root/${CLOUD_FOLDER_NAME}/${CLOUD_SECRETS}" -p --options "--order-by;"createdTime\ desc";--max;$keep" --verbose=$v)


    # find older files to delete
    local del_deconz=()
    for elem in "${cloud_deconz_list_all[@]}"; do
        local -i found=0
        for keep_elem in "${cloud_deconz_list_to_keep[@]}"; do
            if [[ "$elem" == "$keep_elem" ]]; then
                found=1
                break
            fi
        done
        if [[ $found -eq 0 ]]; then
            del_deconz+=("$elem")
        fi
    done
    local del_homeassistant=()
    for elem in "${cloud_homeassistant_list_all[@]}"; do
        local -i found=0
        for keep_elem in "${cloud_homeassistant_list_to_keep[@]}"; do
            if [[ "$elem" == "$keep_elem" ]]; then
                found=1
                break
            fi
        done
        if [[ $found -eq 0 ]]; then
            del_homeassistant+=("$elem")
        fi
    done
    local del_pihole=()
    for elem in "${cloud_pihole_list_all[@]}"; do
        local -i found=0
        for keep_elem in "${cloud_pihole_list_to_keep[@]}"; do
            if [[ "$elem" == "$keep_elem" ]]; then
                found=1
                break
            fi
        done
        if [[ $found -eq 0 ]]; then
            del_pihole+=("$elem")
        fi
    done
    local del_voultwarden=()
    for elem in "${cloud_voultwarden_list_all[@]}"; do
        local -i found=0
        for keep_elem in "${cloud_voultwarden_list_to_keep[@]}"; do
            if [[ "$elem" == "$keep_elem" ]]; then
                found=1
                break
            fi
        done
        if [[ $found -eq 0 ]]; then
            del_voultwarden+=("$elem")
        fi
    done
    local del_secrets=()
    for elem in "${cloud_secrets_list_all[@]}"; do
        local -i found=0
        for keep_elem in "${cloud_secrets_list_to_keep[@]}"; do
            if [[ "$elem" == "$keep_elem" ]]; then
                found=1
                break
            fi
        done
        if [[ $found -eq 0 ]]; then
            del_secrets+=("$elem")
        fi
    done

    [[ $VERBOSE -ge $INFO ]] && echo "${#cloud_deconz_list_all[@]} Clouds Deconz: $cloud_deconz_list_all"
    [[ $VERBOSE -ge $INFO ]] && echo "${#cloud_deconz_list_to_keep[@]} Clouds Deconz to keep: $cloud_deconz_list_to_keep"
    [[ $VERBOSE -ge $INFO ]] && echo "${#cloud_homeassistant_list_all[@]} Clouds HomeAssistant: $cloud_homeassistant_list_all"
    [[ $VERBOSE -ge $INFO ]] && echo "${#cloud_homeassistant_list_to_keep[@]} Clouds HomeAssistant to keep: $cloud_homeassistant_list_to_keep"
    [[ $VERBOSE -ge $INFO ]] && echo "${#cloud_pihole_list_all[@]} Clouds Pihole: $cloud_pihole_list_all"
    [[ $VERBOSE -ge $INFO ]] && echo "${#cloud_pihole_list_to_keep[@]} Clouds Pihole to keep: $cloud_pihole_list_to_keep"
    [[ $VERBOSE -ge $INFO ]] && echo "${#cloud_voultwarden_list_all[@]} Clouds Vaultwarden: $cloud_voultwarden_list_all"
    [[ $VERBOSE -ge $INFO ]] && echo "${#cloud_voultwarden_list_to_keep[@]} Clouds Vaultwarden to keep: $cloud_voultwarden_list_to_keep"
    [[ $VERBOSE -ge $INFO ]] && echo "${#cloud_secrets_list_all[@]} Clouds Secrets: $cloud_secrets_list_all"
    [[ $VERBOSE -ge $INFO ]] && echo "${#cloud_secrets_list_to_keep[@]} Clouds Secrets to keep: $cloud_secrets_list_to_keep"

    [[ $VERBOSE -ge $WARN ]] && echo "${#del_deconz[@]} to be deleted for Deconz: $del_deconz"
    [[ $VERBOSE -ge $WARN ]] && echo "${#del_homeassistant[@]} to be deleted for HomeAssistant: $del_homeassistant"
    [[ $VERBOSE -ge $WARN ]] && echo "${#del_pihole[@]} to be deleted for Pihole: $del_pihole"
    [[ $VERBOSE -ge $WARN ]] && echo "${#del_voultwarden[@]} to be deleted for Vaultwarden: $del_voultwarden"
    [[ $VERBOSE -ge $WARN ]] && echo "${#del_secrets[@]} to be deleted for Secrets: $del_secrets"

    # now we have a list for all folders of "id,name"
    for elem in "${del_deconz[@]}"; do
        delete-file $elem
    done
    for elem in "${del_homeassistant[@]}"; do
        delete-file $elem
    done
    for elem in "${del_pihole[@]}"; do
        delete-file $elem
    done
    for elem in "${del_voultwarden[@]}"; do
        delete-file $elem
    done
    for elem in "${del_secrets[@]}"; do
        delete-file $elem
    done

    [[ $VERBOSE -ge $INFO ]] && echo "Completed deleting old files, now at most $1 files are on the drive for each service"
}

[[ $VERBOSE -ge $INFO ]] && echo "Upload script started"

default $FILES_TO_KEEP

remove-drive-old-files $FILES_TO_KEEP

bash "$HELPER" -i --verbose=$v

exit 0