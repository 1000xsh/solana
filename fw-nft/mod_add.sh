#!/bin/bash

echo "flushing existing nftables rules..."
sudo nft flush ruleset

echo "setting up nftables rules..."

# table and chains
sudo nft add table inet filter
sudo nft add chain inet filter input { type filter hook input priority 0 \; policy drop \; }
sudo nft add chain inet filter forward { type filter hook forward priority 0 \; policy drop \; }
sudo nft add chain inet filter output { type filter hook output priority 0 \; policy accept \; }

echo "allowing loopback traffic..."
sudo nft add rule inet filter input iif lo accept

echo "allowing established and related connections..."
sudo nft add rule inet filter input ct state established,related accept

echo "creating whitelist set..."
sudo nft add set inet filter whitelist { type ipv4_addr \; flags interval \; }

# ips from ips.txt to the whitelist
if [ -f "ips.txt" ]; then
    while IFS= read -r ip; do
        if [[ ! -z "$ip" && ! "$ip" =~ ^# ]]; then
            echo "adding IP $ip to the whitelist set..."
            sudo nft add element inet filter whitelist { "$ip" }
        fi
    done < "ips.txt"
else
    echo "error: ips.txt not found!"
    exit 1
fi

# process whitelisted ips with specific ports
# IP port,otherPort,otherPort

if [ -f "ips_ports.txt" ]; then
    while IFS= read -r line; do
        ip=$(echo "$line" | awk '{print $1}')
        ports=$(echo "$line" | awk '{print $2}')
        
        if [[ ! -z "$ip" && ! -z "$ports" && ! "$ip" =~ ^# ]]; then
            IFS=',' read -ra port_array <<< "$ports"
            for port in "${port_array[@]}"; do
                echo "allowing ip $ip on port $port..."
                sudo nft add rule inet filter input ip saddr "$ip" tcp dport "$port" accept
                sudo nft add rule inet filter input ip saddr "$ip" udp dport "$port" accept
            done
        fi
    done < "ips_ports.txt"
else
    echo "error: ips_ports.txt not found!"
    exit 1
fi

echo "allowing traffic from whitelisted IPs..."
sudo nft add rule inet filter input ip saddr @whitelist accept

echo "allowing specific ports for general traffic..."
sudo nft add rule inet filter input tcp dport { 8000-8898, 8901-10000 } accept
sudo nft add rule inet filter input udp dport { 8000-8898, 8901-10000 } accept

echo "allowing ssh (port 22) for whitelisted ips..."
sudo nft add rule inet filter input ip saddr @whitelist tcp dport 22 accept

##echo "allowing general ssh access on port 22..."
#sudo nft add rule inet filter input tcp dport 22 accept

echo "logging and dropping all other traffic..."
sudo nft add rule inet filter input log prefix \"NFTables-Dropped:\" level warn
sudo nft add rule inet filter input drop

echo "nftables rules applied successfully."
