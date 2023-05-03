// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface ILosslessGovernance {
    function tokenOwnersVote(uint256 _reportID, bool _vote) external;
}