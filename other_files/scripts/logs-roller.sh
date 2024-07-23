#!/bin/bash

# for deconz to copy logs to the file use the command "docker logs deconz >& /bit_server/other_files/logs/service_logs/deconz.log"

logFiles=()
KEEP_LINE=500

SERVICE_LOG_FOLDER="/bit_server/other_files/logs/service_logs"
VAULTWARDEN_LOG_FILE="vaultwarden.log"
logFiles+=($SERVICE_LOG_FOLDER/$VAULTWARDEN_LOG_FILE)
UNBOUND_LOG_FILE="unbound.log"
logFiles+=($SERVICE_LOG_FOLDER/$UNBOUND_LOG_FILE)
SCRIPT_LOG_FOLDER="/bit_server/other_files/logs/script_logs"
BACKUP_LOG_FILE="backup_script.log"
logFiles+=($SCRIPT_LOG_FOLDER/$BACKUP_LOG_FILE)
UPDATE_LOG_FILE="update_script.log"
logFiles+=($SCRIPT_LOG_FOLDER/$UPDATE_LOG_FILE)


for file in ${logFiles[@]}; do
    echo "$(tail -$KEEP_LINE $file)" > $file
done

