#!/bin/bash

L1StandardBridgeProxy=0x5C7c905B505f0Cf40Ab6600d05e677F717916F6B
code=$(cast code $L1StandardBridgeProxy --rpc-url "$L1_NODE_URL")

if [ "$code" = "0x" ]; then
    echo "Code size is 0. Deploying L1..."
    /app/deploy-l1.sh $L1_NODE_URL
fi

echo "Code exists. Running supersim..."
exec supersim "$@"
