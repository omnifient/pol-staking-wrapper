// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

contract POLStakeHelper {
    // TODO: upgradeable proxy

    // IERC20 constant pol;
    // IERC20 constant matic;
    // address constant polMigrator;
    // address constant stakingManager;

    address public delegate;
    address public beneficiary;

    constructor(address delegate_, address beneficiary_) {
        // TODO: TBI
        delegate = delegate_;
        beneficiary = beneficiary_;

        // TODO: set admin
    }

    // TODO: admin, operator roles

    function stakePOL(uint256 amount) external {
        // TODO: TBI
        // TODO: onlyAdminOrOperator
        //
        // pol.safeTransfer(msg.sender, address(this), amount);
        // polMigrator.unmigrate(polAmount)
        //
        // stakingManager.stakeFor(amount, ..) where is delegate used?
    }

    function unstakePOL(uint256 amount) external {
        // TODO: TBI
        // TODO: onlyAdminOrOperator
        //
        // stakingManager.unstake(amount, ..) where is delegate used?
        //
        // polMigrator.migrate(maticAmount)
        // pol.safeTransfer(address(this), beneficiary, amount);
    }

    function claimRewards() external {
        // TODO: TBI
        // TODO: onlyAdminOrOperator
        //
        // stakingManager.withdrawRewards(...)
        // polMigrator.migrate(maticAmount)
        // pol.safeTransfer(address(this), beneficiary, amtRewards);
    }

    function setBeneficiary(address newBeneficiary) external {
        // TODO: TBI
        // TODO: onlyAdmin
        beneficiary = newBeneficiary;
    }

    function addOperator(address newOperator) external {
        // TODO: use access control library?
        // TODO: TBI
        // TODO: onlyAdmin
    }

    function removeOperator(address op) external {
        // TODO: use access control library?
        // TODO: TBI
        // TODO: onlyAdmin
    }
}
