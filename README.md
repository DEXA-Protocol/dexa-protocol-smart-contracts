# DEXA Protocol Smart Contracts

This repository contains the smart contracts for the DEXA Protocol, including the Researcher Hub, Open Data Marketplace, and Governance features.

## Contracts Overview

1. **ResearcherHub.sol**
   - Handles paper uploads to IPFS
   - Manages peer review system
   - Tracks reviewer reputation scores

2. **DataMarketplace.sol**
   - Manages dataset uploads and sales
   - Handles NFT-based access control
   - Implements revenue sharing between researchers and platform

3. **Governance.sol**
   - Implements DAO voting system
   - Manages proposals and voting using EDU tokens
   - Handles proposal execution

## Setup

1. Install dependencies:
```bash
npm install
```

2. Create a `.env` file with the following variables:
```
EDUCHAIN_RPC_URL=your_rpc_url
PRIVATE_KEY=your_private_key
```

3. Compile contracts:
```bash
npx hardhat compile
```

## Deployment

1. Deploy EDU token first (if not already deployed)
2. Deploy the contracts in the following order:
   - ResearcherHub
   - DataMarketplace
   - Governance

Example deployment script:
```javascript
const eduToken = await ethers.getContractFactory("EDUToken");
const eduTokenInstance = await eduToken.deploy();
await eduTokenInstance.deployed();

const researcherHub = await ethers.getContractFactory("ResearcherHub");
const researcherHubInstance = await researcherHub.deploy(eduTokenInstance.address);
await researcherHubInstance.deployed();

const dataMarketplace = await ethers.getContractFactory("DataMarketplace");
const dataMarketplaceInstance = await dataMarketplace.deploy(eduTokenInstance.address);
await dataMarketplaceInstance.deployed();

const governance = await ethers.getContractFactory("Governance");
const governanceInstance = await governance.deploy(eduTokenInstance.address, ethers.utils.parseEther("1000"));
await governanceInstance.deployed();
```

## Integration with Frontend

1. Copy the contract ABIs from `artifacts/contracts/` after compilation
2. Update the contract addresses in your frontend configuration
3. Use Web3.js or Ethers.js to interact with the contracts

Example frontend integration:
```javascript
import { ethers } from 'ethers';
import ResearcherHubABI from './abis/ResearcherHub.json';
import DataMarketplaceABI from './abis/DataMarketplace.json';
import GovernanceABI from './abis/Governance.json';

const provider = new ethers.providers.Web3Provider(window.ethereum);
const signer = provider.getSigner();

const researcherHub = new ethers.Contract(
  RESEARCHER_HUB_ADDRESS,
  ResearcherHubABI,
  signer
);

// Example: Upload a paper
async function uploadPaper(ipfsHash) {
  try {
    const tx = await researcherHub.uploadPaper(ipfsHash);
    await tx.wait();
    console.log('Paper uploaded successfully');
  } catch (error) {
    console.error('Error uploading paper:', error);
  }
}
```

## Testing

Run the test suite:
```bash
npx hardhat test
```

## Security

- All contracts use OpenZeppelin's standard contracts for security
- ReentrancyGuard is implemented where necessary
- Access control is managed through Ownable and custom modifiers
- All external functions are properly validated

## License

MIT 