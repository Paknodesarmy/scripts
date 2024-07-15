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
sudo apt-get update
sudo apt-get install -y git cargo clang cmake build-essential

# Install Rustup
echo -e "\e[1m\e[32m2. Installing Rustup... \e[0m" && sleep 1
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
. "$HOME/.cargo/env"

# Install Go
echo -e "\e[1m\e[32m3. Installing Go... \e[0m" && sleep 1
cd $HOME && \
ver="1.22.0" && \
sudo rm -rf /usr/local/go && \
sudo curl -fsSL "https://golang.org/dl/go$ver.linux-amd64.tar.gz" | sudo tar -C /usr/local -xzf - && \
grep -qxF 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' ~/.bash_profile || echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> ~/.bash_profile && \
source ~/.bash_profile && \
go version

# Build Binary
echo -e "\e[1m\e[32m4. Building binary... \e[0m" && sleep 1
cd $HOME
git clone -b v0.3.3 https://github.com/0glabs/0g-storage-node.git
cd 0g-storage-node
git submodule update --init
cargo build --release
sudo mv "$HOME/0g-storage-node/target/release/zgs_node" /usr/local/bin

# Set Up Environment Variables
echo -e "\e[1m\e[32m5. Setting up environment variables... \e[0m" && sleep 1
ENR_ADDRESS=$(wget -qO- eth0.me)
echo "export ENR_ADDRESS=${ENR_ADDRESS}"
cat <<EOF >> ~/.bash_profile
export ENR_ADDRESS=${ENR_ADDRESS}
export ZGS_CONFIG_FILE="$HOME/0g-storage-node/run/config.toml"
export ZGS_LOG_DIR="$HOME/0g-storage-node/run/log"
export ZGS_LOG_CONFIG_FILE="$HOME/0g-storage-node/run/log_config"
EOF
source ~/.bash_profile

# Store Miner Key
echo -e "\e[1m\e[32m6. Storing miner key... \e[0m" && sleep 1
read -p "Enter your private key for miner_key configuration: " PRIVATE_KEY && echo

# Create Network & DB Directory
echo -e "\e[1m\e[32m7. Creating network & DB directory... \e[0m" && sleep 1
mkdir -p "$HOME/0g-storage-node/network" "$HOME/0g-storage-node/db"

# Update Config File
echo -e "\e[1m\e[32m8. Updating config file... \e[0m" && sleep 1
CONFIG_FILE="$ZGS_CONFIG_FILE"
sed -i 's|^\s*#\?\s*network_dir\s*=.*|network_dir = "/root/0g-storage-node/network"|' "$CONFIG_FILE"
sed -i "s|^\s*#\?\s*network_enr_address\s*=.*|network_enr_address = \"$ENR_ADDRESS\"|" "$CONFIG_FILE"
sed -i 's|^\s*#\?\s*network_enr_tcp_port\s*=.*|network_enr_tcp_port = 1234|' "$CONFIG_FILE"
sed -i 's|^\s*#\?\s*network_enr_udp_port\s*=.*|network_enr_udp_port = 1234|' "$CONFIG_FILE"
sed -i 's|^\s*#\?\s*network_libp2p_port\s*=.*|network_libp2p_port = 1234|' "$CONFIG_FILE"
sed -i 's|^\s*#\?\s*network_discovery_port\s*=.*|network_discovery_port = 1234|' "$CONFIG_FILE"
sed -i 's|^\s*#\?\s*network_target_peers\s*=.*|network_target_peers = 50|' "$CONFIG_FILE"
sed -i 's|^\s*#\?\s*blockchain_rpc_endpoint\s*=.*|blockchain_rpc_endpoint = "https://og-testnet-jsonrpc.blockhub.id"|' "$CONFIG_FILE"
sed -i 's|^\s*#\?\s*log_contract_address\s*=.*|log_contract_address = "0x8873cc79c5b3b5666535C825205C9a128B1D75F1"|' "$CONFIG_FILE"
sed -i 's|^\s*#\?\s*log_sync_start_block_number\s*=.*|log_sync_start_block_number = 802|' "$CONFIG_FILE"
sed -i 's|^\s*#\?\s*rpc_enabled\s*=\s*true|rpc_enabled = true|' "$CONFIG_FILE"
sed -i 's|^\s*#\?\s*rpc_listen_address\s*=\s*"0.0.0.0:5678"|rpc_listen_address = "0.0.0.0:5678"|' "$CONFIG_FILE"
sed -i 's|^\s*#\?\s*db_dir\s*=.*|db_dir = "/root/0g-storage-node/db"|' "$CONFIG_FILE"
sed -i 's|^\s*#\?\s*log_config_file\s*=.*|log_config_file = "/root/0g-storage-node/run/log_config"|' "$CONFIG_FILE"
sed -i 's|^\s*#\?\s*log_directory\s*=.*|log_directory = "/root/0g-storage-node/run/log"|' "$CONFIG_FILE"
sed -i 's|^\s*#\?\s*mine_contract_address\s*=.*|mine_contract_address = "0x85F6722319538A805ED5733c5F4882d96F1C7384"|' "$CONFIG_FILE"
sed -i "s|^\s*#\?\s*miner_key\s*=.*|miner_key = \"$PRIVATE_KEY\"|" "$CONFIG_FILE"

# Create Service File
echo -e "\e[1m\e[32m9. Creating systemd service file... \e[0m" && sleep 1
sudo tee /etc/systemd/system/zgs.service > /dev/null <<EOF
[Unit]
Description=0G Storage Node
After=network.target

[Service]
User=$USER
Type=simple
ExecStart=/usr/local/bin/zgs_node --config $HOME/0g-storage-node/run/config.toml
Restart=on-failure
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

# Start Storage Node
echo -e "\e[1m\e[32m10. Starting storage node... \e[0m" && sleep 1
sudo systemctl daemon-reload
sudo systemctl enable zgs
sudo systemctl start zgs
sudo systemctl status zgs

echo -e "\e[1m\e[32mStorage node setup completed successfully!\e[0m"

# Useful Commands
echo -e "\e[1m\e[32mUseful Commands: \e[0m"
echo "Check Latest Log: tail -n 100 \"\$ZGS_LOG_DIR/\$(ls -Art \$ZGS_LOG_DIR | tail -n 1)\""
echo "Check Peers Log: grep 'peers' \"\$ZGS_LOG_DIR/\$(ls -Art \$ZGS_LOG_DIR | tail -n 1)\""
echo "Check Tx Sequence Log: grep 'tx_seq' \"\$ZGS_LOG_DIR/\$(ls -Art \$ZGS_LOG_DIR | tail -n 1)\""
echo "Look for Errors: grep \"Error\" \$ZGS_LOG_DIR/zgs.log.*"
echo "List Logs by Date: ls -lt \$ZGS_LOG_DIR"
echo "View Specific Date Logs: cat \$ZGS_LOG_DIR/zgs.log.\$(date +%Y-%m-%d)"
echo "Restart the Node: sudo systemctl restart zgs"
echo "Stop the Node: sudo systemctl stop zgs"
