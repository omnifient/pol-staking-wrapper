// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract POLStakeHelper {
    using SafeERC20 for IERC20;

    IERC20 immutable pol;
    IERC20 immutable matic;
    address immutable polMigrator; // TODO: replace with interface
    address immutable stakingManager; // TODO: replace with interface

    address public delegate;
    address public beneficiary;

    constructor(
        address pol_,
        address matic_,
        address polMigrator_,
        address stakingManager_,
        address delegate_,
        address beneficiary_
    ) {
        pol = IERC20(pol_);
        matic = IERC20(matic_);
        polMigrator = polMigrator_;
        stakingManager = stakingManager_;

        delegate = delegate_;
        beneficiary = beneficiary_;

        // TODO: set admin
    }

    // TODO: admin, operator roles

    function stakePOL(uint256 amount) external {
        // TODO: TBI
        // TODO: onlyAdminOrOperator

        require(amount > 0, "INVALID_AMT");

        pol.safeTransferFrom(msg.sender, address(this), amount);
        // polMigrator.unmigrate(polAmount)

        // stakingManager.stakeFor(amount, ..) where is delegate used?
    }

    function unstakePOL(uint256 amount) external {
        // TODO: TBI
        // TODO: onlyAdminOrOperator

        require(amount > 0, "INVALID_AMT");

        // stakingManager.unstake(amount, ..) where is delegate used?

        // polMigrator.migrate(maticAmount)
        pol.safeTransfer(beneficiary, amount);
    }

    function claimRewards() external {
        // TODO: TBI
        // TODO: onlyAdminOrOperator

        uint256 amtRewards = 0;
        // stakingManager.withdrawRewards(...)
        // polMigrator.migrate(maticAmount)
        pol.safeTransfer(beneficiary, amtRewards);
    }

    function setBeneficiary(address newBeneficiary) external {
        // TODO: TBI
        // TODO: onlyAdmin

        require(newBeneficiary != address(0), "INVALID_ADDR");

        beneficiary = newBeneficiary;
    }

    function addOperator(address newOperator) external {
        // TODO: use access control library?
        // TODO: TBI
        // TODO: onlyAdmin

        require(newOperator != address(0), "INVALID_ADDR");
    }

    function removeOperator(address op) external {
        // TODO: use access control library?
        // TODO: TBI
        // TODO: onlyAdmin

        require(op != address(0), "INVALID_ADDR");
    }
}
