// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "lib/forge-std/src/console.sol";
import "lib/forge-std/src/Script.sol";

import "../src/POLStakeHelper.sol";
import "../src/POLStakeHelperProxy.sol";

contract DeployInitPOLStakeHelper is Script {
    function run() external {
        // retrieve required arguments
        address admin = vm.envAddress("ADDRESS_ADMIN");
        address pol = vm.envAddress("TOKEN_POL");
        address matic = vm.envAddress("TOKEN_MATIC");
        address polygonMigrator = vm.envAddress("POLYGON_MANAGER");
        address stakingManager = vm.envAddress("STAKING_MANAGER");
        address delegate = vm.envAddress("DELEGATE");
        address beneficiary = vm.envAddress("BENEFICIARY");

        // deploy the implementation
        POLStakeHelper impl = new POLStakeHelper(admin);

        // deploy the transparent proxy
        // NOTE: behind the scenes, this deploys a ProxyAdmin
        // the only one who allowed to upgrade the proxy
        POLStakeHelperProxy proxy = new POLStakeHelperProxy(
            admin,
            address(impl),
            ""
        );

        POLStakeHelper(address(proxy)).initialize(
            admin,
            pol,
            matic,
            polygonMigrator,
            stakingManager,
            delegate,
            beneficiary
        );
    }
}
