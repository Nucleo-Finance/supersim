# 🛠️ Supersim

## 🚀 Getting Started

### 1. Install prerequisites: `foundry`

`supersim` requires `anvil` to be installed.

Follow [this guide](https://book.getfoundry.sh/getting-started/installation) to install Foundry.

### 2. Deploy contract on `local l1 node`

```sh
chmod +x deploy-l1.sh
./deploy-l1.sh
```

### 3. Start `supersim` in vanilla mode

```sh
go run ./cmd
```
Vanilla mode will start a new chain, with the OP Stack contracts already deployed.

```
Chain Configuration
-----------------------
L1: Name: Local  ChainID: 900  RPC: http://127.0.0.1:8545  LogPath: /var/folders/y6/bkjdghqx1sn_3ypk1n0zy3040000gn/T/anvil-chain-900-3719464405

L2s: Predeploy Contracts Spec ( https://specs.optimism.io/protocol/predeploys.html )

  * Name: OPChainA  ChainID: 901  RPC: http://127.0.0.1:9545  LogPath: /var/folders/y6/bkjdghqx1sn_3ypk1n0zy3040000gn/T/anvil-chain-901-1956365912
    L1 Contracts:
     - OptimismPortal:         0x73eccD6288e117cAcA738BDAD4FEC51312166C1A
     - L1CrossDomainMessenger: 0x0D4ff719551E23185Aeb16FFbF2ABEbB90635942
     - L1StandardBridge:       0x5C7c905B505f0Cf40Ab6600d05e677F717916F6B
```


## 🔀 First steps

### Example A: (L1 to L2) Deposit ETH from the L1 into the L2

**1. Check initial balance on the L2 (chain 901)**

Grab the balance of the sender account on L2:

```sh
cast balance 0xD3E6F38DACFD07e11e44f102393a20d249C1c221 --rpc-url http://127.0.0.1:9545
```

**2. Fund sender account**

```sh
 cast send 0xD3E6F38DACFD07e11e44f102393a20d249C1c221 --value 1ether --rpc-url http://172.21.0.2:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

**3. Call `bridgeETH` function on the `L1StandardBridgeProxy` contract on the L1**

Initiate a bridge transaction on the L1:

```sh
cast send 0x5C7c905B505f0Cf40Ab6600d05e677F717916F6B "bridgeETH(uint32 _minGasLimit, bytes calldata _extraData)" 50000 0x --value 0.1ether --rpc-url http://172.21.0.2:8545 --private-key 0x895223ed216470ca32b8151df1989d46d2cc8325282ba133b293c0d655eda7e2
```

**4. Check the balance on the L2 (chain 901)**

Verify that the ETH balance of the sender has increased on the L2:

```sh
cast balance 0xD3E6F38DACFD07e11e44f102393a20d249C1c221 --rpc-url http://127.0.0.1:9545
```