// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IPolygonMigration.sol";
import "./interfaces/IStakeManager.sol";

/// @title POLStakeHelper
/// @notice TBW
contract POLStakeHelper {
    using SafeERC20 for IERC20;

    /// @notice POL token
    IERC20 immutable pol;

    /// @notice MATIC token
    IERC20 immutable matic;

    /// @notice contract for POL<->MATIC conversions
    IPolygonMigration immutable polMigrator;

    /// @notice contract for MATIC staking
    IStakeManager immutable stakingManager;

    /// @notice delegate for staking
    address public delegate;

    /// @notice beneficiary for rewards and unstake
    address public beneficiary;

    // TODO: admin, operator roles

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
        polMigrator = IPolygonMigration(polMigrator_);
        stakingManager = IStakeManager(stakingManager_);

        delegate = delegate_;
        beneficiary = beneficiary_;

        // TODO: set admin
    }

    /// @notice TBW
    function stakePOL(uint256 amount) external {
        // TODO: TBI
        // TODO: onlyAdminOrOperator

        require(amount > 0, "INVALID_AMT");

        pol.safeTransferFrom(msg.sender, address(this), amount);

        // TODO: does this need any approval? use permit version
        polMigrator.unmigrate(amount);
        // TODO: does this need any approval?
        // stakingManager.stakeFor(amount, ..) where is delegate used?
    }

    /// @notice TBW
    function unstakePOL(uint256 amount) external {
        // TODO: TBI
        // TODO: onlyAdminOrOperator

        require(amount > 0, "INVALID_AMT");

        // stakingManager.unstake(amount, ..) where is delegate used?

        // TODO: does this need any approval? use permit version
        polMigrator.migrate(amount);
        pol.safeTransfer(beneficiary, amount);
    }

    /// @notice TBW
    function claimRewards() external {
        // TODO: TBI
        // TODO: onlyAdminOrOperator

        uint256 amtRewards = 0;
        // stakingManager.withdrawRewards(...)
        // TODO: does this need any approval? use permit version
        polMigrator.migrate(amtRewards);
        pol.safeTransfer(beneficiary, amtRewards);
    }

    /// @notice TBW
    function setBeneficiary(address newBeneficiary) external {
        // TODO: onlyAdmin

        require(newBeneficiary != address(0), "INVALID_ADDR");

        beneficiary = newBeneficiary;
    }

    /// @notice TBW
    function addOperator(address newOperator) external {
        // TODO: use access control library?
        // TODO: TBI
        // TODO: onlyAdmin

        require(newOperator != address(0), "INVALID_ADDR");
    }

    /// @notice TBW
    function removeOperator(address op) external {
        // TODO: use access control library?
        // TODO: TBI
        // TODO: onlyAdmin

        require(op != address(0), "INVALID_ADDR");
    }
}
