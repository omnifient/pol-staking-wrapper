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
    address internal _operator;
    address internal _randomJoe;
    address internal _beneficiary;
    address internal _delegate;

    IERC20 internal _matic;
    IERC20 internal _pol;

    POLStakeHelper internal _polStakeHelper;
    address internal _stakeManagerAddr;
    IStakeManager internal _stakeManager;
    address internal _governanceAddress;

    function setUp() public virtual {
        address deployer = vm.addr(1);
        _admin = vm.envAddress("ADDRESS_ADMIN"); // TODO: use vm.addr(2)?
        _beneficiary = vm.envAddress("BENEFICIARY"); // TODO: use vm.addr(3)?
        _operator = vm.addr(4);
        _randomJoe = vm.addr(5);

        _stakeManagerAddr = vm.envAddress("STAKE_MANAGER");
        _stakeManager = IStakeManager(_stakeManagerAddr);
        _governanceAddress = vm.envAddress("GOVERNOR");
        _matic = IERC20(vm.envAddress("TOKEN_MATIC"));
        _pol = IERC20(vm.envAddress("TOKEN_POL"));

        // 1. deploy and (partly) initialize the POLStakeHelper
        vm.startPrank(deployer);
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

        // 2. configure the validator to create a validator share
        // 2.1 get the validator's address
        bytes memory signerPubKey = vm.envBytes("TEST_SIGNER_PUB_KEY");
        address validatorAddress = _getSigner(signerPubKey);

        // 2.2 fund the validator
        deal(address(_matic), validatorAddress, 3 * 10 ** 18);
        assertEq(_matic.balanceOf(validatorAddress), 3 * 10 ** 18);

        // 2.3 prank the stake manager address and increase the validator threshold
        uint256 currentThreshold = _stakeManager.validatorThreshold();
        vm.prank(_governanceAddress);
        _stakeManager.updateValidatorThreshold(currentThreshold + 1);

        // 2.4 so that we can call stakeFor and create the validator share
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

        // 3. finish initialization by setting the delegate
        // retrieve the delegate's address
        _delegate = _stakeManager.getValidatorContract(
            _stakeManager.getValidatorId(polStakeHelperProxyAddr)
        );
        // and set it
        vm.prank(_admin);
        _polStakeHelper.setDelegate(_delegate);

        // 4. access control configs
        _grantOperatorRole(_operator);
    }

    function _getSigner(bytes memory pub) private pure returns (address) {
        require(pub.length == 64, "not pub");
        return address(uint160(uint256(keccak256(pub))));
    }

    function _grantOperatorRole(address to) internal {
        bytes32 role = _polStakeHelper.ROLE_OPERATOR();
        vm.broadcast(_admin);
        _polStakeHelper.grantRole(role, to);
    }

    function _getDelegateShares(uint256 amount) internal view returns (uint256) {
        uint256 exchangeRate = IValidatorShare(_delegate).exchangeRate();
        uint256 precision = 10 ** 29;
        uint256 sharedMinted = (amount * exchangeRate) / precision;
        return sharedMinted;
    }

    function _stakePOL(address from, uint256 amount) internal {
        vm.startBroadcast(from);
        deal(address(_pol), from, amount);
        _pol.approve(address(_polStakeHelper), amount);
        _polStakeHelper.stakePOL(amount);
        vm.stopBroadcast();
    }

    function _randomAmount(uint min, uint max) internal view returns (uint256) {
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

    function _increaseRewardPerStake(
        uint256 _value
    ) internal returns (uint256) {
        bytes32 slot = bytes32(uint256(36));
        bytes32 load = vm.load(address(_stakeManager), slot);
        emit log_bytes32(load);

        // convert bytes32 to uint256
        uint256 currentRewardPerStake = uint256(load);

        bytes32 value = bytes32(uint256(currentRewardPerStake + _value));
        vm.store(address(_stakeManager), slot, value);

        return currentRewardPerStake + _value;
    }
}
