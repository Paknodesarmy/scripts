#!/bin/bash

echo "   ___      _        __          _              _                        "
echo "  / _ \__ _| | __ /\ \ \___   __| | ___  ___   /_\  _ __ _ __ ___  _   _ "
echo " / /_)/ _  | |/ //  \/ / _ \ / _  |/ _ \/ __| //_\\| '__| '_  _ \| | | |"
echo "/ ___/ (_| |   </ /\  / (_) | (_| |  __/\__ \/  _  \ |  | | | | | | |_| |"
echo "\/    \__,_|_|\_\_\/_/ \___/ \__,_|\___||___/\_/ \_/_|  |_| |_| |_|\__, |"
echo "                                                                   |___/ "

# Wait for 2 seconds
sleep 2

# Install dependencies for building from source
echo -e "\e[1m\e[32m1. Updating packages... \e[0m" && sleep 1
sudo apt-get update && sudo apt-get upgrade -y

# Install Go
echo -e "\e[1m\e[32m2. Installing Go... \e[0m" && sleep 1
cd $HOME && \
ver="1.22.0" && \
wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz" && \
sudo rm -rf /usr/local/go && \
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz" && \
rm "go$ver.linux-amd64.tar.gz" && \
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> ~/.bash_profile && \
source ~/.bash_profile && \
go version

# Install Rust
echo -e "\e[1m\e[32m3. Installing Rust... \e[0m" && sleep 1
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
. "$HOME/.cargo/env"

# Set environment variables
echo -e "\e[1m\e[32m4. Setting environment variables... \e[0m" && sleep 1
read -p "Enter json-rpc (default https://jsonrpc.0g-test.paknodesarmy.xyz): " BLOCKCHAIN_RPC_ENDPOINT
BLOCKCHAIN_RPC_ENDPOINT=${BLOCKCHAIN_RPC_ENDPOINT:-"https://jsonrpc.0g-test.paknodesarmy.xyz"}
echo "Current json-rpc: $BLOCKCHAIN_RPC_ENDPOINT"

ENR_ADDRESS=$(wget -qO- eth0.me)
echo "export ENR_ADDRESS=${ENR_ADDRESS}" >> ~/.bash_profile
echo 'export ZGS_LOG_DIR="$HOME/0g-storage-node/run/log"' >> ~/.bash_profile
echo 'export ZGS_LOG_SYNC_BLOCK="802"' >> ~/.bash_profile
echo 'export LOG_CONTRACT_ADDRESS="0x8873cc79c5b3b5666535C825205C9a128B1D75F1"' >> ~/.bash_profile
echo 'export MINE_CONTRACT="0x85F6722319538A805ED5733c5F4882d96F1C7384"' >> ~/.bash_profile
echo "export BLOCKCHAIN_RPC_ENDPOINT=\"$BLOCKCHAIN_RPC_ENDPOINT\"" >> ~/.bash_profile

source ~/.bash_profile

echo -e "\n\033[31mCHECK YOUR STORAGE NODE VARIABLES\033[0m\n\nLOG_CONTRACT_ADDRESS: $LOG_CONTRACT_ADDRESS\nMINE_CONTRACT: $MINE_CONTRACT\nZGS_LOG_SYNC_BLOCK: $ZGS_LOG_SYNC_BLOCK\nBLOCKCHAIN_RPC_ENDPOINT: $BLOCKCHAIN_RPC_ENDPOINT\n\n"

# Prompt for Ethereum wallet private key
echo -e "\e[1m\e[32m5. Enter your Ethereum wallet private key: \e[0m" && sleep 1
read -sp "Private key: " PRIVATE_KEY && echo

# Validate private key input
if [[ -z "$PRIVATE_KEY" ]]; then
    echo -e "\n\033[31mERROR: Ethereum wallet private key is required!\033[0m"
    exit 1
fi

# Display loading message
echo -e "Please wait \e[1m\e[33m⠋\e[0m" && sleep 1 && echo -e "Please wait \e[1m\e[33m⠙\e[0m" && sleep 1 && echo -e "Please wait \e[1m\e[33m⠹\e[0m" && sleep 1 && echo -e "Please wait \e[1m\e[33m⠸\e[0m" && sleep 1 && echo -e "Please wait \e[1m\e[33m⠼\e[0m" && sleep 1 && echo -e "Please wait \e[1m\e[33m⠴\e[0m" && sleep 1 && echo -e "Please wait \e[1m\e[33m⠦\e[0m" && sleep 1 && echo -e "Please wait \e[1m\e[33m⠧\e[0m" && sleep 1 && echo -e "Please wait \e[1m\e[33m⠇\e[0m" && sleep 1 && echo -e "Please wait \e[1m\e[33m⠏\e[0m"

# Check RPC connection
echo -e "\e[1m\e[32m6. Checking RPC connection... \e[0m" && sleep 1
curl -s -X POST $BLOCKCHAIN_RPC_ENDPOINT -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' | jq -r '.result' | xargs printf "%d\n"

# Download binary
echo -e "\e[1m\e[32m7. Downloading and building binaries... \e[0m" && sleep 1
cd $HOME
git clone https://github.com/0glabs/0g-storage-node.git
cd $HOME/0g-storage-node
git stash
git tag -d v0.3.3
git fetch --all --tags
git checkout 2a2688d2c34a1e9480239e17b626912370662dcc
git submodule update --init
sudo apt install -y cargo
cargo build --release

# Update node configuration
echo -e "\e[1m\e[32m8. Updating node configuration... \e[0m" && sleep 1
sed -i "
s|^miner_key = \"\"|miner_key = \"$PRIVATE_KEY\"|
s|^\s*#\?\s*network_dir\s*=.*|network_dir = \"network\"|
s|^\s*#\?\s*network_enr_address\s*=.*|network_enr_address = \"$ENR_ADDRESS\"|
s|^\s*#\?\s*network_enr_tcp_port\s*=.*|network_enr_tcp_port = 1234|
s|^\s*#\?\s*network_enr_udp_port\s*=.*|network_enr_udp_port = 1234|
s|^\s*#\?\s*network_libp2p_port\s*=.*|network_libp2p_port = 1234|
s|^\s*#\?\s*network_discovery_port\s*=.*|network_discovery_port = 1234|
s|^\s*#\s*rpc_listen_address\s*=.*|rpc_listen_address = \"0.0.0.0:5678\"|
s|^\s*#\s*rpc_listen_address_admin\s*=.*|rpc_listen_address_admin = \"0.0.0.0:5679\"|
s|^\s*#\?\s*rpc_enabled\s*=.*|rpc_enabled = true|
s|^\s*#\?\s*db_dir\s*=.*|db_dir = \"db\"|
s|^\s*#\?\s*log_config_file\s*=.*|log_config_file = \"log_config\"|
s|^\s*#\?\s*log_directory\s*=.*|log_directory = \"log\"|
s|^\s*#\?\s*network_boot_nodes\s*=.*|network_boot_nodes = \[\"/ip4/54.219.26.22/udp/1234/p2p/16Uiu2HAmTVDGNhkHD98zDnJxQWu3i1FL1aFYeh9wiQTNu4pDCgps\",\"/ip4/52.52.127.117/udp/1234/p2p/16Uiu2HAkzRjxK2gorngB1Xq84qDrT4hSVznYDHj6BkbaE4SGx9oS\",\"/ip4/18.167.69.68/udp/1234/p2p/16Uiu2HAm2k6ua2mGgvZ8rTMV8GhpW71aVzkQWy7D37TTDuLCpgmX\"]|
s|^\s*#\?\s*log_contract_address\s*=.*|log_contract_address = \"$LOG_CONTRACT_ADDRESS\"|
s|^\s*#\?\s*mine_contract_address\s*=.*|mine_contract_address = \"$MINE_CONTRACT\"|
s|^\s*#\?\s*log_sync_start_block_number\s*=.*|log_sync_start_block_number = $ZGS_LOG_SYNC_BLOCK|
s|^\s*#\?\s*blockchain_rpc_endpoint\s*=.*|blockchain_rpc_endpoint = \"$BLOCKCHAIN_RPC_ENDPOINT\"|
" $HOME/0g-storage-node/run/config.toml

# Create systemd service
echo -e "\e[1m\e[32m9. Creating systemd service... \e[0m" && sleep 1
sudo tee /etc/systemd/system/zgs.service > /dev/null <<EOF
[Unit]
Description=ZGS Node
After=network.target

[Service]
User=$USER
WorkingDirectory=$HOME/0g-storage-node/run
ExecStart=$HOME/0g-storage-node/target/release/zgs_node --config $HOME/0g-storage-node/run/config.toml
Restart=on-failure
RestartSec=10
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

# Start the node
echo -e "\e[1m\e[32m10. Starting the node... \e[0m" && sleep 1
sudo systemctl daemon-reload
sudo systemctl enable zgs
sudo systemctl start zgs
sudo systemctl status zgs

# Instructions for logs
echo -e "\e[1m\e[32m11. Show logs by date... \e[0m"
echo "Check the logs file: ls -lt $ZGS_LOG_DIR"
echo "Full logs command: tail -f ~/0g-storage-node/run/log/zgs.log.\$(TZ=UTC date +%Y-%m-%d)"
echo "tx_seq-only logs command: tail -f ~/0g-storage-node/run/log/zgs.log.\$(TZ=UTC date +%Y-%m-%d) | grep tx_seq:"
