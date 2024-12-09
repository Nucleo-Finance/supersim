#!/bin/bash

if [ "$1" = "deploy-l1" ]; then
    /app/deploy-l1.sh $L1_NODE_URL
else
    exec supersim "$@"
fi