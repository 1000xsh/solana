#!/bin/bash

echo "running mod_flush.sh..."
./mod_flush.sh
if [ $? -ne 0 ]; then
    echo "error: mod_flush.sh failed."
    exit 1
fi

echo "running mod_add.sh..."
./mod_add.sh
if [ $? -ne 0 ]; then
    echo "rrror: module_add.sh failed."
    exit 1
fi

echo "all scripts executed successfully."
