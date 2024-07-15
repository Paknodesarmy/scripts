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
sudo apt-get install -y clang cmake build-essential jq

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
read -p "Enter JSON-RPC endpoint (default: https://jsonrpc.0g-test.paknodesarmy.xyz): " BLOCKCHAIN_RPC_ENDPOINT
BLOCKCHAIN_RPC_ENDPOINT=${BLOCKCHAIN_RPC_ENDPOINT:-https://jsonrpc.0g-test.paknodesarmy.xyz}
echo "Using JSON-RPC endpoint: $BLOCKCHAIN_RPC_ENDPOINT"

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
while true; do
  echo -e "\e[1m\e[32m5. Enter your Ethereum wallet private key: \e[0m" && sleep 1
  read -sp "Private key: " PRIVATE_KEY && echo
  if [ -n "$PRIVATE_KEY" ]; then
    break
  else
    echo "Private key cannot be empty. Please enter your Ethereum wallet private key."
  fi
done

# Display loading message
for i in {1..10}; do
  echo -e "Please wait \e[1m\e[33m⠋\e[0m" && sleep 0.1
  echo -e "Please wait \e[1m\e[33m⠙\e[0m" && sleep 0.1
  echo -e "Please wait \e[1m\e[33m⠹\e[0m" && sleep 0.1
  echo -e "Please wait \e[1m\e[33m⠸\e[0m" && sleep 0.1
  echo -e "Please wait \e[1m\e[33m⠼\e[0m" && sleep 0.1
  echo -e "Please wait \e[1m\e[33m⠴\e[0m" && sleep 0.1
  echo -e "Please wait \e[1m\e[33m⠦\e[0m" && sleep 0.1
  echo -e "Please wait \e[1m\e[33m⠧\e[0m" && sleep 0.1
  echo -e "Please wait \e[1m\e[33m⠇\e[0m" && sleep 0.1
  echo -e "Please wait \e[1m\e[33m⠏\e[0m" && sleep 0.1
done

# Check RPC connection
echo -e "\e[1m\e[32m6. Checking RPC connection... \e[0m" && sleep 1
curl -s -X POST $BLOCKCHAIN_RPC_ENDPOINT -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' | jq -r '.result' | xargs printf "%d\n"

# Download and build binaries
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
s|^#\?miner_key = \".*\"|miner_key = \"$PRIVATE_KEY\"|
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
s|^\s*#\?\s*network_boot_nodes\s*=.*|network_boot_nodes = \[\"/ip4/54.219.26.22/udp/1234/p2p/16Uiu2HAmTVDGNhkHD98zDnJxQWu3i1FL1aFYeh9wiQTNu4pDCgps\",\"/ip4/52.52.127.117/udp/1234/p2p/16Uiu2HAkzRjxK2gorngB1Xq84qDrT4hSVznYDHj6BkbaE4SGx9oS\",\"/ip4/3.101.148.32/udp/1234/p2p/16Uiu2HAmBfd2d3cyrCmrroELFZ1sCEJ9FXYKhWUB6jKX3cXBnHBM\"]|
" $HOME/0g-storage-node/config/config.toml

# Create log directory
echo -e "\e[1m\e[32m9. Creating log directory... \e[0m" && sleep 1
sudo mkdir -p /root/0g-storage-node/run/log

# Start the node
echo -e "\e[1m\e[32m10. Starting the node... \e[0m" && sleep 1
sudo systemctl start zgs
sudo systemctl enable zgs

echo -e "\e[1m\e[32mNode setup completed successfully!\e[0m"

# Display log file commands
echo -e "\e[1m\e[32m11. Checking log files... \e[0m" && sleep 1
echo "Check the logs directory: ls -lt /root/0g-storage-node/run/log"
echo "Full logs command: tail -f ~/0g-storage-node/run/log/zgs.log.\$(TZ=UTC date +%Y-%m-%d)"
echo "tx_seq-only logs command: tail -f ~/0g-storage-node/run/log/zgs.log.\$(TZ=UTC date +%Y-%m-%d) | grep tx_seq:"
