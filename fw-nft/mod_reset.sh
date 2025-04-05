#!/bin/bash

echo "flushing existing nftables rules..."
./mod_flush.sh

echo "reapplying nftables rules..."
./mod_add.sh

echo "nftables rules reset and reapplied successfully."
