// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


library Models {
    
    struct FractionsSettingsObj {
        uint fractionsNumber;
        uint fractionSalePrice;
        address fractionSaleCurrency;
        address fractionsContractAddress;
    }

    struct Sale {        
        bool active;
        address creator;
        uint createdAt;
        uint startedAt;
        uint tokensVestingPeriod;

        // Sale admin switch
        bool forceDeactivated;

        // Total amount of tokens received from the sale
        uint totalCapital;

        // Total number of fraction sold
        uint totalSold;

        // Total amount of tokens (funds) claimed by sale creator
        uint fundsClaimed;

        mapping(address => uint) fractionsBalances;
        mapping(address => uint) fractionsClaimed;
    }

    struct Configuration {
        // Tokens standard vesting period in blocks
        uint standardTokensVesting;

        // Address of the properties contract
        address propertiesContractAddress;

        // Decimals for fractions Tokens
        uint8 fractionTokensDecimals;

        // Contract admins
        mapping(address => bool) admins;
    }

}
