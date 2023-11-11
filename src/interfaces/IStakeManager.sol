pragma solidity ^0.8.23;

abstract contract IStakeManager {
    // validator replacement
    function startAuction(
        uint256 validatorId,
        uint256 amount,
        bool acceptDelegation,
        bytes calldata signerPubkey
    ) external virtual;

    function confirmAuctionBid(
        uint256 validatorId,
        uint256 heimdallFee
    ) external virtual;

    function transferFunds(
        uint256 validatorId,
        uint256 amount,
        address delegator
    ) external virtual returns (bool);

    function delegationDeposit(
        uint256 validatorId,
        uint256 amount,
        address delegator
    ) external virtual returns (bool);

    function stake(
        uint256 amount,
        uint256 heimdallFee,
        bool acceptDelegation,
        bytes calldata signerPubkey
    ) external virtual;

    function unstake(uint256 validatorId) external virtual;

    function totalStakedFor(
        address addr
    ) external view virtual returns (uint256);

    function stakeFor(
        address user,
        uint256 amount,
        uint256 heimdallFee,
        bool acceptDelegation,
        bytes memory signerPubkey
    ) public virtual;

    function checkSignatures(
        uint256 blockInterval,
        bytes32 voteHash,
        bytes32 stateRoot,
        address proposer,
        bytes memory sigs
    ) public virtual returns (uint256);

    function updateValidatorState(
        uint256 validatorId,
        int256 amount
    ) public virtual;

    function ownerOf(uint256 tokenId) public view virtual returns (address);

    function slash(
        bytes memory slashingInfoList
    ) public virtual returns (uint256);

    function validatorStake(
        uint256 validatorId
    ) public view virtual returns (uint256);

    function epoch() public view virtual returns (uint256);

    function withdrawalDelay() public view virtual returns (uint256);
}
