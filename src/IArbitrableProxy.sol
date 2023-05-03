// SPDX-License-Identifier: MIT

/// @authors: [@ferittuncer]
/// @reviewers: [@fnanni-0*, @unknownunknown1*, @mtsalenc*, @MerlinEgalite*, @shalzz*, hbarcelos]
/// @auditors: []
/// @bounties: []

pragma solidity ^0.8.18;

import {IArbitrableV1} from "./IArbitrableV1.sol";

/// @title ArbitrableProxy
/// A general purpose arbitrable contract. Supports non-binary rulings.
interface IArbitrableProxy is IArbitrableV1 {

    /// @dev TRUSTED. Calls createDispute function of the specified arbitrator to create a dispute.
    ///      Note that we don’t need to check that msg.value is enough to pay arbitration fees as it’s the responsibility of the arbitrator contract.
    /// @param _arbitratorExtraData Extra data for the arbitrator of prospective dispute.
    /// @param _metaevidenceURI Link to metaevidence of prospective dispute.
    /// @param _numberOfRulingOptions Number of ruling options.
    /// @return disputeID Dispute id (on arbitrator side) of the dispute created.
    function createDispute(
        bytes calldata _arbitratorExtraData,
        string calldata _metaevidenceURI,
        uint256 _numberOfRulingOptions
    ) external payable returns (uint256 disputeID);
}