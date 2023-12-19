// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "lib/forge-std/src/Test.sol";

import "./Base.t.sol";

contract StakePOLTests is Base {
    function setUp() public override {
        super.setUp();
        grantOperatorRole(_operator);
    }

    function testAdminCanStake() public {
        uint256 polAmount = 10 * 10 ** 18;
        uint256 stakeMngrBalanceBefore = _matic.balanceOf(
            address(_stakeManager)
        );
        uint256 expectedSharesMinted = getDelegateShares(polAmount);

        vm.expectCall(
            vm.envAddress("POLYGON_MIGRATOR"),
            abi.encodeWithSelector(
                IPolygonMigration.unmigrate.selector,
                polAmount
            )
        );

        stakeFrom(_admin, polAmount);

        uint256 stakeMngrBalanceAfter = _matic.balanceOf(
            address(_stakeManager)
        );

        assertEq(stakeMngrBalanceAfter - stakeMngrBalanceBefore, polAmount);
        assertEq(
            IERC20(_delegate).balanceOf(address(_polStakeHelper)),
            expectedSharesMinted
        );
    }

    function testOperatorCanStake() public {
        uint256 polAmount = 10 * 10 ** 18;
        uint256 stakeMngrBalanceBefore = _matic.balanceOf(
            address(_stakeManager)
        );
        uint256 expectedSharesMinted = getDelegateShares(polAmount);

        stakeFrom(_operator, polAmount);

        uint256 stakeMngrBalanceAfter = _matic.balanceOf(
            address(_stakeManager)
        );

        assertEq(stakeMngrBalanceAfter - stakeMngrBalanceBefore, polAmount);
        assertEq(
            IERC20(_delegate).balanceOf(address(_polStakeHelper)),
            expectedSharesMinted
        );
    }

    function testAdminAndOperatorCanStake() public {
        // Define amounts to be staked by admin and operator
        uint256 adminPolAmount = 10 * 10 ** 18;
        uint256 operatorPolAmount = 5 * 10 ** 18;

        // Admin stakes
        uint256 adminStakeMngrBalanceBefore = _matic.balanceOf(
            address(_stakeManager)
        );
        uint256 adminExpectedSharesMinted = getDelegateShares(adminPolAmount);
        stakeFrom(_admin, adminPolAmount);
        uint256 adminStakeMngrBalanceAfter = _matic.balanceOf(
            address(_stakeManager)
        );

        // Check the admin's stake
        assertEq(
            adminStakeMngrBalanceAfter - adminStakeMngrBalanceBefore,
            adminPolAmount
        );
        assertEq(
            IERC20(_delegate).balanceOf(address(_polStakeHelper)),
            adminExpectedSharesMinted
        );

        // Operator stakes
        uint256 operatorStakeMngrBalanceBefore = _matic.balanceOf(
            address(_stakeManager)
        );
        uint256 operatorExpectedSharesMinted = getDelegateShares(
            operatorPolAmount
        );
        stakeFrom(_operator, operatorPolAmount);
        uint256 operatorStakeMngrBalanceAfter = _matic.balanceOf(
            address(_stakeManager)
        );

        // Check the operator's stake
        assertEq(
            operatorStakeMngrBalanceAfter - operatorStakeMngrBalanceBefore,
            operatorPolAmount
        );
        assertEq(
            IERC20(_delegate).balanceOf(address(_polStakeHelper)),
            operatorExpectedSharesMinted + adminExpectedSharesMinted
        );
    }

    function testJoeNobodyCannotStake() public {
        uint256 polAmount = 10 * 10 ** 18;

        vm.startBroadcast(_randomJoe);
        deal(address(_pol), _randomJoe, polAmount);
        _pol.approve(address(_polStakeHelper), polAmount);
        vm.expectRevert("NOT_ALLOWED");
        _polStakeHelper.stakePOL(polAmount);
        vm.stopBroadcast();
    }

    function testCannotStakeZero() public {
        vm.broadcast(_admin);
        vm.expectRevert("INVALID_AMT");
        _polStakeHelper.stakePOL(0);
    }

    function testCanStakeDifferentAmounts() public {
        // Define the number of tests and the range for random amounts
        uint256 numTests = 5;
        uint256 minStake = 1 ether;
        uint256 maxStake = 100 ether;

        uint256 polStakeHelperBalance;

        for (uint i = 0; i < numTests; i++) {
            // Generate a random amount to stake
            uint256 polAmount = randomAmount(minStake, maxStake);

            // Record the balances before staking
            uint256 stakeMngrBalanceBefore = _matic.balanceOf(
                address(_stakeManager)
            );
            polStakeHelperBalance += getDelegateShares(polAmount);
            // Perform the staking
            stakeFrom(_admin, polAmount);

            // Record the balances after staking
            uint256 stakeMngrBalanceAfter = _matic.balanceOf(
                address(_stakeManager)
            );

            // Assert the balances and shares minted are as expected
            assertEq(stakeMngrBalanceAfter - stakeMngrBalanceBefore, polAmount);
            assertEq(
                IERC20(_delegate).balanceOf(address(_polStakeHelper)),
                polStakeHelperBalance
            );
        }
    }
}
