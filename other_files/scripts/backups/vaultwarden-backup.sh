#!/bin/bash

QUIET=0     # DEBUG=0 quiet
ERROR=1     # DEBUG=1 only error <- default
WARN=2      # DEBUG=2 error and some info
INFO=3      # DEBUG=3 print all
DEBUG=4     # debug=4 will set the -x parameter and disable all manual echo

VERBOSE=${VERBOSE_OVERRIDE:-1}

cleanExit() {
    [[ $VERBOSE -ge $WARN ]] && echo "Vaultwarden auto backup script - ENDING ..."
}

trap cleanExit EXIT # setting exit function

[[ $VERBOSE -ge $INFO ]] && echo "Vaultwarden auto backup script - STARTING ..."

DATE=${DATE_OVERRIDE:-$(date +"%Y-%m-%d-%H-%M-%S")}

[[ $VERBOSE -ge $INFO ]] && echo "Checking input variables"

if [[ -z $BACKUP_FOLDER ]]; then
    [[ $VERBOSE -ge $ERROR ]] && echo "BACKUP_FOLDER variable is empty or not set"
    exit 0
fi

if [[ -z $LONG_TERM_BACKUP_FOLDER ]]; then
    [[ $VERBOSE -ge $ERROR ]] && echo "LONG_TERM_BACKUP_FOLDER variable is empty or not set"
    exit 0
fi

if [[ -z $TEMP_FOLDER ]]; then
    [[ $VERBOSE -ge $ERROR ]] && echo "TEMP_FOLDER variable is empty or not set"
    exit 0
fi

if [[ -z $IGNORE_LIST ]]; then
    [[ $VERBOSE -ge $ERROR ]] && echo "IGNORE_LIST variable is empty or not set"
    exit 0
fi

IFS=':' read -a IGNORE_LIST <<< "$IGNORE_LIST"

if [[ -z $SQLITE_DB_PATH ]]; then
    [[ $VERBOSE -ge $ERROR ]] && echo "SQLITE_DB_PATH variable is empty or not set"
    exit 0
fi

[[ $VERBOSE -ge $INFO ]] && echo "All variables inserted"
[[ $VERBOSE -ge $INFO ]] && echo "Creating backup of vaultwarden"

# echo ${IGNORE_LIST[@]}

mkdir "$TEMP_FOLDER/vaultwarden"

sqlite3 "$SQLITE_DB_PATH" ".backup '$TEMP_FOLDER/vaultwarden/db-$DATE.sqlite3'"
sleep 10

for x in $BACKUP_FOLDER/*; do
    basepath=$(basename $x)
    # echo $basepath
    found=false
    for i in "${IGNORE_LIST[@]}"; do
        # echo "$basepath =~ $i"
        if [[ $basepath =~ $i ]]; then
            found=true
            break
        fi
    done
    if [[ $found == true ]]; then
        [[ $VERBOSE -ge $INFO ]] && echo "$x ##IGNORED##"
    else
        [[ $VERBOSE -ge $INFO ]] && echo "copying $basepath"

        if [[ -d $x ]]; then
            cp -R "$x" "$TEMP_FOLDER/vaultwarden"
        else
            cp "$x" "$TEMP_FOLDER/vaultwarden"
        fi
    fi
done

[[ $VERBOSE -ge $INFO ]] && echo "Compressing all files"

tar -c -f "vaultwarden-$DATE.tar" -C "$TEMP_FOLDER" "vaultwarden"
mv "vaultwarden-$DATE.tar" "$LONG_TERM_BACKUP_FOLDER"

[[ $VERBOSE -ge $INFO ]] && echo "cleaning temporary files"
rm -f -r "$TEMP_FOLDER"/*
[[ $VERBOSE -ge $INFO ]] && echo "done cleaning temporary files"
