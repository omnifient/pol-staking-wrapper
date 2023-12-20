pragma solidity ^0.8.23;

import "lib/forge-std/src/Test.sol";

import "./Base.t.sol";

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

contract AccessControlTests is Base {
    bytes32 _adminRole;

    function setUp() public override {
        super.setUp();

        _adminRole = _polStakeHelper.ROLE_ADMIN();
    }

    function testAdminCannotChangeAdmin() public {
        vm.startPrank(_admin);
        address newAdmin = address(3);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                _admin,
                _polStakeHelper.DEFAULT_ADMIN_ROLE()
            )
        );
        _polStakeHelper.grantRole(_adminRole, newAdmin);
        vm.stopPrank();
    }

    function testJoeCannotChangeAdmin() public {
        vm.startPrank(_randomJoe);
        address newAdmin = address(3);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                _randomJoe,
                _polStakeHelper.DEFAULT_ADMIN_ROLE()
            )
        );
        _polStakeHelper.grantRole(_adminRole, newAdmin);
        vm.stopPrank();
    }

    function testAdminCanChangeBeneficiary() public {
        vm.startPrank(_admin);
        address newBeneficiary = address(3);
        _polStakeHelper.setBeneficiary(newBeneficiary);
        vm.stopPrank();

        assertEq(_polStakeHelper.beneficiary(), newBeneficiary);
    }

    function testAdminCanSetDelegate() public {
        vm.startPrank(_admin);
        address newDelegate = address(3);
        _polStakeHelper.setDelegate(newDelegate);
        vm.stopPrank();

        assertEq(address(_polStakeHelper.delegate()), newDelegate);
    }

    function testOperatorCanSetDelegate() public {
        vm.startPrank(_operator);
        address newDelegate = address(3);
        _polStakeHelper.setDelegate(newDelegate);
        vm.stopPrank();

        assertEq(address(_polStakeHelper.delegate()), newDelegate);
    }

    function testNonAdminOrOperatorCannotSetBeneficiary() public {
        vm.startPrank(_randomJoe);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                _randomJoe,
                _adminRole
            )
        );
        _polStakeHelper.setBeneficiary(address(3));
        vm.stopPrank();
    }

    function testNonAdminOrOperatorCannotSetDelegate() public {
        vm.startPrank(_randomJoe);
        vm.expectRevert("NOT_ALLOWED");
        _polStakeHelper.setDelegate(address(3));
        vm.stopPrank();
    }
}
