#!/bin/bash

L1StandardBridgeProxy=0x5C7c905B505f0Cf40Ab6600d05e677F717916F6B

# Check if L1 contracts are deployed
CODE_SIZE=$(cast code $L1StandardBridgeProxy)

if [ "${#CODE_SIZE}" -eq 0 ] || [ "$CODE_SIZE" = "0x" ]; then
    echo "Deploying L1 contracts..."
    /app/deploy-l1.sh "$L1_NODE_URL"
fi

exec supersim "$@"