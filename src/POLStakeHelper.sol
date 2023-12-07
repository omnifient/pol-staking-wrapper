// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/IPolygonMigration.sol";
import "./interfaces/IValidatorShare.sol";

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

    /// @notice Contract for MATIC delegate for staking.
    IValidatorShare public delegate;

    /// @notice Beneficiary for rewards and unstaked tokens.
    address public beneficiary;

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
        address beneficiary_,
        address stakeManager_
    ) external initializer {
        // TODO: add access control to initialization function

        __AccessControl_init(); // does nothing, but keeping it here as best practice

        pol = IERC20(pol_);
        matic = IERC20(matic_);
        polMigrator = IPolygonMigration(polMigrator_);
        beneficiary = beneficiary_;

        // configure unlimited approval of MATIC for staking and migrator contracts
        matic.approve(stakeManager_, type(uint256).max); // for stake/restake
        matic.approve(polMigrator_, type(uint256).max); // for migrate
        // configure unlimited approval of POL for migrator contract
        pol.approve(polMigrator_, type(uint256).max); // for unmigrate

        // configure access control
        _setRoleAdmin(ROLE_OPERATOR, ROLE_ADMIN); // set ROLE_ADMIN as the admin role for ROLE_OPERATOR
        _grantRole(ROLE_ADMIN, admin); // grant ROLE_ADMIN to `admin`
    }

    function setDelegate(address delegate_) external onlyAdminOrOperator {
        delegate = IValidatorShare(delegate_);
    }

    /// @notice This function transfers `amount` of POL into the contract,
    /// uses `PolygonMigrator` to convert it to MATIC, and then stakes the
    // MATIC by delegating it to `delegate`.
    function stakePOL(uint256 amount) external onlyAdminOrOperator {
        require(amount > 0, "INVALID_AMT");

        // transfer POL from sender to this contract
        pol.safeTransferFrom(msg.sender, address(this), amount);

        // convert POL to MATIC
        // NOTE: already approved unlimited spending for the migrator (in the initializer)
        polMigrator.unmigrate(amount);

        // NOTE: already approved unlimited spending for the stake manager (in the initializer)
        // (stake manager - not the delegate - is the contract that actually transfers the funds)
        // NOTE: `buyVoucher` distributes rewards before staking
        // they will remain in POLStakeHelper until `claimRewards` is called
        delegate.buyVoucher(amount, amount);
    }

    /// @notice This function tells the delegate to unstake `amount` of MATIC.
    /// The unstaking process is asynchronous; a subsequent call to `transferUnstakedPOL`
    /// will transfer the unstaked tokens to the beneficiary.
    function unstakePOL(uint256 amount) external onlyAdminOrOperator {
        require(amount > 0, "INVALID_AMT");
        // TODO: require(amount <= delegate.balanceOf(address(this)) * delegate.exchangeRate(), "INSUFFICIENT_BAL");

        // initiate the unstaking of MATIC
        delegate.sellVoucher(amount, amount);
    }

    /// @notice Transfers the unstaked tokens, first by converting the unstaked
    /// MATIC to POL using the PolygonMigrator, and then sending it to the `beneficiary`.
    function transferUnstakedPOL() external onlyAdminOrOperator {
        // claim the unstaked MATIC
        delegate.unstakeClaimTokens();

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
        // TODO: require(validatorId != 0, "NO_STAKE_YET");

        // withdraw the rewards from staking
        delegate.withdrawRewards();

        uint256 amtRewards = matic.balanceOf(address(this));
        if (amtRewards > 0) {
            // convert MATIC to POL
            // NOTE: already approved unlimited spending for the migrator (in the initializer)
            polMigrator.migrate(amtRewards);

            // transfer the POL to the beneficiary
            pol.safeTransfer(beneficiary, amtRewards);
        }
    }

    /// @notice Sets a new beneficiary address.
    function setBeneficiary(
        address newBeneficiary
    ) external onlyRole(ROLE_ADMIN) {
        require(newBeneficiary != address(0), "INVALID_ADDR");

        beneficiary = newBeneficiary;
    }
}
