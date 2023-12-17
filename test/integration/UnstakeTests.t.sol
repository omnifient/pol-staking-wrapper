pragma solidity ^0.8.23;

import "lib/forge-std/src/Test.sol";

import "./Base.t.sol";

contract UnstakeTests is Base {
    uint256 epoch;
    uint256 withdrawalDelay;

    function setUp() public override {
        super.setUp();
        grantOperatorRole(_operator);
        epoch = _stakeManager.epoch();
        withdrawalDelay = _stakeManager.withdrawalDelay();
    }

    function testAdminCanUnstakeWhenWithdrawalDelayElapsed() public {
        uint256 polAmount = 10 * 10 ** 18;

        // stake
        stakeFrom(_admin, polAmount);

        uint256 stakerBalanceBefore = _pol.balanceOf(_beneficiary);

        // unstake part 1
        vm.broadcast(_admin);
        _polStakeHelper.unstakePOL(polAmount);

        // increase epoch
        vm.broadcast(_governanceAddress);
        _stakeManager.setCurrentEpoch(epoch + withdrawalDelay);

        // unstake part 2
        vm.broadcast(_admin);
        _polStakeHelper.transferUnstakedPOL();

        uint256 stakerBalanceAfter = _pol.balanceOf(_beneficiary);

        assertEq(stakerBalanceAfter - stakerBalanceBefore, polAmount);
    }

    // not wait withdrawal delay
    function testAdminCantUnstakeWhenWithdrawalDelayNotElapsed() public {
        uint256 polAmount = 10 * 10 ** 18;

        // stake
        stakeFrom(_admin, polAmount);

        // unstake part 1
        vm.broadcast(_admin);
        _polStakeHelper.unstakePOL(polAmount);

        // increase epoch with less than withdrawal delay
        vm.broadcast(_governanceAddress);
        _stakeManager.setCurrentEpoch(epoch + withdrawalDelay - 1);

        // unstake part 2
        vm.broadcast(_admin);
        vm.expectRevert("Incomplete withdrawal period");
        _polStakeHelper.transferUnstakedPOL();
    }

    // operator can unstake
    function testOperatorCanUnstakeWhenWithdrawalDelayElapsed() public {
        uint256 polAmount = 10 * 10 ** 18;

        // stake
        stakeFrom(_operator, polAmount);

        uint256 stakerBalanceBefore = _pol.balanceOf(_beneficiary);

        // unstake part 1
        vm.broadcast(_operator);
        _polStakeHelper.unstakePOL(polAmount);

        // increase epoch
        vm.broadcast(_governanceAddress);
        _stakeManager.setCurrentEpoch(epoch + withdrawalDelay);

        // unstake part 2
        vm.broadcast(_operator);
        _polStakeHelper.transferUnstakedPOL();

        uint256 stakerBalanceAfter = _pol.balanceOf(_beneficiary);

        assertEq(stakerBalanceAfter - stakerBalanceBefore, polAmount);
    }

    function testRevertWhenRandomJoeUnstake() public {
        vm.broadcast(_randomJoe);
        vm.expectRevert("NOT_ALLOWED");
        _polStakeHelper.unstakePOL(100);

        vm.broadcast(_randomJoe);
        vm.expectRevert("NOT_ALLOWED");
        _polStakeHelper.transferUnstakedPOL();
    }

    function testRevertWhenStakeInTheMiddleOfUnstake() public {
        uint256 polAmount = 10 * 10 ** 18;

        // stake
        stakeFrom(_admin, polAmount);

        // unstake part 1
        vm.startBroadcast(_admin);
        _polStakeHelper.unstakePOL(polAmount);

        // restake
        deal(address(_pol), _admin, polAmount);
        _pol.approve(address(_polStakeHelper), polAmount);
        vm.expectRevert("Ongoing exit");
        _polStakeHelper.stakePOL(polAmount);
        vm.stopBroadcast();

        // increase epoch
        vm.broadcast(_governanceAddress);
        _stakeManager.setCurrentEpoch(epoch + withdrawalDelay);

        // unstake part 2
        vm.broadcast(_admin);
        _polStakeHelper.transferUnstakedPOL();

        // staking when the unbonds share are transferred passes
        stakeFrom(_admin, polAmount);
    }

    function testPartiallyUnstake() public {
        uint256 numTests = 5;
        uint256 minStake = 1 ether;
        uint256 maxStake = 100 ether;

        uint256 totalPolStaked;

        for (uint i = 0; i < numTests; i++) {
            // Generate a random amount to stake
            uint256 polAmount = randomAmount(minStake, maxStake);

            // Record the balances before staking
            totalPolStaked += polAmount;
            // Perform the staking
            stakeFrom(_admin, polAmount);
        }

        uint256 stakerBalanceBefore = _pol.balanceOf(_beneficiary);

        uint256 polToUnstake = totalPolStaked / 2;

        uint256 expectedRemainingShares = getDelegateShares(polToUnstake);

        // unstake part 1
        vm.broadcast(_admin);
        _polStakeHelper.unstakePOL(polToUnstake);

        // increase epoch
        vm.broadcast(_governanceAddress);
        _stakeManager.setCurrentEpoch(epoch + withdrawalDelay);

        // unstake part 2
        vm.broadcast(_admin);
        _polStakeHelper.transferUnstakedPOL();

        uint256 stakerBalanceAfter = _pol.balanceOf(_beneficiary);

        assertEq(stakerBalanceAfter - stakerBalanceBefore, polToUnstake);

        // check remaining shares accounting for odd number division by 2
        assertApproxEqRel(
            IERC20(_delegate).balanceOf(address(_polStakeHelper)),
            expectedRemainingShares,
            1
        );
    }

    function testRevertWhenTransferUnstakedPOLWithNothingUnstaked() public {
        uint256 polAmount = 10 * 10 ** 18;

        // stake
        stakeFrom(_admin, polAmount);

        vm.broadcast(_admin);
        vm.expectRevert("Incomplete withdrawal period");
        _polStakeHelper.transferUnstakedPOL();
    }

    function testRevertWhenUnstakingMoreThanStaked() public {
        uint256 polAmount = 10 * 10 ** 18;

        // stake
        stakeFrom(_admin, polAmount);

        // unstake more than staked
        vm.broadcast(_admin);
        vm.expectRevert("Too much requested");
        _polStakeHelper.unstakePOL(polAmount + 1);
    }

    function testRevertWhenUnstakingZero() public {
        vm.broadcast(_admin);
        vm.expectRevert("INVALID_AMT");
        _polStakeHelper.unstakePOL(0);
    }
}
