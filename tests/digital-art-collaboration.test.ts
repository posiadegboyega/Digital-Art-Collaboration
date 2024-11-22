import { describe, it, expect, beforeEach } from 'vitest';

// Mock Clarity contract state
let artists = new Map();
let artworks = new Map();
let nfts = new Map();
let lastArtworkId = 0;
let lastNftId = 0;

// Mock Clarity functions
function registerArtist(caller: string, name: string): { type: string; value: boolean } {
  if (artists.has(caller)) {
    return { type: 'err', value: 103 }; // err-already-exists
  }
  artists.set(caller, { name, registered: true });
  return { type: 'ok', value: true };
}

function createArtwork(caller: string, title: string, description: string): { type: string; value: number } {
  if (!artists.has(caller)) {
    return { type: 'err', value: 102 }; // err-unauthorized
  }
  const newArtworkId = ++lastArtworkId;
  artworks.set(newArtworkId, {
    title,
    description,
    creator: caller,
    collaborators: [caller],
    contributions: [100],
    totalContributions: 100,
    isFinalized: false,
    nftId: null
  });
  return { type: 'ok', value: newArtworkId };
}

function addContribution(caller: string, artworkId: number, contribution: number): { type: string; value: boolean } {
  if (!artists.has(caller)) {
    return { type: 'err', value: 102 }; // err-unauthorized
  }
  const artwork = artworks.get(artworkId);
  if (!artwork) {
    return { type: 'err', value: 101 }; // err-not-found
  }
  if (artwork.isFinalized) {
    return { type: 'err', value: 102 }; // err-unauthorized
  }
  artwork.collaborators.push(caller);
  artwork.contributions.push(contribution);
  artwork.totalContributions += contribution;
  artworks.set(artworkId, artwork);
  return { type: 'ok', value: true };
}

function finalizeArtwork(caller: string, artworkId: number): { type: string; value: boolean } {
  const artwork = artworks.get(artworkId);
  if (!artwork) {
    return { type: 'err', value: 101 }; // err-not-found
  }
  if (artwork.creator !== caller) {
    return { type: 'err', value: 102 }; // err-unauthorized
  }
  if (artwork.isFinalized) {
    return { type: 'err', value: 102 }; // err-unauthorized
  }
  artwork.isFinalized = true;
  artworks.set(artworkId, artwork);
  return { type: 'ok', value: true };
}

function mintNft(caller: string, artworkId: number, price: number): { type: string; value: number } {
  const artwork = artworks.get(artworkId);
  if (!artwork) {
    return { type: 'err', value: 101 }; // err-not-found
  }
  if (!artwork.isFinalized) {
    return { type: 'err', value: 102 }; // err-unauthorized
  }
  if (artwork.nftId !== null) {
    return { type: 'err', value: 103 }; // err-already-exists
  }
  const newNftId = ++lastNftId;
  nfts.set(newNftId, { artworkId, owner: caller, price });
  artwork.nftId = newNftId;
  artworks.set(artworkId, artwork);
  return { type: 'ok', value: newNftId };
}

function buyNft(caller: string, nftId: number): { type: string; value: boolean } {
  const nft = nfts.get(nftId);
  if (!nft) {
    return { type: 'err', value: 101 }; // err-not-found
  }
  // In a real implementation, we would handle the STX transfer and royalty distribution here
  nft.owner = caller;
  nfts.set(nftId, nft);
  return { type: 'ok', value: true };
}

describe('Digital Art Collaboration Platform', () => {
  beforeEach(() => {
    artists.clear();
    artworks.clear();
    nfts.clear();
    lastArtworkId = 0;
    lastNftId = 0;
  });
  
  it('should register an artist', () => {
    const result = registerArtist('artist1', 'John Doe');
    expect(result.type).toBe('ok');
    expect(result.value).toBe(true);
    expect(artists.get('artist1')).toEqual({ name: 'John Doe', registered: true });
  });
  
  it('should not register an artist twice', () => {
    registerArtist('artist1', 'John Doe');
    const result = registerArtist('artist1', 'John Doe');
    expect(result.type).toBe('err');
    expect(result.value).toBe(103); // err-already-exists
  });
  
  it('should create an artwork', () => {
    registerArtist('artist1', 'John Doe');
    const result = createArtwork('artist1', 'My Artwork', 'A beautiful piece');
    expect(result.type).toBe('ok');
    expect(result.value).toBe(1);
    const artwork = artworks.get(1);
    expect(artwork).toBeDefined();
    expect(artwork.title).toBe('My Artwork');
    expect(artwork.creator).toBe('artist1');
  });
  
  it('should add a contribution to an artwork', () => {
    registerArtist('artist1', 'John Doe');
    registerArtist('artist2', 'Jane Doe');
    createArtwork('artist1', 'My Artwork', 'A beautiful piece');
    const result = addContribution('artist2', 1, 50);
    expect(result.type).toBe('ok');
    expect(result.value).toBe(true);
    const artwork = artworks.get(1);
    expect(artwork.collaborators).toContain('artist2');
    expect(artwork.contributions).toContain(50);
    expect(artwork.totalContributions).toBe(150);
  });
  
  it('should finalize an artwork', () => {
    registerArtist('artist1', 'John Doe');
    createArtwork('artist1', 'My Artwork', 'A beautiful piece');
    const result = finalizeArtwork('artist1', 1);
    expect(result.type).toBe('ok');
    expect(result.value).toBe(true);
    const artwork = artworks.get(1);
    expect(artwork.isFinalized).toBe(true);
  });
  
  it('should mint an NFT for a finalized artwork', () => {
    registerArtist('artist1', 'John Doe');
    createArtwork('artist1', 'My Artwork', 'A beautiful piece');
    finalizeArtwork('artist1', 1);
    const result = mintNft('artist1', 1, 1000);
    expect(result.type).toBe('ok');
    expect(result.value).toBe(1);
    const nft = nfts.get(1);
    expect(nft).toBeDefined();
    expect(nft.artworkId).toBe(1);
    expect(nft.owner).toBe('artist1');
    expect(nft.price).toBe(1000);
  });
  
  it('should buy an NFT', () => {
    registerArtist('artist1', 'John Doe');
    registerArtist('collector', 'Art Collector');
    createArtwork('artist1', 'My Artwork', 'A beautiful piece');
    finalizeArtwork('artist1', 1);
    mintNft('artist1', 1, 1000);
    const result = buyNft('collector', 1);
    expect(result.type).toBe('ok');
    expect(result.value).toBe(true);
    const nft = nfts.get(1);
    expect(nft.owner).toBe('collector');
  });
});

