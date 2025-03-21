## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
forge script script/MultiSign.s.sol:MultiSignScript --rpc-url https://sepolia.infura.io/v3/
```
### Verify
```shell
forge verify-contract 0x6c7f5ddb6d2bd06360639767f2afa5db1bd00e35 ERC1967Proxy --chain-id 11155111 --constructor-args $(cast abi-encode "constructor(address, bytes)" 0xdc15f740d00259402177f7d85515629fb6d0082e $(cast abi-encode "initialize(address[],uint256)" "[0xf989866c9305f3d77867923fa3b85d6df0aedd85,0x6e29d41a33c8c223edb1fd26a344335786d5f94d,0x9b543457bac8feec8d7bf82d2492aa814609d7a2]" 2)) 
```
### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
