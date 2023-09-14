// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract DelnorteFractionsToken is ERC20, Ownable {

    uint8 private _customDecimals;
    
    constructor(
        string memory name, 
        string memory symbol, 
        uint8 _decimals
    ) ERC20(name, symbol) {
        _customDecimals = _decimals;
    }

    /**
     * @notice Mint tokens
     * @dev Mint function available only to its owner
     * @param beneficiary -- tokens receiver
     * @param mintAmount  -- number of tokens to be minted
     */  
    function mint(address beneficiary, uint256 mintAmount) external onlyOwner {
        _mint(beneficiary, mintAmount);   
    }

    /**
     * @dev Decimals override function to set up token decimals
     */
    function decimals() public view virtual override returns (uint8) {
        return _customDecimals;
    }

}