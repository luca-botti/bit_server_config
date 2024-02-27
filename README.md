# Instruction for deploy the server

This instructions will deploy a copy of my personal home server and could be used by others with just their backups of the various installed services (HomeAssistant, Deconz and Pihole).

Starting from a windows terminal:

0.  if the file at `$USERFOLDER/.ssh/id-rsa` is not present, execute this to create the fingerprint ( <your_comment> could be anything, but normally is used an email for identification ).

    ```powershell
    ssh-keygen -t rsa -b 4096 -C "<your_comment>"
    ```
1.  execute (change <user> and <host> to the user and the address, or hostname, of the server), will require the password of the server

    ```powershell
    cat ~/.ssh/id_rsa.pub | ssh "<user>@<host>" "mkdir -p ~/.ssh && touch ~/.ssh/authorized_keys && chmod -R go= ~/.ssh && cat >> ~/.ssh/authorized_keys"
    ```
2.  then execute this to log on the server (change <user> and <host> to the user and the address, or hostname, of the server)

    ```powershell
    ssh <user>@<host>
    ```

now you should be inside the terminal of the server

3.  execute this list of commands (substitute <email> with your email, <user> with your username for git, and <user> with the user logged in the server):

    ```bash
    sudo apt update && \
    sudo apt full-upgrade -y && \
    sudo apt install git -y && \
    git config --global user.email '<email>' && \
    git config --global user.name '<user>' && \
    cd / && \
    sudo mkdir /bit_server && \
    sudo chown -R '<user>' /bit_server/ && \
    cd /bit_server/ && \
    git clone https://github.com/luca-botti/bit_server_config.git . && \
    sudo bash other_files/scripts/install.sh && \
    newgrp docker
    ```

    this will clone this repository and instaling any necessary software

4. now we will need to get all the backups, we will need the backup of:

    - home-assistant
    - deconz
    - pihole
    - secrets

5. for restoring the secrets we just copy the `secrets` folder that's inside the backup to `/bit_server/other_files`

6. then we need to restore the backup of homeassistant, in order to do so, we just need to decompress the homeassistant backup and copy all the files inside `/bit_server/homeassistant/config/`
    
7. start all docker containers executing

    ```bash
    sudo bash other_files/scripts/update.sh
    ```

8. restoring deConz backup

    1. go to [deconz web page](about:blank) (the true address will be thee host address of the server and the port of the service setted using the secrets .env files)
    2. register using credentials found inside `secrets.txt`
    3. skip adding lights
    4. go to *Menù (up-left 3 lines) -> Gateway -> Backup options -> load backup*
    5. load the backup file (could be necessary that you have download the backup file from the server to your local machine)
    6. wait to finish the procedure
    7. click a button on all remotes and move the motion sensor until it will show up under *Menù -> Sensors*
    8. (bonus) check everything is fine using vncViewer app (all info in secrets files)

9. restoring pihole backup

    1. go to [pihole web page](about:blank) (the true address will be thee host address of the server and the port of thee service setted using the secrets .env files)
    2. insert the password and login
    3. click on *>>* on the upper-left corner if the menù is not extended
    4. go to *settings -> teleporter -> restore*
    5. load the backup file



Now the file tree inside the base folder should look like this:

    `tree -L 2`

    bit_server
    ├── backups
    │   ├── deconz
    │   ├── homeassistant
    │   ├── pihole
    │   └── secrets
    ├── caddy
    │   ├── Caddyfile
    │   └── data
    ├── deconz
    │   ├── config.ini
    │   ├── devices
    │   ├── otau
    │   ├── vnc
    │   ├── zcldb.txt
    │   └── zll.db
    ├── docker-compose.yaml
    ├── homeassistant
    │   └── config
    ├── LICENSE
    ├── other_files
    │   ├── info_files
    │   ├── scripts
    │   └── secrets
    ├── pihole
    │   ├── backups
    │   ├── etc-dnsmasq.d
    │   ├── etc-pihole
    │   └── lighttpd
    └── README.md


And if the router has the forwarding table and the dynamic DNS resolver activated, everything should work correctly.



