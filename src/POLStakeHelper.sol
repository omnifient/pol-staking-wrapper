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
        // TODO: onlyAdminOrOperator
        require(amount > 0, "INVALID_AMT");

        // transfer POL from sender to this contract
        pol.safeTransferFrom(msg.sender, address(this), amount);

        // convert POL to MATIC
        polMigrator.unmigrate(amount); // TODO: use unmigrateWithPermit for spending approval

        // approve spending for the staking manager - TODO: do this once with max amount?
        matic.approve(address(stakingManager), amount);

        // TODO: stake the MATIC
        // stakingManager.stake(amount, ..) // how to use the delegate?
    }

    /// @notice TBW
    function unstakePOL(uint256 amount) external {
        // TODO: onlyAdminOrOperator
        require(amount > 0, "INVALID_AMT");

        // TODO: unstake the MATIC
        // stakingManager.unstake(amount, ..) where is delegate used?

        // allow the migrator to spend the MATIC - TODO: do this once with max amount?
        matic.approve(address(polMigrator), amount);

        // call migrator to convert the MATIC to POL
        polMigrator.migrate(amount);

        // transfer the POL to the beneficiary
        pol.safeTransfer(beneficiary, amount);
    }

    /// @notice TBW
    function claimRewards() external {
        // TODO: onlyAdminOrOperator

        // get the validator id (TODO: maybe store this in the contract after staking?)
        uint256 validatorId = stakingManager.getValidatorId(address(this));
        // withdraw the rewards from staking
        stakingManager.withdrawRewards(validatorId);
        uint256 amtRewards = matic.balanceOf(address(this));
        require(amtRewards > 0, "NO_REWARDS");

        // allow the migrator to spend the MATIC - TODO: do this once with max amount?
        matic.approve(address(polMigrator), amtRewards);

        // call migrator to convert the MATIC to POL
        polMigrator.migrate(amtRewards);

        // transfer the POL to the beneficiary
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
