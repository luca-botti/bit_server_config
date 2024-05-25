# TODO

 - older backup remove polocy


# Instruction for deploy the server

This instructions will deploy a copy of my personal home server and could be used by others with just their backups of the various installed services (HomeAssistant, Deconz and Pihole).

Starting from a windows terminal:

0.  if the file at `$USERFOLDER/.ssh/id-rsa` is not present, execute this to create the fingerprint ( *your_comment* could be anything, but normally is used an email for identification ).

    ```powershell
    ssh-keygen -t rsa -b 4096 -C "<your_comment>"
    ```
1.  execute (change *user* and *host* to the user and the address, or hostname, of the server), will require the password of the server

    ```powershell
    cat ~/.ssh/id_rsa.pub | ssh "<user>@<host>" "mkdir -p ~/.ssh && touch ~/.ssh/authorized_keys && chmod -R go= ~/.ssh && cat >> ~/.ssh/authorized_keys"
    ```
2.  then execute this to log on the server (change *user* and *host* to the user and the address, or hostname, of the server)

    ```powershell
    ssh <user>@<host>
    ```

now you should be inside the terminal of the server

3.  execute this list of commands (substitute *email* with your email, *git-user* with your username for git, and *user* with the user logged in the server):

    ```bash
    sudo apt update && \
    sudo apt full-upgrade -y && \
    sudo apt install git -y && \
    git config --global user.email '<email>' && \
    git config --global user.name '<git-user>' && \
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
    - vaultwarden

5. for all of them we will need to decrypt them, in order to this we just need to use this command using the chosen password:

    ```bash
    gpg --batch --output <output-filename> --passphrase <password> --decrypt <input-filename>.gpg
    ```

6. for restoring the secrets we just copy the `secrets` folder that's inside the backup to `/bit_server/other_files`

7. then we need to restore the backup of homeassistant, in order to do so, we just need to decompress the homeassistant backup and copy all the files inside `/bit_server/homeassistant/config/`

8. before starting all the container we need also to restore the vaultwarden backup [wiki page](https://github.com/dani-garcia/vaultwarden/wiki/Backing-up-your-vault#restoring-backup-data), to do so, we just need to decompress the vaultwarden tar archive and copy all the files inside `/bit_server/vaultwarden/data/`
    
9. start all docker containers executing

    ```bash
    sudo bash other_files/scripts/update.sh
    ```

10. restoring deConz backup

    1. go to [deconz web page](about:blank) (the true address will be thee host address of the server and the port of the service setted using the secrets .env files)
    2. register using credentials found inside `secrets.txt`
    3. skip adding lights
    4. go to ***Menù (up-left 3 lines) -> Gateway -> Backup options -> load backup***
    5. load the backup file (could be necessary that you have download the backup file from the server to your local machine)
    6. wait to finish the procedure
    7. click a button on all remotes and move the motion sensor until it will show up under ***Menù -> Sensors***
    8. (bonus) check everything is fine using vncViewer app (all info in secrets files)

11. restoring pihole backup

    1. go to [pihole web page](about:blank) (the true address will be thee host address of the server and the port of thee service setted using the secrets .env files)
    2. insert the password and login
    3. click on ***>>*** on the upper-left corner if the menù is not extended
    4. go to ***settings -> teleporter -> restore***
    5. load the backup file 

12. then for activate the automatic backup we need to configure the gdrive cli application already installed using the account credentials that can be found in `secrets`, just run (*file_name* is the exported account token from gdrive)

    ```bash
    gdrive account import /bit_server/other_files/secrets/others/<file-name>.tar
    ```

13. (OPTIONAL) for retrieving the local_key for local-tuya execute this command for obatin the device.json with all tuya device informations [tinyTuya](https://pypi.org/project/tinytuya/):

    ```bash
    sudo apt install python3 python3-pip python3-full -y
    python3 -m venv .venv
    source .venv/bin/activate
    pip install tinytuya
    ```

    the next command will prompt for the key in your iot tuya platform and a device id as described on the tinytuya web page (using scan hadn't work for me).

     ```bash
    python -m tinytuya wizard
    ```

    then you should have the device.json filewith all the data needed. <br>
    you can exit the venv using:

     ```bash
    deactivate
    ```



Now the dir tree inside the base folder should look like this:

    `tree -L 2 -d`

    bit_server
    ├── backups
    │   ├── deconz
    │   ├── homeassistant
    │   ├── pihole
    │   ├── secrets
    │   └── vaultwarden
    ├── caddy
    │   ├── config
    │   └── data
    ├── deconz
    │   ├── devices
    │   ├── otau
    │   └── vnc
    ├── homeassistant
    │   └── config
    ├── other_files
    │   ├── info_files
    │   ├── scripts
    │   └── secrets
    ├── pihole
    │   ├── backups
    │   ├── etc-dnsmasq.d
    │   ├── etc-pihole
    │   └── lighttpd
    ├── unbound
    │   └── config
    └── vaultwarden
        └── data


And if the router has the forwarding table and the dynamic DNS resolver activated, everything should work correctly.

For the fritz!box:
- URL di aggiornamento (to be copied as it is): `https://www.duckdns.org/update?domains=<domain>&token=<pass>&ip=<ipaddr>&ipv6=<ip6addr>`
- Nome di dominio (substitute <> values): `<subdomain1>.duckdns.org,<subdomain2>.duckdns.org`
- Nome utente: none
- Password (substitute <> values): `<duck-dns-token>`

The forwarding table will have to open all the ports use from serveces that needs to be accessed from a remote origin.


