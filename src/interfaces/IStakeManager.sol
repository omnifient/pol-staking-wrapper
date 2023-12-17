pragma solidity ^0.8.23;

abstract contract IStakeManager {
    function getValidatorId(address user) public view virtual returns (uint256);

    function getValidatorContract(
        uint256 validatorId
    ) public view virtual returns (address);

    function minHeimdallFee() public view virtual returns (uint256);

    function stakeFor(
        address user,
        uint256 amount,
        uint256 heimdallFee,
        bool acceptDelegation,
        bytes memory signerPubkey
    ) public virtual;

    function restake(
        uint256 validatorId,
        uint256 amount,
        bool stakeRewards
    ) public virtual;

    function unstake(uint256 validatorId) external virtual;

    function withdrawRewards(uint256 validatorId) public virtual;

    function validatorThreshold() public view virtual returns (uint256);

    function updateValidatorThreshold(uint256 validatorId) public virtual;

    function token() external view virtual returns (address);

    function epoch() external view virtual returns (uint256);

    function setCurrentEpoch(uint256 _currentEpoch) external virtual;

    function withdrawalDelay() external view virtual returns (uint256);
}
