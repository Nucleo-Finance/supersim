#!/usr/bin/env bash

set -eu

L1_NODE_URL=$1
L1_CHAIN_ID=31337
OWNER_ADDRESS=0x70997970C51812dc3A010C7d01b50e0d17dc79C8
OWNER_PRIVATE_KEY=59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d

export DEPLOYMENT_CONTEXT="$L1_CHAIN_ID"

echo "Writing deployment config"
cd ./optimism/packages/contracts-bedrock

deploy_config_file="deploy-config/$DEPLOYMENT_CONTEXT.json"
cp deploy-config/devnetL1-template.json $deploy_config_file
sed -i "s/\"l1ChainID\": .*/\"l1ChainID\": $DEPLOYMENT_CONTEXT,/g" $deploy_config_file

mkdir -p deployments/$DEPLOYMENT_CONTEXT

# Deployment requires the create2 deterministic proxy contract be published on L1 at address 0x4e59b44847b379578588920ca78fbf26c0b4956c
# See: https://github.com/Arachnid/deterministic-deployment-proxy
echo "Deploying create2 proxy contract..."
echo "Funding deployment signer address"
deployment_signer="0x3fab184622dc19b6109349b94811493bf2a45362"
cast send --from $OWNER_ADDRESS --rpc-url $L1_NODE_URL --value 1ether $deployment_signer --private-key $OWNER_PRIVATE_KEY
echo "Deploying contract..."
raw_bytes="0xf8a58085174876e800830186a08080b853604580600e600039806000f350fe7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe03601600081602082378035828234f58015156039578182fd5b8082525050506014600cf31ba02222222222222222222222222222222222222222222222222222222222222222a02222222222222222222222222222222222222222222222222222222222222222"

cast publish --rpc-url $L1_NODE_URL $raw_bytes

echo "Deploying L1 Optimism contracts..."
forge script scripts/Deploy.s.sol:Deploy --private-key $OWNER_PRIVATE_KEY -vvv --broadcast --rpc-url $L1_NODE_URL --slow

echo "Contracts deployed"
cp deploy-config/$DEPLOYMENT_CONTEXT.json ../../../l1-devnet/devnet.json
cp deployments/$DEPLOYMENT_CONTEXT/.deploy ../../../genesis/generated/901-l2-addresses.json

echo "Generating L2 genesis file..."

cd ../../../optimism/op-node

# Disabling memsize restriction
go build -ldflags=-checklinkname=0 cmd/main.go
./main genesis l2 --l1-rpc $L1_NODE_URL --deploy-config ../../l1-devnet/devnet.json --l1-deployments ../../genesis/generated/901-l2-addresses.json --outfile.l2 ../../genesis/generated/901-l2-genesis.json --outfile.rollup ../../l2-config/$DEPLOYMENT_CONTEXT-rollup.json