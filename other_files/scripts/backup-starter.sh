#!/bin/bash

(source /bit_server/other_files/secrets/.backupSecrets.env && V=3 U=0 bash /bit_server/other_files/scripts/backups/backup.sh) | while IFS= read -r line; do printf '[%s] -  %s\n' "$(date +"%a %d-%b-%Y--%H:%M:%S:%N")" "$line"; done >> /bit_server/other_files/logs/script_logs/backup_script.log 2>&1