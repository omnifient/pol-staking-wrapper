# POL Staking Wrapper

[PRD](https://docs.google.com/document/d/1PwTVnWjTxxA98-26tN37Pp5meFiLLuuIZ99SvzExDF4/edit?pli=1#heading=h.v8evnmugpcqi)

## Context

- an upgrade to the MATIC token, called POL, was recently started
- roadmap for POL usage includes migrate Polygon PoS validators to stake using POL natively
- some entities (e.g. centralized exchanges) would love to be able to offer their customers the option of delegating via POL

## Goal

- build a wrapper contract which validators could deploy, which allows a third party to delegate to them in POL and would handle conversions to and from MATIC transparently

## Interface

POLStakeHelper

- must be upgradeable
- transparent proxy

### fields

- delegate
- beneficiary: funds always go to this address

### main functions

- stakePOL
- claimRewards
- unstakePOL

### config functions

- upgrade proxy
- add/remove operators
- set beneficiary

### roles

- admin: single account, can upgrade things, add/remove operators, change beneficiary, call stake, unstake, claim
- operator: multiple accounts, can call stake, unstake, claim

## Testing and Deploying

### Testing

```shell
forge test -vvvvv --fork-url <https://eth-mainnet.g.alchemy.com/v2/YOUR_ALCHEMY_KEY>
```

### Deployment to Local (Mainnet) Fork

Make sure your `.env` has the required values.

1. Start the anvil fork.

```
anvil --fork-url <https://eth-mainnet.g.alchemy.com/v2/YOUR_ALCHEMY_KEY> --port 12345 --fork-block-number 18828797
```

2. Deploy and initialize 1/2 the POLStakeHelper.

```
forge script script/DeployInitPOLStakeHelper.s.sol:DeployInit1POLStakeHelper --fork-url http://localhost:12345 --broadcast -vvvv
```

Note down the POLStakeHelperProxy's deployed address.

3. Deploy a Validator Share contract for the POLStakeHelper.

This step should be done outside of this project as it requires the validator to `stakeFor` the (just deployed) POLStakeHelperProxy with `acceptDelegation=true`.

Check [Base.t.sol](/test/integration/Base.t.sol)'s `setUp()` and `script/DeployInitPOLStakeHelper.s.sol` for example code.

4. Finish the initialization of the POLStakeHelper.

Make sure `POL_STAKE_HELPER_PROXY` and `DELEGATE` (the Validator Share that was deployed in the previous step) are set in `.env`.

```
forge script script/DeployInitPOLStakeHelper.s.sol:Init2POLStakeHelper --fork-url http://localhost:12345 --broadcast -vvvv
```

### Deployment to Testnet/Mainnet

Follow steps 2-4 from the previous section.

## Resources

### docs
- https://wiki.polygon.technology/docs/delegate/staking-faq/#how-to-stake-tokens-on-polygon
- https://wiki.polygon.technology/docs/pos/reference/contracts/stakingmanager/

### code
- https://github.com/0xPolygon/pol-token/blob/main/src/PolygonMigration.sol
- https://github.com/maticnetwork/contracts/blob/main/contracts/staking/stakeManager/StakeManager.sol

### addresses
- https://wiki.polygon.technology/docs/pos/reference/contracts/genesis-contracts/
- https://github.com/0xPolygon/pol-token/blob/main/deployments/1.md

#### ETH MAINNET
- MATIC=0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0
- POL=0x455e53CBB86018Ac2B8092FdCd39d8444aFFC3F6
- POLYGON_MIGRATOR=0x29e7DF7b6A1B2b07b731457f499E1696c60E2C4e
- STAKE_MANAGER=0x5e3Ef299fDDf15eAa0432E6e66473ace8c13D908

#### ETH GOERLI
- MATIC=0x499d11E0b6eAC7c0593d8Fb292DCBbF815Fb29Ae
- POL=0x4f34BF3352A701AEc924CE34d6CfC373eABb186c
- POLYGON_MIGRATOR=0x5c5589fca76237Ed00BA024e19b6C077a108f687
