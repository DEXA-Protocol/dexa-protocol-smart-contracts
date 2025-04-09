// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DataMarketplace is ERC721, Ownable, ReentrancyGuard {
    IERC20 public eduToken;
    
    struct Dataset {
        string ipfsHash;
        address researcher;
        uint256 price;
        uint256 totalSales;
        bool isActive;
    }
    
    mapping(uint256 => Dataset) public datasets;
    mapping(uint256 => mapping(address => bool)) public hasAccess;
    uint256 public datasetCount;
    uint256 public platformFee = 10; // 10% platform fee
    
    event DatasetUploaded(uint256 indexed datasetId, string ipfsHash, address researcher, uint256 price);
    event DatasetPurchased(uint256 indexed datasetId, address buyer, uint256 price);
    
    constructor(address _eduToken) ERC721("DEXA Dataset", "DEXA") {
        eduToken = IERC20(_eduToken);
    }
    
    function uploadDataset(string memory _ipfsHash, uint256 _price) external {
        require(bytes(_ipfsHash).length > 0, "Invalid IPFS hash");
        require(_price > 0, "Price must be greater than 0");
        
        uint256 datasetId = datasetCount++;
        datasets[datasetId] = Dataset({
            ipfsHash: _ipfsHash,
            researcher: msg.sender,
            price: _price,
            totalSales: 0,
            isActive: true
        });
        
        emit DatasetUploaded(datasetId, _ipfsHash, msg.sender, _price);
    }
    
    function purchaseDataset(uint256 _datasetId) external nonReentrant {
        Dataset storage dataset = datasets[_datasetId];
        require(dataset.isActive, "Dataset is not active");
        require(!hasAccess[_datasetId][msg.sender], "Already purchased");
        
        uint256 price = dataset.price;
        require(eduToken.transferFrom(msg.sender, address(this), price), "Transfer failed");
        
        // Calculate shares
        uint256 platformShare = (price * platformFee) / 100;
        uint256 researcherShare = price - platformShare;
        
        // Transfer to researcher
        require(eduToken.transfer(dataset.researcher, researcherShare), "Researcher transfer failed");
        
        // Update state
        hasAccess[_datasetId][msg.sender] = true;
        dataset.totalSales++;
        
        // Mint NFT for access
        _mint(msg.sender, _datasetId);
        
        emit DatasetPurchased(_datasetId, msg.sender, price);
    }
    
    function setPlatformFee(uint256 _newFee) external onlyOwner {
        require(_newFee <= 20, "Fee cannot exceed 20%");
        platformFee = _newFee;
    }
    
    function getDatasetInfo(uint256 _datasetId) external view returns (
        string memory ipfsHash,
        address researcher,
        uint256 price,
        uint256 totalSales,
        bool isActive
    ) {
        Dataset storage dataset = datasets[_datasetId];
        return (
            dataset.ipfsHash,
            dataset.researcher,
            dataset.price,
            dataset.totalSales,
            dataset.isActive
        );
    }
    
    function checkAccess(uint256 _datasetId, address _user) external view returns (bool) {
        return hasAccess[_datasetId][_user];
    }
} 