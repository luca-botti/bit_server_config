#!/bin/bash

USER="$LOGNAME" 

cd /bit_server/

sudo apt update
sudo apt full-upgrade -y
sudo apt autoremove -y

echo "Installing Docker..."

# Add Docker's official GPG key:

for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt remove $pkg; done

sudo apt install ca-certificates curl -y
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

# Adding current user to docker group
sudo groupadd -f docker
sudo usermod -aG docker $USER

# Enabling docker to start at boot
sudo systemctl enable docker.service
sudo systemctl enable containerd.service

# unbound log file
sudo touch /bit_server/other_files/scripts/logs/unbound.log
sudo chmod 777 /bit_server/other_files/scripts/logs/unbound.log

echo "Docker installed!"

echo "Installing backup scripts dependencies..."

# backup dependencies

sudo apt install jq cron findutils coreutils diffutils csvkit coreutils gpg sqlite3 -y # used in backup scripts

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y # installing rust
source "$HOME/.cargo/env" # adding rust binaries to PATH

mkdir .gdrive
cd .gdrive/

LATEST=$(curl -Ls -o /dev/null -w %{url_effective} https://github.com/glotlabs/gdrive/releases/latest) # getting latest version code
LATEST=$(basename $LATEST)
curl -Ls -o "gdrive-$LATEST.tar.gz" https://github.com/glotlabs/gdrive/archive/refs/tags/$LATEST.tar.gz # downloading binaries
tar -xzf "gdrive-$LATEST.tar.gz" # extracting them
cd gdrive-$LATEST/ # go inside the dowloaded binaries
sudo chown -R pi .
cargo build --release # building gdrive
sudo cp target/release/gdrive /usr/local/bin # adding gdrive to PATH
cd ../..
sudo rm -r .gdrive #cleaning

#setting script to be executables
sudo chmod u+x /bit_server/other_files/scripts/backup-starter.sh
sudo chmod u+x /bit_server/other_files/scripts/updater.sh

# adding automated update script
sudo crontab -l > sudocrontab 
echo "PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin" >> usercrontab
echo "LD_LIBRARY_PATH=/usr/local/lib" >> usercrontab
echo "0 4 * * 2 /bin/bash -c \"/bit_server/other_files/scripts/updater.sh\"" >> sudocrontab
sudo crontab sudocrontab
sudo rm sudocrontab

# adding automated backup script
crontab -l > usercrontab
echo "PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin" >> usercrontab
echo "LD_LIBRARY_PATH=/usr/local/lib" >> usercrontab
echo "30 3 * * 2 /bin/bash -c \"/bit_server/other_files/scripts/backup-starter.sh\"" >> usercrontab
crontab usercrontab
rm usercrontab

echo "All Done!"