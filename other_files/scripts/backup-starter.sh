#!/bin/bash

(source /bit_server/other_files/secrets/.backupSecrets.env && DBG=0 bash /bit_server/other_files/scripts/backups/backup.sh)