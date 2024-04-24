// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";


contract BondFactory is ERC721, ERC721URIStorage, ERC721Burnable, Ownable, VRFConsumerBase {
    uint256 private _nextTokenId;
    bytes32 internal keyHash;
    uint256 internal fee;
    mapping(bytes32 => address) public requestIdToSender;

    constructor(
        address vrfCoordinator, 
        address linkToken, 
        bytes32 _keyHash, 
        uint256 _fee
    ) 
        ERC721("Bond", "SEB")
        VRFConsumerBase(vrfCoordinator, linkToken)
    {
        transferOwnership(msg.sender);
        keyHash = _keyHash;
        fee = _fee;
    }

    function safeMint(address to) public onlyOwner returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        requestId = requestRandomness(keyHash, fee);
        requestIdToSender[requestId] = to;
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        uint256 tokenId = _nextTokenId++;
        uint256 priceInCents = 9975 + (randomness % 51); // This will give a number between 9975 to 10025
        string memory tokenURI = string(abi.encodePacked("https://example.com/bond/",
         tokenId.toString(), "/", priceInCents.toString()));
        _safeMint(requestIdToSender[requestId], tokenId);
        _setTokenURI(tokenId, tokenURI);
    }

    // The following functions are overrides required by Solidity.

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
}
