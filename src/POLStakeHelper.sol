// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/IPolygonMigration.sol";
import "./interfaces/IStakeManager.sol";

/// @title POLStakeHelper
/// @notice Upgradeable contract for validators to allow a third party
// to delegate to them in POL, transparently converting to and from MATIC.
contract POLStakeHelper is AccessControlUpgradeable {
    using SafeERC20 for IERC20;

    /// @notice Access control roles.
    bytes32 public constant ROLE_ADMIN = keccak256("ADMIN");
    bytes32 public constant ROLE_OPERATOR = keccak256("OPERATOR");

    /// @notice POL token.
    IERC20 public pol;

    /// @notice MATIC token.
    IERC20 public matic;

    /// @notice Contract for POL<->MATIC conversions.
    IPolygonMigration public polMigrator;

    /// @notice Contract for MATIC staking.
    IStakeManager public stakeManager;

    /// @notice Delegate for staking.
    address public delegate; // TODO: not needed?
    bytes public delegateKey;

    /// @notice Beneficiary for rewards and unstaked tokens.
    address public beneficiary;

    /// @notice Validator identifier used for subsequent calls to StakeManager.
    uint256 public validatorId;

    /// @notice Custom modifier for admin or operator gated functions.
    modifier onlyAdminOrOperator() {
        require(
            hasRole(ROLE_ADMIN, msg.sender) ||
                hasRole(ROLE_OPERATOR, msg.sender),
            "NOT_ALLOWED"
        );
        _;
    }

    constructor() {
        _disableInitializers();
    }

    /// @notice Setup the state for the proxy's implementation.
    function initialize(
        address admin,
        address pol_,
        address matic_,
        address polMigrator_,
        address stakeManager_,
        address delegate_,
        bytes memory delegateKey_,
        address beneficiary_
    ) external initializer {
        // TODO: add access control to initialization function

        __AccessControl_init(); // does nothing, but keeping it here as best practice

        pol = IERC20(pol_);
        matic = IERC20(matic_);
        polMigrator = IPolygonMigration(polMigrator_);
        stakeManager = IStakeManager(stakeManager_);

        delegate = delegate_;
        beneficiary = beneficiary_;
        delegateKey = delegateKey_;

        // configure unlimited approval of MATIC for staking and migrator contracts
        matic.approve(address(stakeManager), type(uint256).max); // for stakeFor/restake
        matic.approve(address(polMigrator), type(uint256).max); // for migrate
        // configure unlimited approval of POL for migrator contract
        pol.approve(address(polMigrator), type(uint256).max); // for unmigrate

        // configure access control
        _setRoleAdmin(ROLE_OPERATOR, ROLE_ADMIN); // set ROLE_ADMIN as the admin role for ROLE_OPERATOR
        _grantRole(ROLE_ADMIN, admin); // grant ROLE_ADMIN to `admin`
    }

    /// @notice This function transfer `amount` of POL into the contract,
    /// uses the `PolygonMigrator` contract to convert it to MATIC, and
    /// then stakes the MATIC, delegating it to `delegate`.
    function stakePOL(uint256 amount) external onlyAdminOrOperator {
        uint256 fee = stakeManager.minHeimdallFee();
        require(amount > fee, "INVALID_AMT");

        // transfer POL from sender to this contract
        pol.safeTransferFrom(msg.sender, address(this), amount);

        // convert POL to MATIC
        // NOTE: already approved unlimited spending for the migrator (in the initializer)
        polMigrator.unmigrate(amount);

        // NOTE: already approved unlimited spending for the stake manager (in the initializer)
        if (validatorId == 0) {
            // first time staking (or after unstake)
            stakeManager.stakeFor(
                address(this),
                amount - fee,
                fee,
                false,
                delegateKey
            );
            // store the validatorId for future calls
            validatorId = stakeManager.getValidatorId(address(this));
        } else {
            // stakeFor was already called before and the validatorId is still valid
            stakeManager.restake(validatorId, amount, true); // TODO: stakeRewards
        }
    }

    /// @notice This function unstakes the MATIC, using the PolygonMigrator
    /// to convert it to POL, and then sends it to the `beneficiary`.
    function unstakePOL() external onlyAdminOrOperator {
        require(validatorId != 0, "NO_STAKE_YET");

        // unstake the MATIC
        stakeManager.unstake(validatorId);

        // reset validator id
        validatorId = 0;

        uint256 amount = matic.balanceOf(address(this));
        if (amount > 0) {
            // convert MATIC to POL
            // NOTE: already approved unlimited spending for the migrator (in the initializer)
            polMigrator.migrate(amount);

            // transfer the POL to the beneficiary
            pol.safeTransfer(beneficiary, amount);
        }
    }

    /// @notice This function calls withdrawRewards on the staking contract,
    /// converting the MATIC rewards into POL, sending it to the `beneficiary`.
    function claimRewards() external onlyAdminOrOperator {
        require(validatorId != 0, "NO_STAKE_YET");

        // withdraw the rewards from staking
        stakeManager.withdrawRewards(validatorId);
        uint256 amtRewards = matic.balanceOf(address(this));
        require(amtRewards > 0, "NO_REWARDS");

        // convert MATIC to POL
        // NOTE: already approved unlimited spending for the migrator (in the initializer)
        polMigrator.migrate(amtRewards);

        // transfer the POL to the beneficiary
        pol.safeTransfer(beneficiary, amtRewards);
    }

    /// @notice Sets a new beneficiary address.
    function setBeneficiary(
        address newBeneficiary
    ) external onlyRole(ROLE_ADMIN) {
        require(newBeneficiary != address(0), "INVALID_ADDR");

        beneficiary = newBeneficiary;
    }
}
