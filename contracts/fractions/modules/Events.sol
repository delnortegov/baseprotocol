// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


library Events {
    event WithdrawExecuted(address walletAddress, uint amount);
    event ERC20Sent(address walletAddress, address token, uint amount);
    event ERC20Received(address walletAddress, address token, uint amount, bool success);

    event PropertyFractionalized(address _by, uint _propertyTokenId, uint _fractionsNumber, uint _fractionSalePrice, address _fractionSaleCurrency);
    event SaleStatusChanged(address _by, uint _propertyTokenId, bool _newStatus);
    event FractionsPurchased(address _by, uint _propertyTokenId, uint _numberOfFractions);
    event FractionsClaimed(address _by, uint _propertyTokenId, uint _claimAmount);
    event FundsClaimed(address _by, uint _propertyTokenId, uint _claimAmount);

    event AdminPaused(address _admin);
    event AdminUnpaused(address _admin);
    event AdminStatusFlipped(address _admin, address _walletAddress, bool _newStatus);
    event AdminSaleForceDeactivated(address _admin, uint _propertyId, bool _newForceDeactivatedValue);
    event AdminSaleBalancesUpdated(address _admin, address _user, uint _propertyId, uint _newBalance, uint _newClaimed);
    event AdminConfigurationUpdated(address _admin, uint _standardTokensVesting, uint8 _fractionTokensDecimals, address _propertiesContractAddress);
    event AdminFractionSettingsUpdated(
        address _admin,
        uint _propertyId,
        uint _fractionsNumber,
        uint _fractionSalePrice,
        address _fractionSaleCurrency,
        address _fractionsContractAddress
    );
    event AdminSaleUpdated(
        address _admin,
        uint _propertyId,
        uint _createdAt,
        uint _startedAt,
        uint _tokensVestingPeriod,
        bool _forceDeactivated,
        uint _totalCapital,
        uint _totalSold,
        uint _fundsClaimed,
        bool _active,
        address _creator
    );
}