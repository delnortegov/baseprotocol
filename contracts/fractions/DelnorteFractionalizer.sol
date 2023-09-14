// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 *   ___      _              _         ___            _   _               _ _            
 *  |   \ ___| |_ _  ___ _ _| |_ ___  | __| _ __ _ __| |_(_)___ _ _  __ _| (_)______ _ _ 
 *  | |) / -_) | ' \/ _ \ '_|  _/ -_) | _| '_/ _` / _|  _| / _ \ ' \/ _` | | |_ / -_) '_|
 *  |___/\___|_|_||_\___/_|  \__\___| |_||_| \__,_\__|\__|_\___/_||_\__,_|_|_/__\___|_|  
 *                                                                                      
 */

/**
 * @title DelnorteFractionalizer contract
 * @author botpapa.xyz
 * @notice Smart contract for fractionalizing properties and hosting fractions' sales
 */


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./modules/Models.sol";
import "./modules/Events.sol";
import "./modules/Modifiers.sol";
import "./modules/Interfaces.sol";
import "./modules/DelnorteFractionsToken.sol";


contract DelnorteFractionalizer is Ownable, Pausable, ReentrancyGuard, Modifiers {
    // base contract configuration
    Models.Configuration public config;

    // mapping of property settings | tokenId => FractionsSettingsObj
    mapping(uint => Models.FractionsSettingsObj) public propertyFractionsSettings;

    // mapping of sales | saleId => Sale
    mapping(uint => Models.Sale) public sales;

    /**
     * CONSTRUCTOR
     */
    constructor(
        address _propertiesContractAddress,
        uint8 _fractionTokensDecimals,
        uint _standardTokensVesting
    ) {
        config.propertiesContractAddress = _propertiesContractAddress;
        config.fractionTokensDecimals = _fractionTokensDecimals;
        config.standardTokensVesting = _standardTokensVesting;
    }


    /////////////////////
    //                 //
    //   Admin panel   //
    //                 //
    /////////////////////

    /**
     * @notice Flip admin status [admin]
     */
    function flipAdminStatus(address walletAddress) external onlyOwner returns(bool) {
        config.admins[walletAddress] = !config.admins[walletAddress];
        emit Events.AdminStatusFlipped(msg.sender, walletAddress, config.admins[walletAddress]);
        return config.admins[walletAddress];
    }

    /**
     * @notice Force deactivate sale [admin]
     */
    function adminForceDeactivateSale(
        uint _propertyId,
        bool _newForceDeactivatedValue
    ) public onlyAdmin(config) {
        sales[_propertyId].forceDeactivated = _newForceDeactivatedValue;
        emit Events.AdminSaleForceDeactivated(msg.sender, _propertyId, _newForceDeactivatedValue);
    }

    /**
     * @notice Update fractions settings [admin]
     * @dev Updating full struct of fractions settings by propertyId
     */
    function adminUpdateFractionsSettings(
        uint _propertyId,
        uint _fractionsNumber,
        uint _fractionSalePrice,
        address _fractionSaleCurrency,
        address _fractionsContractAddress
    ) public onlyAdmin(config) {
        propertyFractionsSettings[_propertyId] = Models.FractionsSettingsObj(
            {
                fractionsNumber: _fractionsNumber,
                fractionSalePrice: _fractionSalePrice,
                fractionSaleCurrency: _fractionSaleCurrency,
                fractionsContractAddress: _fractionsContractAddress
            }
        );
        emit Events.AdminFractionSettingsUpdated(msg.sender, _propertyId, _fractionsNumber, _fractionSalePrice, _fractionSaleCurrency, _fractionsContractAddress);
    }

    /**
     * @notice Update sale [admin]
     */
    function adminUpdateSale(
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
    ) public onlyAdmin(config) {
        sales[_propertyId].active = _active;
        sales[_propertyId].creator = _creator;
        sales[_propertyId].createdAt = _createdAt;
        sales[_propertyId].startedAt = _startedAt;
        sales[_propertyId].tokensVestingPeriod = _tokensVestingPeriod;
        sales[_propertyId].forceDeactivated = _forceDeactivated;
        sales[_propertyId].totalCapital = _totalCapital;
        sales[_propertyId].totalSold = _totalSold;
        sales[_propertyId].fundsClaimed = _fundsClaimed;
        emit Events.AdminSaleUpdated(
            msg.sender, _propertyId, _createdAt, _startedAt, _tokensVestingPeriod, _forceDeactivated, _totalCapital, _totalSold, _fundsClaimed, _active, _creator
        );
    }

    /**
     * @notice Update sale balances [admin]
     * @dev Updating fractionsBalances and fractionsClaimed mappings in the Sale struct
     */
    function adminUpdateSaleBalances(
        address _user,
        uint _propertyId,
        uint _newBalance,
        uint _newClaimed
    ) public onlyAdmin(config) {
        sales[_propertyId].fractionsBalances[_user] = _newBalance;
        sales[_propertyId].fractionsClaimed[_user] = _newClaimed;
        emit Events.AdminSaleBalancesUpdated(msg.sender, _user, _propertyId, _newBalance, _newClaimed);
    }

    /**
     * @notice Update base configuration [admin]
     */
    function adminUpdateConfiguration(
        uint _standardTokensVesting,
        uint8 _fractionTokensDecimals,
        address _propertiesContractAddress
    ) public onlyAdmin(config) {
        config.standardTokensVesting = _standardTokensVesting;
        config.propertiesContractAddress = _propertiesContractAddress;
        config.fractionTokensDecimals = _fractionTokensDecimals;
        emit Events.AdminConfigurationUpdated(msg.sender, _standardTokensVesting, _fractionTokensDecimals, _propertiesContractAddress);
    }

    /**
     * @notice Pause smart contract [admin]
     */
    function pause() public onlyAdmin(config) {
        _pause();
        emit Events.AdminPaused(msg.sender);
    }

    /**
     * @notice Unpause smart contract
     */
    function unpause() public onlyAdmin(config) {
        _unpause();
        emit Events.AdminUnpaused(msg.sender);
    }


    /////////////////
    //             //
    //   Getters   //
    //             //
    /////////////////

    function isAdmin(address _user) public view returns(bool) {
        return config.admins[_user];
    }

    function getVestedTokensBalance(uint propertyTokenId, address user) public view returns(uint) {
        return sales[propertyTokenId].fractionsBalances[user];
    }

    function getSaleStatus(uint propertyTokenId) public view returns(bool) {
        return sales[propertyTokenId].active;
    }

    function getFractionsContractAddress(uint propertyTokenId) public view returns(address) {
        return propertyFractionsSettings[propertyTokenId].fractionsContractAddress;
    }


    //////////////////////////////////////
    //                                  //
    //   Fractionalization management   //
    //                                  //
    //////////////////////////////////////

    /**
     * @notice Fractionalize property
     * @dev Main function to produce ERC-20 token fractions. This function takes property NFT, deploys fractions contract and creates the sale
     */
    function fractionalize(
        uint _propertyTokenId, 
        uint _fractionsNumber, 
        uint _fractionSalePrice, 
        address _fractionSaleCurrency
    ) public nonReentrant whenNotPaused {
        // Transferring NFT to this contract and checking ownership
        ERC721Contract(config.propertiesContractAddress).transferFrom(msg.sender, address(this), _propertyTokenId);
        require(ERC721Contract(config.propertiesContractAddress).ownerOf(_propertyTokenId) == address(this), "NFT transfer failed.");

        // Deploying ERC-20 smart contract of fractions
        DelnorteFractionsToken _fractionsToken = new DelnorteFractionsToken(
            string(abi.encodePacked("Fractionalized property #", _propertyTokenId)),
            string(abi.encodePacked("dFRX#", _propertyTokenId)),
            config.fractionTokensDecimals
        );
        
        // Configuring sale
        sales[_propertyTokenId].creator = msg.sender;
        sales[_propertyTokenId].createdAt = block.number;

        sales[_propertyTokenId].active = false;
        sales[_propertyTokenId].startedAt = 0;
        sales[_propertyTokenId].tokensVestingPeriod = config.standardTokensVesting;

        // Configuring fractions settings
        propertyFractionsSettings[_propertyTokenId] = Models.FractionsSettingsObj(
            {
                fractionsNumber: _fractionsNumber,
                fractionSalePrice: _fractionSalePrice,
                fractionSaleCurrency: _fractionSaleCurrency,
                fractionsContractAddress: address(_fractionsToken)
            }
        );
        
        emit Events.PropertyFractionalized(msg.sender, _propertyTokenId, _fractionsNumber, _fractionSalePrice, _fractionSaleCurrency);
    }

    /**
     * @notice Change sale status
     * @dev Function allows to change sale's `active` field
     */
    function changeSaleStatus(uint _propertyTokenId, bool _newStatus) public nonReentrant {
        Models.Sale storage _sale = sales[_propertyTokenId];
        require(_sale.creator == msg.sender, "You cannot manage the sale as you are not the owner.");
        require(!_sale.forceDeactivated, "Current sale was force deactivated.");
        
        sales[_propertyTokenId].active = _newStatus;
        emit Events.SaleStatusChanged(msg.sender, _propertyTokenId, _newStatus);
    }


    //////////////////////////
    //                      //
    //   Users' functions   //
    //                      //
    //////////////////////////

    /**
     * @notice Buy fractions
     */
    function buyFractions(uint _propertyTokenId, uint _numberOfFractions) public nonReentrant whenNotPaused {
        // Base requirement checks
        require(!sales[_propertyTokenId].forceDeactivated, "Given property does not have an active sale.");
        require(sales[_propertyTokenId].active, "Given property does not have an active sale.");
        require(sales[_propertyTokenId].totalSold + _numberOfFractions <= propertyFractionsSettings[_propertyTokenId].fractionsNumber, "Given tokens amount exceeds available supply.");
        
        // Taking ERC-20 tokens as payment
        uint _totalAmount = propertyFractionsSettings[_propertyTokenId].fractionSalePrice * _numberOfFractions;
        bool receiveSucess = getERC20(propertyFractionsSettings[_propertyTokenId].fractionSaleCurrency, msg.sender, _totalAmount);
        require(receiveSucess, "Payment unsuccessful.");

        // Updating user's fraction tokens balance, total sold and total capital
        sales[_propertyTokenId].fractionsBalances[msg.sender] += _numberOfFractions;
        sales[_propertyTokenId].totalCapital += _totalAmount;
        sales[_propertyTokenId].totalSold += _numberOfFractions;

        emit Events.FractionsPurchased(msg.sender, _propertyTokenId, _numberOfFractions);
    }

    /**
     * @notice Claim fractions
     * @dev Claiming purchased fractions by users (available after the vesting period is over)
     */
    function claimPurchasedFractions(uint _propertyTokenId) public nonReentrant whenNotPaused returns(uint)  {
        require(sales[_propertyTokenId].fractionsClaimed[msg.sender] < sales[_propertyTokenId].fractionsBalances[msg.sender], "You have already claimed all of your tokens.");
        require(sales[_propertyTokenId].startedAt + sales[_propertyTokenId].tokensVestingPeriod < block.number, "Vesting time hasn't passed yet.");

        // Fractions minting process
        uint _claimAmount = sales[_propertyTokenId].fractionsBalances[msg.sender] - sales[_propertyTokenId].fractionsClaimed[msg.sender];
        sales[_propertyTokenId].fractionsClaimed[msg.sender] += _claimAmount;
        DelnorteFractionsToken(propertyFractionsSettings[_propertyTokenId].fractionsContractAddress).mint(msg.sender, _claimAmount);

        emit Events.FractionsClaimed(msg.sender, _propertyTokenId, _claimAmount);
        return _claimAmount;
    }


    /**
     * @notice Claim funds
     * @dev Function allows claiming gathered funds from the sale by the property owner
     */
    function claimFunds(uint _propertyTokenId) public nonReentrant returns(uint) {
        require(sales[_propertyTokenId].creator == msg.sender, "You have no rights to perform this action.");
        require(sales[_propertyTokenId].fundsClaimed < sales[_propertyTokenId].totalCapital, "You have already claimed all of the funds.");

        // Funds claiming process
        uint _claimAmount = sales[_propertyTokenId].totalCapital - sales[_propertyTokenId].fundsClaimed;
        sales[_propertyTokenId].fundsClaimed += _claimAmount;
        ERC20(propertyFractionsSettings[_propertyTokenId].fractionSaleCurrency).transferFrom(address(this), msg.sender, _claimAmount);

        emit Events.FundsClaimed(msg.sender, _propertyTokenId, _claimAmount);
        return _claimAmount;
    }


    /////////////////////////////////////////
    //                                     //
    //   Withdrawals and token transfers   //
    //                                     //
    /////////////////////////////////////////

    /**
     * @notice Withdraw ether
     * @dev Function allows withdrawing ETH from the smart contract [for the admins only]
     */
    function withdrawAll() external onlyAdmin(config) {
        uint amount = address(this).balance;
        payable(msg.sender).transfer(amount);
        emit Events.WithdrawExecuted(msg.sender, amount);
    }

    /**
     * @notice Withdraw ERC-20
     * @dev Function allows withdrawing ERC-20 from the smart contract [for the admins only]
     */
    function sendERC20(address token, address walletAddress, uint amount) external onlyAdmin(config) nonReentrant {
        bool increased = ERC20Contract(token).increaseAllowance(address(this), amount);
        require(increased, "Failed to increase ERC20 allowance");

        bool sent = ERC20Contract(token).transferFrom(address(this), walletAddress, amount);
        require(sent, "Failed to send ERC20");

        emit Events.ERC20Sent(walletAddress, token, amount);
    }

    /**
     * @dev Function allows taking payments in custom ERC-20 tokens from this smart contract
     */
    function getERC20(address token, address walletAddress, uint amount) internal returns(bool) {
        bool sent = ERC20Contract(token).transferFrom(walletAddress, address(this), amount);
        emit Events.ERC20Received(walletAddress, token, amount, sent);
        return sent;
    }

}