# Digital Art Collaboration Platform

## Overview
A Stacks blockchain smart contract for collaborative digital art creation and NFT minting, enabling artists to register, create artworks, collaborate, and sell their digital creations.

## Key Features
- Artist Registration
- Collaborative Artwork Creation
- Contribution Tracking
- Artwork Finalization
- NFT Minting
- Royalty Distribution

## Contract Functions

### Artist Management
- `register-artist`: Register a new artist with a name
- `get-artist-info`: Retrieve artist information

### Artwork Management
- `create-artwork`: Create a new artwork
- `add-contribution`: Add contributions to an existing artwork
- `finalize-artwork`: Finalize an artwork for NFT minting
- `get-artwork-info`: Retrieve artwork details

### NFT Marketplace
- `mint-nft`: Create an NFT for a finalized artwork
- `buy-nft`: Purchase an existing NFT
- `get-nft-info`: Retrieve NFT information

## Royalty Distribution
Royalties are distributed proportionally based on each collaborator's contribution percentage when an NFT is sold.

## Error Handling
The contract includes specific error codes for various scenarios:
- Owner-only actions
- Not found resources
- Unauthorized operations
- Duplicate registrations
- Invalid percentages

## Requirements
- Stacks blockchain
- Compatible wallet (e.g., Hiro Wallet)

## Security Considerations
- Only registered artists can create and collaborate on artworks
- Artwork must be finalized before NFT minting
- Royalty distribution is automatic and proportional
