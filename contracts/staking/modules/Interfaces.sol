// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ERC721Contract {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external returns (address);
    function ownerOf(uint256 tokenId) external returns (address);
}

interface ERC20Contract {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function increaseAllowance(address spender, uint addedValue) external returns (bool);
    function balanceOf(address account) external returns (uint256);
}

interface IPropertiesContract {
    function getTokenMinter(uint _tokenId) external view returns (address);
}

interface IFractionalizerContract {
    function getSaleStatus(uint propertyTokenId) external view returns (bool);
    function getFractionsContractAddress(uint propertyTokenId) external view returns (address);
}
