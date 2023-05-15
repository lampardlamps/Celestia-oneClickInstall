# this code installs all the necessary components for starting a light node on Celestia network, and set up the systemD
# config. It can be easily adopted for all the other node types and networks within the Celestia family.

# define the node version and network
VER=v0.9.3
NETWORK=blockspacerace
CORE_IP=https://rpc-blockspacerace.pops.one

# prompt the user to start from a specific line, this is to avoid having to go through
# all previous lines again if one step in the middle breaks down
read -p "Would you like to start executing from a specific line? [y/n] " start_line
if [[ "$start_line" == "y" ]]; then
    read -p "Please enter the line number you would like to start from: " line_number
    if [[ "$line_number" =~ ^[0-9]+$ ]]; then
        echo "Starting execution from line $line_number"
        sed -n "${line_number},$ p" "${BASH_SOURCE[0]}" | VER=$VER NETWORK=$NETWORK CORE_IP=$CORE_IP bash  # $VER etc are input here to prevent their values being lost when the script is executed from a certain line.
        exit
    else
        echo "Invalid input: please enter a number."
    fi
fi

# continue executing the script from the beginning
echo "Starting script from the beginning..."

# install dependencies
sudo apt update && sudo apt upgrade -y
sudo apt install curl tar wget clang pkg-config libssl-dev jq build-essential git make ncdu -y

# install go
ver="1.20.2"
cd $HOME
wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
rm "go$ver.linux-amd64.tar.gz"

# add go to PATH
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile
source $HOME/.bash_profile

# check go version
go version

# add continue or exit option depending on the output
read -n 1 -s -r -p "Check the go version, if correct press Enter to continue, else Escape to exit..."

# Check user input
case "$REPLY" in
    '') # User pressed Enter
        echo "Continuing..."
        # Add your code here
        ;;
    $'\e') # User pressed Escape
        echo "Exiting..."
        exit 1
        ;;
    *) # Unknown input
        echo "Unknown input, exiting..."
        exit 1
        ;;
esac

go version
# install celestia node:
cd $HOME
sudo rm -rf celestia-node
git clone https://github.com/celestiaorg/celestia-node.git
cd celestia-node
echo "now checking out $VER..."
git checkout tags/$VER
# need to give admin permisson, otherwise build might fail
make build
sudo make install
make cel-key

# check celestia version to decide continue or not:
celestia version
read -n 1 -s -r -p "Check the celestia version, if correct press Enter to continue, else Escape to exit..."
# Check user input
case "$REPLY" in
    '') # User pressed Enter
        echo "Continuing..."
        # Add your code here
        ;;
    $'\e') # User pressed Escape
        echo "Exiting..."
        exit 1
        ;;
    *) # Unknown input
        echo "Unknown input, exiting..."
        exit 1
        ;;
esac

# do you need to generate keys? If so input your keyname, else continue
read -p "Do you want to generate a new key? (Y/N): " -r
echo    # move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "User entered 'yes'"
    read -p "Please enter a string and press Enter: " key_name
    echo "User entered: $key_name"

    # generate key with user input
    ./cel-key add $key_name --keyring-backend test --node.type light --p2p.network $NETWORK
    echo
    read -p "Save the mnemonic phrases, and then press Enter to continue..."
else
    echo "User entered 'no'"
    read -p "Please enter the name of the key you would like to use and press Enter: " key_name
    echo "User entered: $key_name"
fi

# initiate the light node client
celestia light init --p2p.network $NETWORK
sleep 3s
# configure the node for systemD start
echo "Now setting up the systemD config using key name $key_name"
sudo tee <<EOF >/dev/null /etc/systemd/system/celestia-lightd.service
[Unit]
Description=celestia-lightd Light Node
After=network-online.target

[Service]
User=$USER
ExecStart=celestia light start --core.ip $CORE_IP --p2p.network $NETWORK --keyring.accname $key_name --metrics.tls=false --metrics --metrics.endpoint otel.celestia.tools:4318 --gateway --gateway.addr localhost --gateway.port 26659
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

# start the node using systemD
sudo systemctl stop celestia-lightd
sudo systemctl daemon-reload
sudo systemctl enable celestia-lightd
sudo systemctl start celestia-lightd




