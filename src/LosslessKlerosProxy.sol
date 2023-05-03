// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {ILosslessGovernance} from "./ILosslessGovernance.sol";
import {IArbitrableProxy} from "./IArbitrableProxy.sol";
import {IKlerosLiquid} from "./IKlerosLiquid.sol";

contract LosslessKlerosProxy {
    struct Dispute {
        uint256 disputeID;
        bool isExecuted;
    }

    address public governor;
    ILosslessGovernance public losslessGovernance;
    IArbitrableProxy public arbitrableProxy;
    IKlerosLiquid public klerosLiquid;
    uint256 public courtID;
    uint256 public numberOfJurors;
    string public metaevidenceURI;
    mapping(uint256 => Dispute) public reportIDToDispute;

    event ArbitrationExecution(uint256 _reportID);

    constructor(
        address _governor,
        address _losslessGovernance,
        address _arbitrableProxy,
        address _klerosLiquid,
        uint256 _courtID,
        uint256 _numberOfJurors,
        string memory _metaevidenceURI
    ) {
        governor = _governor;
        losslessGovernance = ILosslessGovernance(_losslessGovernance);
        arbitrableProxy = IArbitrableProxy(_arbitrableProxy);
        klerosLiquid = IKlerosLiquid(_klerosLiquid);
        courtID = _courtID;
        numberOfJurors = _numberOfJurors;
        metaevidenceURI = _metaevidenceURI;
    }

    modifier onlyGovernor() {
        require(msg.sender == governor, "Not authorized: governor only");
        _;
    }

    function changeGovernor(address _newGovernor) public onlyGovernor {
        governor = _newGovernor;
    }

    function changeCourtID(uint256 _courtID) public onlyGovernor {
        courtID = _courtID;
    }

    function changeNumberOfJurors(uint256 _numberOfJurors) public onlyGovernor {
        numberOfJurors = _numberOfJurors;
    }

    function changeMetaevidenceURI(string memory _metaevidenceURI) public onlyGovernor {
        metaevidenceURI = _metaevidenceURI;
    }

    function requestArbitration(uint256 _reportID) public payable {
        require(reportIDToDispute[_reportID].disputeID == 0, "Dispute already created for this report");
        
        bytes memory extraData = abi.encodePacked(courtID, numberOfJurors);
        uint256 disputeID = arbitrableProxy.createDispute{value: msg.value}(extraData, metaevidenceURI, 2);
        reportIDToDispute[_reportID].disputeID = disputeID;
    }

    function executeVote(uint256 _reportID) public {
        Dispute storage dispute = reportIDToDispute[_reportID];
        require(dispute.disputeID != 0, "Dispute not found");
        require(dispute.isExecuted == false, "Already executed");

        (uint256 winningChoice, uint256[] memory counts, bool tied) = klerosLiquid.getVoteCounter(dispute.disputeID, 0);
        bool vote = winningChoice == 1 && !tied && counts[1] == numberOfJurors;
        require(vote, "Arbitration criteria not fulfilled");

        dispute.isExecuted = true;
        losslessGovernance.tokenOwnersVote(_reportID, vote);

        emit ArbitrationExecution(_reportID);
    }
}
