#!/bin/bash

# 1. Install Dependencies
sudo apt-get update
sudo apt-get install -y git cargo clang cmake build-essential

# Rustup Installation
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"

# Install GO
cd $HOME && \
ver="1.22.0" && \
sudo rm -rf /usr/local/go && \
sudo curl -fsSL "https://golang.org/dl/go$ver.linux-amd64.tar.gz" | sudo tar -C /usr/local -xzf - && \
grep -qxF 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' ~/.bash_profile || echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> ~/.bash_profile && \
source ~/.bash_profile && \
go version

# Build Binary
cd $HOME
git clone -b v0.3.3 https://github.com/0glabs/0g-storage-node.git
cd 0g-storage-node
git submodule update --init
cargo build --release

# Set Up Environment Variables
ENR_ADDRESS=$(wget -qO- eth0.me)
echo "export ENR_ADDRESS=${ENR_ADDRESS}" >> ~/.bash_profile
echo "export ZGS_CONFIG_FILE=\"$HOME/0g-storage-node/run/config.toml\"" >> ~/.bash_profile
echo "export ZGS_LOG_DIR=\"$HOME/0g-storage-node/run/log\"" >> ~/.bash_profile
echo "export ZGS_LOG_CONFIG_FILE=\"$HOME/0g-storage-node/run/log_config\"" >> ~/.bash_profile
source ~/.bash_profile

# Store Miner Key
read -p "Enter your private key for miner_key configuration (leave blank to skip): " PRIVATE_KEY && echo
if [ -n "$PRIVATE_KEY" ]; then
    sed -i "s|^\s*#\?\s*miner_key\s*=.*|miner_key = \"$PRIVATE_KEY\"|" "$ZGS_CONFIG_FILE"
else
    echo "No private key entered. Skipping miner_key configuration."
fi

# Update Config File
sed -i 's|^\s*#\?\s*network_dir\s*=.*|network_dir = "/root/0g-storage-node/network"|' "$ZGS_CONFIG_FILE"
sed -i "s|^\s*#\?\s*network_enr_address\s*=.*|network_enr_address = \"$ENR_ADDRESS\"|" "$ZGS_CONFIG_FILE"
sed -i 's|^\s*#\?\s*network_enr_tcp_port\s*=.*|network_enr_tcp_port = 1234|' "$ZGS_CONFIG_FILE"
sed -i 's|^\s*#\?\s*network_enr_udp_port\s*=.*|network_enr_udp_port = 1234|' "$ZGS_CONFIG_FILE"
sed -i 's|^\s*#\?\s*network_libp2p_port\s*=.*|network_libp2p_port = 1234|' "$ZGS_CONFIG_FILE"
sed -i 's|^\s*#\?\s*network_discovery_port\s*=.*|network_discovery_port = 1234|' "$ZGS_CONFIG_FILE"
sed -i 's|^\s*#\?\s*network_target_peers\s*=.*|network_target_peers = 50|' "$ZGS_CONFIG_FILE"
sed -i 's|^\s*#\?\s*blockchain_rpc_endpoint\s*=.*|blockchain_rpc_endpoint = "'"$RPC_ENDPOINT"'"|' "$ZGS_CONFIG_FILE"
sed -i 's|^\s*#\?\s*log_contract_address\s*=.*|log_contract_address = "0x8873cc79c5b3b5666535C825205C9a128B1D75F1"|' "$ZGS_CONFIG_FILE"
sed -i 's|^\s*#\?\s*log_sync_start_block_number\s*=.*|log_sync_start_block_number = 802|' "$ZGS_CONFIG_FILE"
sed -i 's|^\s*#\?\s*rpc_enabled\s*=\s*true|rpc_enabled = true|' "$ZGS_CONFIG_FILE"
sed -i 's|^\s*#\?\s*rpc_listen_address\s*=\s*"0.0.0.0:5678"|rpc_listen_address = "0.0.0.0:5678"|' "$ZGS_CONFIG_FILE"
sed -i 's|^\s*#\?\s*db_dir\s*=.*|db_dir = "/root/0g-storage-node/db"|' "$ZGS_CONFIG_FILE"
sed -i 's|^\s*#\?\s*log_config_file\s*=.*|log_config_file = "/root/0g-storage-node/run/log_config"|' "$ZGS_CONFIG_FILE"
sed -i 's|^\s*#\?\s*log_directory\s*=.*|log_directory = "/root/0g-storage-node/run/log"|' "$ZGS_CONFIG_FILE"
sed -i 's|^\s*#\?\s*mine_contract_address\s*=.*|mine_contract_address = "0x85F6722319538A805ED5733c5F4882d96F1C7384"|' "$ZGS_CONFIG_FILE"

# 8. Create Service File
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


sudo systemctl daemon-reload
sudo systemctl enable zgs
sudo systemctl start zgs
sudo systemctl status zgs

echo "Node setup completed successfully!"
echo "To check logs, use:"
echo "  tail -n 100 \"$ZGS_LOG_DIR/\$(ls -Art $ZGS_LOG_DIR | tail -n 1)\""
echo "To restart the node, use:"
echo "  sudo systemctl restart zgs"
echo "To stop the node, use:"
echo "  sudo systemctl stop zgs"
