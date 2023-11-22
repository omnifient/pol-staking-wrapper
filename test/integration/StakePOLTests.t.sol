// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "lib/forge-std/src/Test.sol";

contract StakePOLTests is Test {
    function testAdminCanStake() public {}

    function testOperatorCanStake() public {}

    function testAdminOperatorCanStake() public {}

    function testJoeNobodyCannotStake() public {}

    function testCanStakeMultipleTimes() public {}

    function testCannotStakeZero() public {}

    function testCanStakeDifferentAmounts() public {}
}
