#!/bin/bash

sudo bash /bit_server/other_files/scripts/update.sh | while IFS= read -r line; do printf '[%s] -  %s\n' "$(date +"%a %d-%b-%Y--%H:%M:%S:%N")" "$line"; done >> /bit_server/other_files/scripts/logs/docker.log 2>&1