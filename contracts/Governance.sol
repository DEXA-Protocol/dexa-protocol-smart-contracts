// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Governance is Ownable, ReentrancyGuard {
    IERC20 public eduToken;
    
    struct Proposal {
        string description;
        uint256 startTime;
        uint256 endTime;
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        address proposer;
        mapping(address => bool) hasVoted;
    }
    
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;
    uint256 public minimumTokensToPropose;
    uint256 public votingPeriod = 3 days;
    
    event ProposalCreated(uint256 indexed proposalId, string description, address proposer);
    event VoteCast(uint256 indexed proposalId, address voter, bool support, uint256 votes);
    event ProposalExecuted(uint256 indexed proposalId);
    
    constructor(address _eduToken, uint256 _minimumTokensToPropose) {
        eduToken = IERC20(_eduToken);
        minimumTokensToPropose = _minimumTokensToPropose;
    }
    
    function createProposal(string memory _description) external {
        require(eduToken.balanceOf(msg.sender) >= minimumTokensToPropose, "Insufficient tokens to propose");
        
        uint256 proposalId = proposalCount++;
        Proposal storage proposal = proposals[proposalId];
        proposal.description = _description;
        proposal.startTime = block.timestamp;
        proposal.endTime = block.timestamp + votingPeriod;
        proposal.proposer = msg.sender;
        
        emit ProposalCreated(proposalId, _description, msg.sender);
    }
    
    function castVote(uint256 _proposalId, bool _support) external nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp >= proposal.startTime, "Voting not started");
        require(block.timestamp <= proposal.endTime, "Voting ended");
        require(!proposal.hasVoted[msg.sender], "Already voted");
        
        uint256 votes = eduToken.balanceOf(msg.sender);
        require(votes > 0, "No tokens to vote with");
        
        proposal.hasVoted[msg.sender] = true;
        
        if (_support) {
            proposal.forVotes += votes;
        } else {
            proposal.againstVotes += votes;
        }
        
        emit VoteCast(_proposalId, msg.sender, _support, votes);
    }
    
    function executeProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp > proposal.endTime, "Voting still in progress");
        require(!proposal.executed, "Proposal already executed");
        require(proposal.forVotes > proposal.againstVotes, "Proposal did not pass");
        
        proposal.executed = true;
        emit ProposalExecuted(_proposalId);
    }
    
    function getProposalInfo(uint256 _proposalId) external view returns (
        string memory description,
        uint256 startTime,
        uint256 endTime,
        uint256 forVotes,
        uint256 againstVotes,
        bool executed,
        address proposer
    ) {
        Proposal storage proposal = proposals[_proposalId];
        return (
            proposal.description,
            proposal.startTime,
            proposal.endTime,
            proposal.forVotes,
            proposal.againstVotes,
            proposal.executed,
            proposal.proposer
        );
    }
    
    function setVotingPeriod(uint256 _newPeriod) external onlyOwner {
        require(_newPeriod >= 1 days && _newPeriod <= 7 days, "Invalid voting period");
        votingPeriod = _newPeriod;
    }
    
    function setMinimumTokensToPropose(uint256 _newMinimum) external onlyOwner {
        minimumTokensToPropose = _newMinimum;
    }
} 