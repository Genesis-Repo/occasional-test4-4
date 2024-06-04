// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFTMarketplace is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping(uint256 => uint256) private _tokenPrices;
    mapping(uint256 => uint256) private _royaltyPercentages; // Map token ID to royalty percentage
    mapping(uint256 => address) private _creators; // Map token ID to creator address

    event NFTListed(uint256 indexed tokenId, uint256 price);
    event NFTSold(address indexed buyer, uint256 indexed tokenId, uint256 price);

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

    function listNFT(uint256 price, uint256 royaltyPercentage) external {
        require(royaltyPercentage <= 100, "Royalty percentage cannot exceed 100");
        
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _mint(msg.sender, newTokenId);
        
        _tokenPrices[newTokenId] = price;
        _royaltyPercentages[newTokenId] = royaltyPercentage;
        _creators[newTokenId] = msg.sender;
        
        emit NFTListed(newTokenId, price);
    }

    function buyNFT(uint256 tokenId) external payable {
        require(_exists(tokenId), "Token ID does not exist");
        
        uint256 price = _tokenPrices[tokenId];
        require(msg.value >= price, "Insufficient funds");

        address tokenOwner = ownerOf(tokenId);
        
        // Calculate royalty fee
        uint256 royaltyPercentage = _royaltyPercentages[tokenId];
        uint256 royaltyFee = (msg.value * royaltyPercentage) / 100;
        uint256 sellerAmount = msg.value - royaltyFee;
        
        // Transfer funds
        _transfer(tokenOwner, msg.sender, tokenId);
        
        // Transfer royalty fee to creator
        address creator = _creators[tokenId];
        (bool sent, ) = payable(creator).call{value: royaltyFee}("");
        require(sent, "Failed to send royalty fee");

        // Send remaining amount to seller
        (bool success, ) = payable(tokenOwner).call{value: sellerAmount}("");
        require(success, "Failed to send remaining amount to seller");

        emit NFTSold(msg.sender, tokenId, price);
    }

    function getTokenPrice(uint256 tokenId) external view returns (uint256) {
        return _tokenPrices[tokenId];
    }
}