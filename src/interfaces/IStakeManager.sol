pragma solidity ^0.8.23;

abstract contract IStakeManager {
    function getValidatorId(address user) public view virtual returns (uint256);

    function stake(
        uint256 amount,
        uint256 heimdallFee,
        bool acceptDelegation,
        bytes calldata signerPubkey
    ) external virtual;

    function stakeFor(
        address user,
        uint256 amount,
        uint256 heimdallFee,
        bool acceptDelegation,
        bytes memory signerPubkey
    ) public virtual;

    function unstake(uint256 validatorId) external virtual;

    function withdrawRewards(uint256 validatorId) public virtual;
}
