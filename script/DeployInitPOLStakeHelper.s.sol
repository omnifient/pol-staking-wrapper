// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "lib/forge-std/src/Script.sol";

import "./DeployLib.sol";

contract DeployInitPOLStakeHelper is Script {
    function run() external {
        // retrieve required arguments
        address admin = vm.envAddress("ADDRESS_ADMIN");
        address pol = vm.envAddress("TOKEN_POL");
        address matic = vm.envAddress("TOKEN_MATIC");
        address polygonMigrator = vm.envAddress("POLYGON_MANAGER");
        address delegate = vm.envAddress("DELEGATE");
        address beneficiary = vm.envAddress("BENEFICIARY");
        address stakeManager = vm.envAddress("STAKE_MANAGER");

        DeployLib.deploy(
            admin,
            pol,
            matic,
            polygonMigrator,
            delegate,
            beneficiary,
            stakeManager
        );
    }
}
