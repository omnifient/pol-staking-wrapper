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

    address internal _operator = vm.addr(1);
    address internal _randomJoe = vm.addr(2);

    address internal _stakeManagerAddr = vm.envAddress("STAKE_MANAGER");
    IStakeManager internal _stakeManager = IStakeManager(_stakeManagerAddr);

    address internal _delegate;

    address internal _governanceAddress =
        0x6e7a5820baD6cebA8Ef5ea69c0C92EbbDAc9CE48;

    function setUp() public virtual {
        address deployer = vm.addr(1);

        _admin = vm.envAddress("ADDRESS_ADMIN"); // TODO: use vm.addr(2)?
        _beneficiary = vm.envAddress("BENEFICIARY"); // TODO: use vm.addr(3)?

        _matic = IERC20(vm.envAddress("TOKEN_MATIC"));
        _pol = IERC20(vm.envAddress("TOKEN_POL"));

        vm.startPrank(deployer);
        // deploy and (partly) initialize the POLStakeHelper
        address polStakeHelperProxyAddr = DeployLib.deploy(
            _admin,
            address(_pol),
            address(_matic),
            vm.envAddress("POLYGON_MIGRATOR"),
            _beneficiary,
            _stakeManagerAddr
        );
        _polStakeHelper = POLStakeHelper(polStakeHelperProxyAddr);
        vm.stopPrank();

        bytes memory signerPubKey = vm.envBytes("TEST_SIGNER_PUB_KEY");

        address validatorAddress = _getSigner(signerPubKey);

        deal(address(_matic), validatorAddress, 3 * 10 ** 18);

        assertEq(_matic.balanceOf(validatorAddress), 3 * 10 ** 18);

        // prank the stake manager address and increase the validator threshold
        uint256 currentThreshold = _stakeManager.validatorThreshold();
        vm.prank(_governanceAddress);
        _stakeManager.updateValidatorThreshold(currentThreshold + 1);

        vm.startPrank(validatorAddress);
        _matic.approve(_stakeManagerAddr, 3 * 10 ** 18);
        _stakeManager.stakeFor(
            polStakeHelperProxyAddr,
            10 ** 18, // min amount
            10 ** 18, // min fee
            true, // must accept delegation
            signerPubKey // signer pub key for the validator
        );
        _delegate = _stakeManager.getValidatorContract(
            _stakeManager.getValidatorId(polStakeHelperProxyAddr)
        );
        vm.stopPrank();

        vm.prank(_admin);
        _polStakeHelper.setDelegate(_delegate);
    }

    function _getSigner(bytes memory pub) private pure returns (address) {
        require(pub.length == 64, "not pub");
        return address(uint160(uint256(keccak256(pub))));
    }

    function grantOperatorRole(address to) internal {
        bytes32 role = _polStakeHelper.ROLE_OPERATOR();
        vm.broadcast(_admin);
        _polStakeHelper.grantRole(role, to);
    }

    function getDelegateShares(uint256 amount) internal view returns (uint256) {
        uint256 exchangeRate = IValidatorShare(_delegate).exchangeRate();
        uint256 precision = 10 ** 29;
        uint256 sharedMinted = (amount * exchangeRate) / precision;
        return sharedMinted;
    }

    function stakeFrom(address from, uint256 amount) internal {
        vm.startBroadcast(from);
        deal(address(_pol), from, amount);
        _pol.approve(address(_polStakeHelper), amount);
        _polStakeHelper.stakePOL(amount);
        vm.stopBroadcast();
    }

    function randomAmount(uint min, uint max) internal view returns (uint256) {
        return
            (uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.prevrandao,
                        msg.sender
                    )
                )
            ) % (max - min)) + min;
    }
}
