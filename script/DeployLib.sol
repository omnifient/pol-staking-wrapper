// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "lib/forge-std/src/console.sol";

import "../src/POLStakeHelper.sol";
import "../src/POLStakeHelperProxy.sol";

library DeployLib {
    function deploy(
        address admin,
        address pol,
        address matic,
        address polygonMigrator,
        address beneficiary,
        address stakeManager
    ) internal returns (address) {
        // deploy the implementation
        console.log("--- deploying implementation");
        POLStakeHelper impl = new POLStakeHelper();
        console.log("--- implementation deployed");

        // deploy the transparent proxy AND initialize it through the call data
        // NOTE: this implicitly deploys a ProxyAdmin (who is allowed to upgrade)
        console.log("--- deploying and initializing proxy");
        POLStakeHelperProxy proxy = new POLStakeHelperProxy(
            admin,
            address(impl),
            abi.encodeWithSignature(
                "initialize(address,address,address,address,address,address)",
                admin,
                pol,
                matic,
                polygonMigrator,
                beneficiary,
                stakeManager
            )
        );
        console.log("--- proxy deployed");

        return address(proxy);
    }
}
