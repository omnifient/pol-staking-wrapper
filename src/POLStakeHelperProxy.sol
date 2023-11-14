// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract POLStakeHelperProxy is TransparentUpgradeableProxy {
    constructor(
        address proxyAdmin,
        address impl_,
        bytes memory data_
    ) payable TransparentUpgradeableProxy(impl_, proxyAdmin, data_) {}
}
