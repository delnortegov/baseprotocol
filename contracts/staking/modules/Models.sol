// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


library Models {

    struct Staking {
        // ERC-20 tokens address, dividend size per token & dividend period
        address dividendsAddress;
        uint dividendSize;
        uint dividendPeriod;
        uint minStakingTime;

        // Staking switch
        bool active;

        // Staking admin switch
        bool forceDeactivated;

        // When staking was open
        uint startedAt;
        
        // Staking creator (same as the wallet that fractionalized the property)
        address creator;
    }

    struct Deposit {
        bool isOpen;

        uint amount;
        uint stakingId;
        uint creationTime;
        uint lastClaimTime;
    }

    struct Staker {
        // List of deposits owned by a wallet
        uint depositsNumber;

        // Mapping of depositId => Deposit
        mapping(uint => Deposit) deposits;
    }

    struct Configuration {
        // Parent smart contracts' addresses
        address propertiesContractAddress;
        address fractionalizationContractAddress;

        // Smart contract admins
        mapping(address => bool) admins;
    }

}
