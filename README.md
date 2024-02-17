# bit_server_config
deployable version of the server

To deploy (from a windows pc):

from a windows terminal:

0.  if not present at `$USERFOLDER/.ssh/id-rsa` execute this to create the fingerprint (your_comment could be anything).

    ```powershell
    ssh-keygen -t rsa -b 4096 -C "your_comment"
    ```
1.  execute (change user@host to the user and the address or name of the server)

    ```powershell
    cat ~/.ssh/id_rsa.pub | ssh "user@host" "mkdir -p ~/.ssh && touch ~/.ssh/authorized_keys && chmod -R go= ~/.ssh && cat >> ~/.ssh/authorized_keys"
    ```
2.  like before

    ```powershell
    ssh user@host
    ```

now you should be inside the terminal of the server

3.  execute:

    ```bash
    sudo apt update && sudo apt full-upgrade && sudo apt install git && git config --global user.email luca.botti.00@gmail.com && git config --global user.name luca-botti && cd / && sudo mkdir /bit_server && sudo chown -R pi /bit_server/ && cd /bit_server/ && git clone https://github.com/luca-botti/bit_server_config.git .
    ```

    this will clone this repository and start anything for us


