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
        vm.stopPrank();

        bytes memory signerPubKey = vm.envBytes("TEST_SIGNER_PUB_KEY");

        address validatorAddress = _getSigner(signerPubKey);

        vm.prank(0x2f7E0aeCE1df77277504d885246cd98704372758); // at 18762829: 3 MATIC
        _matic.transfer(validatorAddress, 3 * 10 ** 18);

        assertEq(_matic.balanceOf(validatorAddress), 3 * 10 ** 18);

        // prank the stake manager address and increase the validator threshold
        address governanceAddress = 0x6e7a5820baD6cebA8Ef5ea69c0C92EbbDAc9CE48;
        uint256 currentThreshold = stakeManager.validatorThreshold();
        vm.prank(governanceAddress);
        stakeManager.updateValidatorThreshold(currentThreshold + 1);

        vm.startPrank(validatorAddress);
        _matic.approve(stakeManagerAddr, 3 * 10 ** 18);
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
        vm.stopPrank();

        vm.prank(_admin);
        _polStakeHelper.setDelegate(delegate);
    }

    function _getSigner(bytes memory pub) private pure returns (address) {
        require(pub.length == 64, "not pub");
        return address(uint160(uint256(keccak256(pub))));
    }
}
