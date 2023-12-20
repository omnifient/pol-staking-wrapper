// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "lib/forge-std/src/Script.sol";

import "./helpers/DeployLib.sol";
import "../src/POLStakeHelperProxy.sol";
import "../src/POLStakeHelper.sol";

/// @notice Deploy and initialization scripts for POLStakeHelper
/// Initialization is a two step process because of the delegate:
/// creating a delegate requires the address of the POLStakeHelper,
/// but POLStakeHelper needs the delegate.
/// As such, the delegate is set after the deploy+init of POLStakeHelper.

contract DeployInit1POLStakeHelper is Script {
    function run() external {
        vm.startBroadcast(vm.envUint("DEPLOYER_PRIVATE_KEY"));

        // retrieve required arguments
        address admin = vm.envAddress("ADMIN");
        address pol = vm.envAddress("TOKEN_POL");
        address matic = vm.envAddress("TOKEN_MATIC");
        address polygonMigrator = vm.envAddress("POLYGON_MIGRATOR");
        address beneficiary = vm.envAddress("BENEFICIARY");
        address stakeManager = vm.envAddress("STAKE_MANAGER");

        // deploy and initialize the impl+proxy
        address polStakeHelperProxyAddr = DeployLib.deploy(
            admin,
            pol,
            matic,
            polygonMigrator,
            beneficiary,
            stakeManager
        );

        vm.setEnv(
            "POL_STAKE_HELPER_PROXY",
            vm.toString(polStakeHelperProxyAddr)
        );

        vm.stopBroadcast();
    }
}

contract Init2POLStakeHelper is Script {
    function run() external {
        vm.startBroadcast(vm.envUint("ADMIN_PRIVATE_KEY"));

        // NOTE: this assumes that the deployer is an admin or operator

        // post-set the delegate field
        address polStakeHelperProxy = vm.envAddress("POL_STAKE_HELPER_PROXY");
        address delegate = vm.envAddress("DELEGATE");

        POLStakeHelper(polStakeHelperProxy).setDelegate(delegate);

        vm.stopBroadcast();
    }
}

/*
// NOTE: this is left here as an example
contract StakeForPOLStakeHelper is Script {
    function run() external {
        address polStakeHelperProxyAddr = vm.envAddress("POL_STAKE_HELPER_PROXY");

        bytes memory signerPubKey = vm.envBytes("SIGNER_PUB_KEY");
        address validatorAddress = address(uint160(uint256(keccak256(signerPubKey))));

        // NOTE: validator must be funded with enough funds to call stakeFor
        // NOTE: stake manager must have available validator slots

        vm.startPrank(validatorAddress);
        _matic.approve(_stakeManagerAddr, 3 * 10 ** 18);
        _stakeManager.stakeFor(
            polStakeHelperProxyAddr,
            10 ** 18, // min amount
            10 ** 18, // min fee
            true, // must accept delegation
            signerPubKey // signer pub key for the validator
        );
        vm.stopPrank();

    }
}
*/
