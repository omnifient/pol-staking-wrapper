// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "lib/forge-std/src/Test.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../script/DeployLib.sol";

import "../../src/POLStakeHelperProxy.sol";
import "../../src/POLStakeHelper.sol";

import "../../src/interfaces/IStakeManager.sol";

contract Base is Test {
    address internal _admin;
    address internal _beneficiary;

    IERC20 internal _matic;
    IERC20 internal _pol;

    POLStakeHelper internal _polStakeHelper;

    function setUp() public virtual {
        address deployer = vm.addr(1);

        _admin = vm.envAddress("ADDRESS_ADMIN"); // TODO: use vm.addr(2)?
        _beneficiary = vm.envAddress("BENEFICIARY"); // TODO: use vm.addr(3)?

        _matic = IERC20(vm.envAddress("TOKEN_MATIC"));
        _pol = IERC20(vm.envAddress("TOKEN_POL"));
        address stakeManagerAddr = vm.envAddress("STAKE_MANAGER");
        IStakeManager stakeManager = IStakeManager(stakeManagerAddr);

        vm.startPrank(deployer);

        // deploy and (partly) initialize the POLStakeHelper
        address polStakeHelperProxyAddr = DeployLib.deploy(
            _admin,
            address(_pol),
            address(_matic),
            vm.envAddress("POLYGON_MIGRATOR"),
            _beneficiary,
            stakeManagerAddr
        );
        _polStakeHelper = POLStakeHelper(polStakeHelperProxyAddr);

        // -------------
        bytes memory signerPubKey; // TODO: validator key e.g. vm.envBytes("TEST_SIGNER_PUB_KEY")
        // pre-requisite: create a validatorshare for our POLStakeHelper
        // TODO: change some state to be able to call stakeFor
        stakeManager.stakeFor(
            polStakeHelperProxyAddr,
            10 ** 18, // min amount
            10 ** 18, // min fee
            true, // must accept delegation
            signerPubKey // signer pub key for the validator
        );
        address delegate = stakeManager.getValidatorContract(
            stakeManager.getValidatorId(polStakeHelperProxyAddr)
        );
        // -------------

        _polStakeHelper.setDelegate(delegate);

        vm.stopPrank();
    }
}
