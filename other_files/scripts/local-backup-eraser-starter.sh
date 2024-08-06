#!/bin/bash

(V=3 bash /bit_server/other_files/scripts/local-backup-eraser-starter.sh) | while IFS= read -r line; do printf '[%s] -  %s\n' "$(date +"%a %d-%b-%Y--%H:%M:%S:%N")" "$line"; done >> /bit_server/other_files/logs/script_logs/backup_eraser.log 2>&1