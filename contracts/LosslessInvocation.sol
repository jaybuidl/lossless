// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LosslessGovernance.sol";
import "@kleros/arbitrable-proxy-contracts/contracts/ArbitrableProxy.sol";
import "@kleros/kleros/contracts/kleros/KlerosLiquid.sol";

contract VotingInvocation {
    address public governor;
    LosslessGovernance public losslessGovernance;
    IArbitrableProxy public arbitrableProxy;
    KlerosLiquid public klerosLiquid;

    uint256 public courtID;
    uint256 public numberOfJurors;
    string public metaevidenceURI;

    mapping(uint256 => uint256) public reportIDToDisputeID;

    constructor(
        address _governor,
        address _losslessGovernance,
        address _arbitrableProxy,
        address _klerosLiquid
    ) {
        governor = _governor;
        losslessGovernance = LosslessGovernance(_losslessGovernance);
        arbitrableProxy = IArbitrableProxy(_arbitrableProxy);
        klerosLiquid = KlerosLiquid(_klerosLiquid);
    }

    modifier onlyGovernor() {
        require(msg.sender == governor, "Only the governor can call this function.");
        _;
    }

    function setGovernor(address _newGovernor) public onlyGovernor {
        governor = _newGovernor;
    }

    function setCourtID(uint256 _courtID) public onlyGovernor {
        courtID = _courtID;
    }

    function setNumberOfJurors(uint256 _numberOfJurors) public onlyGovernor {
        numberOfJurors = _numberOfJurors;
    }

    function setMetaevidenceURI(string memory _metaevidenceURI) public onlyGovernor {
        metaevidenceURI = _metaevidenceURI;
    }

    function invokeVote(uint256 _reportID) public payable {
        require(reportIDToDisputeID[_reportID] == 0, "Dispute already created for this report.");

        bytes memory extraData = abi.encodePacked(courtID, numberOfJurors);
        uint256 arbitrationCost = klerosLiquid.arbitrationCost(extraData);

        require(msg.value >= arbitrationCost, "Not enough funds provided for arbitration.");

        uint256 disputeID = arbitrableProxy.createDispute{value: arbitrationCost}(
            extraData,
            metaevidenceURI,
            2
        );

        reportIDToDisputeID[_reportID] = disputeID;

        if (msg.value > arbitrationCost) {
            payable(msg.sender).transfer(msg.value - arbitrationCost);
        }
    }

    function checkInvocationCriteria(uint256 _reportID) public view returns (bool) {
        uint256 disputeID = reportIDToDisputeID[_reportID];
        require(disputeID != 0, "Dispute not found for this report.");

        (uint256 winningChoice, uint256[] memory counts, bool tied) = klerosLiquid.getVoteCounter(disputeID, 0);

        return (
            winningChoice == 1 &&
            !tied &&
            counts[1] == numberOfJurors
        );
    }

    function executeVote(uint256 _reportID) public {
        require(checkInvocationCriteria(_reportID), "Invocation criteria not fulfilled.");

        losslessGovernance.tokenOwnersVote(_reportID, true);
    }
}
