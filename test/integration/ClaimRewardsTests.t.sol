pragma solidity ^0.8.23;

import "lib/forge-std/src/Test.sol";

import "./Base.t.sol";

contract ClaimRewardsTests is Base {
    function testAdminCanClaimRewards() public {
        // stake some POL
        uint256 polAmount = 10 * 10 ** 18;
        _stakePOL(_admin, polAmount);

        uint256 polBalanceBefore = _pol.balanceOf(_beneficiary);

        // increase rewards - min threshold per validator (10**18)
        _increaseRewardPerStake(10000000 * 10 ** 18);

        uint256 beforeInitialRewardPerShare = IValidatorShare(_delegate)
            .initalRewardPerShare(address(_polStakeHelper));

        // claim rewards
        vm.broadcast(_admin);
        _polStakeHelper.claimRewards();

        // POL transferred to beneficiary
        uint256 polBalanceAfter = _pol.balanceOf(_beneficiary);
        assertGt(polBalanceAfter - polBalanceBefore, 0);

        // ValidatorShare state is updated
        uint256 afterInitialRewardPerShare = IValidatorShare(_delegate)
            .initalRewardPerShare(address(_polStakeHelper));

        assertGt(afterInitialRewardPerShare, beforeInitialRewardPerShare);
    }

    function testOperatorCanClaimRewards() public {
        // stake some POL
        uint256 polAmount = 10 * 10 ** 18;
        _stakePOL(_operator, polAmount);

        uint256 polBalanceBefore = _pol.balanceOf(_beneficiary);

        // increase rewards - min threshold per validator (10**18)
        _increaseRewardPerStake(10000000 * 10 ** 18);

        uint256 beforeInitialRewardPerShare = IValidatorShare(_delegate)
            .initalRewardPerShare(address(_polStakeHelper));

        // claim rewards
        vm.broadcast(_operator);
        _polStakeHelper.claimRewards();

        // POL transferred to beneficiary
        uint256 polBalanceAfter = _pol.balanceOf(_beneficiary);
        assertGt(polBalanceAfter - polBalanceBefore, 0);

        // ValidatorShare state is updated
        uint256 afterInitialRewardPerShare = IValidatorShare(_delegate)
            .initalRewardPerShare(address(_polStakeHelper));

        assertGt(afterInitialRewardPerShare, beforeInitialRewardPerShare);
    }

    function testRandomJoeCannotClaimRewards() public {
        // stake some POL
        uint256 polAmount = 10 * 10 ** 18;
        _stakePOL(_admin, polAmount);

        // increase rewards - min threshold per validator (10**18)
        _increaseRewardPerStake(10000000 * 10 ** 18);

        // claim rewards
        vm.broadcast(_randomJoe);
        vm.expectRevert("NOT_ALLOWED");
        _polStakeHelper.claimRewards();
    }

    function testClaimRewardsWithNoAvailableRewards() public {
        // stake some POL
        uint256 polAmount = 10 * 10 ** 18;
        _stakePOL(_operator, polAmount);

        // claim rewards
        vm.broadcast(_operator);
        vm.expectRevert("Too small rewards amount");
        _polStakeHelper.claimRewards();
    }

    function testClaimRewardsWithNewBeneficiary() public {
        // stake some POL
        uint256 polAmount = 10 * 10 ** 18;
        _stakePOL(_operator, polAmount);

        // increase rewards - min threshold per validator (10**18)
        _increaseRewardPerStake(10000000 * 10 ** 18);

        // change beneficiary
        address newBeneficiary = vm.addr(3);
        uint256 polBalanceBefore = _pol.balanceOf(newBeneficiary);
        vm.broadcast(_admin);
        _polStakeHelper.setBeneficiary(newBeneficiary);

        // claim rewards
        vm.broadcast(_operator);
        _polStakeHelper.claimRewards();

        // POL transferred to beneficiary
        uint256 polBalanceAfter = _pol.balanceOf(newBeneficiary);
        assertGt(polBalanceAfter - polBalanceBefore, 0);
    }
}
