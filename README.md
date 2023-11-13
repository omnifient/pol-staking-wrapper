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


## Resources

https://wiki.polygon.technology/docs/pos/reference/contracts/genesis-contracts/
