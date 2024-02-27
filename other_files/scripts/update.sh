#!/bin/bash

#update repository
sudo apt update
sudo apt full-upgrade -y
sudo apt autoremove -y


cd /bit_server/

#update docker
docker compose --env-file other_files/secrets/.dockerSecrets.env --env-file .env down
docker compose --env-file other_files/secrets/.dockerSecrets.env --env-file .env pull
docker compose --env-file other_files/secrets/.dockerSecrets.env --env-file .env build
docker compose --env-file other_files/secrets/.dockerSecrets.env --env-file .env up -d
docker image prune -af
docker volume prune -f