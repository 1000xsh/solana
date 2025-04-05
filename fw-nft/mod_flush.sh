#!/bin/bash

echo "flushing all nftables rules..."
sudo nft flush ruleset

echo "all nftables rules flushed."
