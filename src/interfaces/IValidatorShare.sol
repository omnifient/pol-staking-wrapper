// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

interface IValidatorShare {
    function buyVoucher(
        uint256 _amount,
        uint256 _minSharesToMint
    ) external returns (uint256 amountToDeposit);

    function sellVoucher(
        uint256 claimAmount,
        uint256 maximumSharesToBurn
    ) external;

    function unstakeClaimTokens() external;

    function sellVoucher_new(
        uint256 claimAmount,
        uint256 maximumSharesToBurn
    ) external;

    function unstakeClaimTokens_new(uint256 unbondNonce) external;
}
