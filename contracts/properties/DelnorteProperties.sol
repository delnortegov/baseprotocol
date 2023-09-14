// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 *   ___      _              _         ___                       _   _        
 *  |   \ ___| |_ _  ___ _ _| |_ ___  | _ \_ _ ___ _ __  ___ _ _| |_(_)___ ___
 *  | |) / -_) | ' \/ _ \ '_|  _/ -_) |  _/ '_/ _ \ '_ \/ -_) '_|  _| / -_|_-<
 *  |___/\___|_|_||_\___/_|  \__\___| |_| |_| \___/ .__/\___|_|  \__|_\___/__/
 *                                                |_|                         
 */

/**
 * @title DelnorteProperties contract
 * @author botpapa.xyz
 * @notice Smart contract for issuing property NFTs
 */


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./modules/Models.sol";
import "./modules/Events.sol";
import "./modules/Modifiers.sol";
import "./modules/Interfaces.sol";


contract DelnorteProperties is ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Burnable, Pausable, Ownable, ReentrancyGuard, Modifiers {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // base configuration variable
    Models.Configuration private config;

    // property NFT id => propertyId
    mapping(uint => uint) public propertyIds;

    // propertyId => propertyData
    mapping(uint => Models.Property) public properties;
    uint public currentPropertyId = 0;
    
    /**
     * CONSTRUCTOR
     */
    constructor(
        string memory name, 
        string memory symbol,
        address[] memory _admins
    ) ERC721(name, symbol) {
        // Setting up admins
        for (uint i = 0; i < _admins.length; i++) {
            config.admins[_admins[i]] = true;
        }
    }


    ////////////////////////
    //                    //
    //   Control panel    //
    //                    //
    ////////////////////////

    /**
     * @notice Set base URI [admin]
     */
    function setBaseURI(string memory _newBaseURI) external onlyAdmin(config) {
        config._baseTokenURI = _newBaseURI;
        emit Events.AdminBaseUriUpdated(msg.sender, _newBaseURI);
    }

    /**
     * @notice Flip admin status [admin]
     */
    function flipAdminStatus(address walletAddress) external onlyOwner {
        config.admins[walletAddress] = !config.admins[walletAddress];
        emit Events.AdminStatusFlipped(msg.sender, walletAddress, config.admins[walletAddress]);
    }

    /**
     * @notice Pause smart contract [admin]
     */
    function pause() public onlyAdmin(config) {
        _pause();
        emit Events.AdminPaused(msg.sender);
    }

    /**
     * @notice Unpause smart contract [admin]
     */
    function unpause() public onlyAdmin(config) {
        _unpause();
        emit Events.AdminUnpaused(msg.sender);
    }


    /////////////////////////
    //                     //
    //   Read functions    //
    //                     //
    /////////////////////////

    function isAdmin(address walletAddress) public view returns(bool) {
        return config.admins[walletAddress];
    }

    function getTokenMinter(uint _tokenId) public view returns (address) {
        uint _propertyId = propertyIds[_tokenId];
        return properties[_propertyId].owner;
    }
    
    function _baseURI() internal view override returns (string memory) {
        return config._baseTokenURI;
    }

    /**
     * @dev Getting list of all NFT ids held by the given address
     */
    function tokensOfOwner(address _owner) external view returns(uint256[] memory) {        
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }


    /////////////////////
    //                 //
    //   Core logic    //
    //                 //
    /////////////////////

    /**
     * @notice Tokenize propery
     * 
     * @dev Main function for registering property on the smart contract.
     * @dev submitProperty allows adding a property to the list but does not mint an NFT of it.
     * @dev Property then needs to pass verification by an admin, after that NFT is being minted to the owner's address.
     */
    function submitProperty(string calldata _metadataURI) public nonReentrant returns(uint newPropertyId) {
        uint _propertyId = currentPropertyId;
        currentPropertyId += 1;

        properties[_propertyId].metadataURI = _metadataURI;
        properties[_propertyId].owner = msg.sender;
        
        emit Events.PropertySubmitted(msg.sender, _propertyId);
        return _propertyId;
    }

    /**
     * @notice Verify property [admin]
     * @dev Funtion automatically mints property NFT on verification
     */
    function verifyProperty(uint _propertyId) public nonReentrant onlyAdmin(config) returns(uint newTokenId) {
        require(properties[_propertyId].owner != address(0), "Property with the given id does not exist.");
        require(!properties[_propertyId].verified, "Property with the given id has already been verified.");

        properties[_propertyId].verified = true;
        properties[_propertyId].verifier = msg.sender;

        uint _newTokenId = _mintProperty(properties[_propertyId].owner);
        propertyIds[_newTokenId] = _propertyId;
        properties[_newTokenId].tokenId = _newTokenId;

        emit Events.PropertyVerified(msg.sender, _propertyId, _newTokenId);
        return _newTokenId;
    }

    /**
     * @dev Internal NFT mint function
     */
    function _mintProperty(address _to) internal returns(uint mintedTokenId) {
        uint256 _mintedTokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_to, _mintedTokenId);
        emit Events.Minted(_to, _mintedTokenId);
        return _mintedTokenId;
    }


    //////////////////////////////////////////
    //                                      //
    //   Withdrawals and token transfers    //
    //                                      //
    //////////////////////////////////////////

    /**
     * @notice Withdraw all ether
     * @dev Function allows withdrawing ETH from the smart contract [for the owner only]
     */
    function withdrawAll() external onlyAdmin(config) {
        uint amount = address(this).balance;
        payable(msg.sender).transfer(amount);
        emit Events.WithdrawExecuted(msg.sender, amount);
    }

    /**
     * @notice Withdraw ERC-20 token
     * @dev Function allows withdrawing ERC-20 from the smart contract [for the owner only]
     */
    function sendERC20(address token, uint amount) external onlyAdmin(config) nonReentrant {
        bool increased = ERC20Contract(token).increaseAllowance(address(this), amount);
        require(increased, "Failed to increase ERC20 allowance");
        
        bool sent = ERC20Contract(token).transferFrom(address(this), msg.sender, amount);
        require(sent, "Failed to send ERC20");
        
        emit Events.ERC20Sent(msg.sender, token, amount);
    }

    /**
     * @dev Function allows taking payments in custom ERC-20 tokens from this smart contract [internal]
     */
    function getERC20(address token, address walletAddress, uint amount) internal returns(bool) {
        bool sent = ERC20Contract(token).transferFrom(walletAddress, address(this), amount);
        emit Events.ERC20Received(walletAddress, token, amount, sent);
        return sent;
    }



    ////////////////////////////////////////
    //                                    //
    //   Required overrides by Solidity   //
    //                                    //
    ////////////////////////////////////////

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        virtual
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

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
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}
