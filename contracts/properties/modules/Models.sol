// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library Models {
    
    struct Property {
        bool active;
        bool forceDeactivated;

        address owner;
        uint tokenId;
        bool verified;
        address verifier;
        string metadataURI;
    }

    struct Configuration {
        // NFT metadata URI
        string _baseTokenURI;

        // Mapping of admins who have control over the smart contract
        mapping(address => bool) admins;
    }
}
