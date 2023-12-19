pragma solidity ^0.8.23;

import "lib/forge-std/src/Test.sol";

import "./Base.t.sol";

import "../../src/POLStakeHelperProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ProxyTests is Base {
    event Upgraded(address indexed implementation);

    function setUp() public override {
        super.setUp();
    }

    function testAdminCanUpgrade() public {
        address newImplementation = address(new POLStakeHelper());

        // get the ProxyAdmin address
        bytes32 slot = bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1);
        bytes32 proxyAdminLoad = vm.load(address(_polStakeHelper), slot);
        ProxyAdmin proxyAdmin = ProxyAdmin(
            address(uint160(uint256(proxyAdminLoad)))
        );

        vm.startPrank(_admin);
        vm.expectEmit(address(_polStakeHelper));
        emit Upgraded(newImplementation);
        proxyAdmin.upgradeAndCall(
            ITransparentUpgradeableProxy(address(_polStakeHelper)),
            newImplementation,
            bytes("") // initializer already called in deploy script
        );
    }

    function testRevertNonAdminCannotUpgrade() public {
        address newImplementation = address(new POLStakeHelper());

        // get the ProxyAdmin address
        bytes32 slot = bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1);
        bytes32 proxyAdminLoad = vm.load(address(_polStakeHelper), slot);
        ProxyAdmin proxyAdmin = ProxyAdmin(
            address(uint160(uint256(proxyAdminLoad)))
        );

        vm.startPrank(_randomJoe);

        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                _randomJoe
            )
        );

        proxyAdmin.upgradeAndCall(
            ITransparentUpgradeableProxy(address(_polStakeHelper)),
            newImplementation,
            bytes("")
        );
    }
}
