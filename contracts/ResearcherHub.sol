// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ResearcherHub is Ownable, ReentrancyGuard {
    IERC20 public eduToken;
    
    struct Paper {
        string ipfsHash;
        address researcher;
        uint256 timestamp;
        bool isVerified;
        uint256 reviewCount;
        mapping(address => Review) reviews;
    }
    
    struct Review {
        string feedback;
        uint256 rating;
        bool isValidated;
        uint256 timestamp;
    }
    
    struct Reviewer {
        uint256 reputationScore;
        uint256 totalReviews;
        uint256 validatedReviews;
    }
    
    mapping(uint256 => Paper) public papers;
    mapping(address => Reviewer) public reviewers;
    uint256 public paperCount;
    
    event PaperUploaded(uint256 indexed paperId, string ipfsHash, address researcher);
    event ReviewSubmitted(uint256 indexed paperId, address reviewer, string feedback);
    event ReviewValidated(uint256 indexed paperId, address reviewer);
    
    constructor(address _eduToken) {
        eduToken = IERC20(_eduToken);
    }
    
    function uploadPaper(string memory _ipfsHash) external {
        require(bytes(_ipfsHash).length > 0, "Invalid IPFS hash");
        
        uint256 paperId = paperCount++;
        Paper storage paper = papers[paperId];
        paper.ipfsHash = _ipfsHash;
        paper.researcher = msg.sender;
        paper.timestamp = block.timestamp;
        
        emit PaperUploaded(paperId, _ipfsHash, msg.sender);
    }
    
    function submitReview(uint256 _paperId, string memory _feedback, uint256 _rating) external {
        require(_paperId < paperCount, "Paper does not exist");
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5");
        
        Paper storage paper = papers[_paperId];
        paper.reviews[msg.sender] = Review({
            feedback: _feedback,
            rating: _rating,
            isValidated: false,
            timestamp: block.timestamp
        });
        
        paper.reviewCount++;
        
        emit ReviewSubmitted(_paperId, msg.sender, _feedback);
    }
    
    function validateReview(uint256 _paperId, address _reviewer) external {
        require(_paperId < paperCount, "Paper does not exist");
        Paper storage paper = papers[_paperId];
        require(paper.reviews[_reviewer].timestamp > 0, "Review does not exist");
        require(!paper.reviews[_reviewer].isValidated, "Review already validated");
        
        paper.reviews[_reviewer].isValidated = true;
        
        Reviewer storage reviewer = reviewers[_reviewer];
        reviewer.reputationScore += 10;
        reviewer.validatedReviews++;
        
        emit ReviewValidated(_paperId, _reviewer);
    }
    
    function getReviewerScore(address _reviewer) external view returns (uint256) {
        return reviewers[_reviewer].reputationScore;
    }
    
    function getPaperReviews(uint256 _paperId) external view returns (
        uint256 reviewCount,
        uint256[] memory ratings,
        string[] memory feedbacks,
        address[] memory reviewerAddresses
    ) {
        Paper storage paper = papers[_paperId];
        reviewCount = paper.reviewCount;
        
        ratings = new uint256[](reviewCount);
        feedbacks = new string[](reviewCount);
        reviewerAddresses = new address[](reviewCount);
        
        uint256 index = 0;
        for (uint256 i = 0; i < reviewCount; i++) {
            address reviewer = address(uint160(uint256(keccak256(abi.encodePacked(_paperId, i)))));
            if (paper.reviews[reviewer].timestamp > 0) {
                ratings[index] = paper.reviews[reviewer].rating;
                feedbacks[index] = paper.reviews[reviewer].feedback;
                reviewerAddresses[index] = reviewer;
                index++;
            }
        }
    }
} 