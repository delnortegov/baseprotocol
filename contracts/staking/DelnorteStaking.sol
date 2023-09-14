// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 *   ___      _              _         ___ _        _   _           
 *  |   \ ___| |_ _  ___ _ _| |_ ___  / __| |_ __ _| |_(_)_ _  __ _ 
 *  | |) / -_) | ' \/ _ \ '_|  _/ -_) \__ \  _/ _` | / / | ' \/ _` |
 *  |___/\___|_|_||_\___/_|  \__\___| |___/\__\__,_|_\_\_|_||_\__, |
 *                                                            |___/ 
 */

/**
 * @title DelnorteStaking contract
 * @author botpapa.xyz
 * @notice Smart contract for staking your fractionalized assets
 */


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./modules/Models.sol";
import "./modules/Events.sol";
import "./modules/Modifiers.sol";
import "./modules/Interfaces.sol";


contract DelnorteStaking is Ownable, Pausable, ReentrancyGuard, Modifiers {
    // base contract configuration
    Models.Configuration public config;

    // propertyId to staking data mapping
    mapping(uint => Models.Staking) public staking;

    // propertyId to staking data mapping
    mapping(address => Models.Staker) public stakers;

    /**
     * CONSTRUCTOR
     */
    constructor(
        address _propertiesContractAddress, 
        address _fractionalizationContractAddress, 
        address[] memory _admins
    ) {
        config.propertiesContractAddress = _propertiesContractAddress;
        config.fractionalizationContractAddress = _fractionalizationContractAddress;

        // Setting up admins
        for (uint i = 0; i < _admins.length; i++) {
            config.admins[_admins[i]] = true;
        }
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
     * @notice Update parent smart contracts [admin]
     */
    function adminUpdateUserDepositsNumber(address _user, uint _newDepositsNumber) 
        public
        onlyAdmin(config) {
            stakers[_user].depositsNumber = _newDepositsNumber;
            emit Events.AdminUpdatedUserDepositsNumber(msg.sender, _user, _newDepositsNumber);
    }

    /**
     * @notice Force activate/deactivate a sale [admin]
     */
    function adminStakingForceDeactivate(uint _stakingId, bool _status) 
        public
        onlyAdmin(config) {
            staking[_stakingId].forceDeactivated = _status;
            emit Events.AdminStakingForceDeactivated(msg.sender, _stakingId, _status);
    }

    /**
     * @notice Update parent smart contracts [admin]
     */
    function adminUpdateParentContractsAddresses(address _propertiesContractAddress, address _fractionalizationContractAddress) 
        public
        onlyAdmin(config) {
            config.propertiesContractAddress = _propertiesContractAddress;
            config.fractionalizationContractAddress = _fractionalizationContractAddress;
            emit Events.AdminParentContractsUpdated(msg.sender, _propertiesContractAddress, _fractionalizationContractAddress);
    }

    /**
     * @notice Update user's deposit info [admin]
     */
    function adminUpdateUserDeposit(
        address _user,
        uint _depositId,

        bool _isOpen, 
        uint _amount, 
        uint _stakingId, 
        uint _creationTime, 
        uint _lastClaimTime
    ) public onlyAdmin(config) {
        stakers[_user].deposits[_depositId] = Models.Deposit(
            {
                isOpen: _isOpen,
                amount: _amount,
                stakingId: _stakingId,
                creationTime: _creationTime,
                lastClaimTime: _lastClaimTime
            }
        );
        emit Events.AdminUpdatedUserDeposit(
            msg.sender, _user, _depositId, _isOpen, _amount, _stakingId, _creationTime, _lastClaimTime
        );
    }

    /**
     * @notice Update staking info [admin]
     */
    function adminUpdateStaking(
        uint _stakingId,

        address _dividendsAddress,
        uint _dividendSize,
        uint _dividendPeriod,
        uint _minStakingTime,
        bool _active,
        bool _forceDeactivated,
        uint _startedAt,
        address _creator
    ) public onlyAdmin(config) {
        staking[_stakingId] = Models.Staking(
            {
                dividendsAddress: _dividendsAddress,
                dividendSize: _dividendSize,
                dividendPeriod: _dividendPeriod,
                minStakingTime: _minStakingTime,
                active: _active,
                forceDeactivated: _forceDeactivated,
                startedAt: _startedAt,
                creator: _creator
            }
        );
        emit Events.AdminUpdatedStaking(
            msg.sender, _stakingId, _dividendsAddress, _dividendSize, _dividendPeriod, _minStakingTime, _active, _forceDeactivated, _startedAt, _creator
        );
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


    ////////////////////////
    //                    //
    //   Read functions   //
    //                    //
    ////////////////////////

    function isAdmin(address _user) public view returns(bool) {
        return config.admins[_user];
    }

    function getUserDepositsCount(address _user) public view returns(uint) {
        return stakers[_user].depositsNumber;
    }

    function getUserDeposit(address _user, uint _depositId) public view returns(Models.Deposit memory) {
        return stakers[_user].deposits[_depositId];
    }

    function calculateDividends(address _user, uint _depositId) 
        public 
        view 
        returns(uint dividendsAvailableToClaim, address dividendsAddress, uint unclaimedBlocks, bool claimAvailable) {
            Models.Deposit memory _deposit = stakers[_user].deposits[_depositId];
            Models.Staking memory _staking = staking[_deposit.stakingId];

            uint _blocksPassed = block.number - _deposit.lastClaimTime;
            uint _periodsPassed = _blocksPassed / _staking.dividendPeriod;

            uint _dividendsAvailableToClaim = _periodsPassed * _staking.dividendSize;
            uint _unclaimedBlocks = _deposit.lastClaimTime - (_periodsPassed * _staking.dividendPeriod);

            address _dividendsAddress = _staking.dividendsAddress;
            bool _claimAvailable = _blocksPassed >= _staking.minStakingTime;
            if (!_staking.active || !_deposit.isOpen) {
                _claimAvailable = false;
            }

            return (_dividendsAvailableToClaim, _dividendsAddress, _unclaimedBlocks, _claimAvailable);
    }

    /**
     * @dev Getting address of the ERC-20 fractions belonging to the propery
     */
    function getStakingTokenAddress(uint _stakingId) internal view returns(address) {
        return IFractionalizerContract(config.fractionalizationContractAddress).getFractionsContractAddress(_stakingId);
    }


    /////////////////
    //             //
    //   Staking   //
    //             //
    /////////////////

    /**
     * @notice Stake your assets
     * @dev This function creates a new deposit for the given assets
     */
    function stake(uint _stakingId, uint _amount) 
        public 
        nonReentrant 
        whenNotPaused
        onlyActiveStaking(staking[_stakingId]) 
        returns(uint) {
            // Transferring fractions to this smart contract 
            address _fractionsContractAddress = getStakingTokenAddress(_stakingId);
            bool receiveSucess = getERC20(_fractionsContractAddress, msg.sender, _amount);
            require(receiveSucess, "Payment unsuccessful.");

            uint _newDepositId = stakers[msg.sender].depositsNumber;
            stakers[msg.sender].deposits[_newDepositId] = Models.Deposit(
                {
                    isOpen: true,
                    amount: _amount,
                    stakingId: _stakingId,
                    creationTime: block.number,
                    lastClaimTime: block.number
                }
            );
            stakers[msg.sender].depositsNumber += 1;

            emit Events.AssetsStaked(msg.sender, _stakingId, _newDepositId, _amount);
            return _newDepositId;
    }

    /**
     * @notice Unstake your assets
     * @dev This function returns assets back (if minStakingTime has passed) and closes the deposit
     */
    function unstake(uint _depositId) 
        public 
        nonReentrant 
        whenNotPaused 
        onlyActiveStaking(staking[stakers[msg.sender].deposits[_depositId].stakingId]) 
        returns(uint claimedDividends) {
            Models.Deposit memory _deposit = stakers[msg.sender].deposits[_depositId];
            Models.Staking memory _staking = staking[_deposit.stakingId];

            require(_deposit.isOpen, "The deposit you want to unstake is closed or does not exist.");
            require(_deposit.creationTime + _staking.minStakingTime <= block.number, "You cannot unstake this deposit due to the minimal staking time has not passed yet.");

            // Claiming dividends
            uint _claimedDividends = claimDividends(_depositId);

            // Resetting deposit
            Models.Deposit memory _resetDeposit;
            stakers[msg.sender].deposits[_depositId] = _resetDeposit;

            // Sending user's staked tokens back
            address _fractionsTokensAddress = getStakingTokenAddress(_deposit.stakingId);
            bool _transferSuccess = internalSendERC20(
                _fractionsTokensAddress,
                msg.sender,
                _deposit.amount
            );
            require(_transferSuccess, "Unstaking was unsuccessful.");

            emit Events.AssetsUnstaked(msg.sender, _deposit.stakingId, _depositId, _claimedDividends);
            return _claimedDividends;
    }

    /**
     * @notice Claim dividends
     * @dev Period for which dividents weren't paid is added back to the storage
     */
    function claimDividends(uint _depositId) 
        public 
        nonReentrant 
        whenNotPaused 
        onlyActiveStaking(staking[stakers[msg.sender].deposits[_depositId].stakingId]) 
        returns(uint claimedDividends) {
            (
                uint _dividendsAvailableToClaim, 
                address _dividendsAddress,
                uint _unclaimedBlocks, 
                bool _claimAvailable
            ) = calculateDividends(msg.sender, _depositId);
            require(_claimAvailable, "Minimal staking period hasn't passed yet.");

            // Sending dividends
            bool _transferSuccess = internalSendERC20(
                _dividendsAddress,
                msg.sender,
                _dividendsAvailableToClaim
            );
            require(_transferSuccess, "Transfer was unsuccessful.");

            // Saving unclaimed blocks to the storage
            stakers[msg.sender].deposits[_depositId].lastClaimTime = block.number - _unclaimedBlocks;

            emit Events.DividendsClaimed(msg.sender, _depositId, _dividendsAvailableToClaim);
            return _dividendsAvailableToClaim;
    }


    /////////////////////////////
    //                         //
    //   Staking admin panel   //
    //                         //
    /////////////////////////////

    /**
     * @notice Create a new staking
     * @dev Only the wallet that fractionalized property NFT is able to create a new staking for it
     * 
     * @param _propertyId -- id of the property whos fractions can be staked
     * @param _dividendsAddress -- address of the ERC-20 token that will be used to pay dividends
     * @param _dividendPeriod -- period in blocks that is used to pay dividends
     * @param _dividendSize -- amount of dividends paid every _dividendPeriod
     * @param _minStakingTime -- period in blocks after which the assets can be unstaked
     */
    function createStaking(uint _propertyId, address _dividendsAddress, uint _dividendPeriod, uint _dividendSize, uint _minStakingTime) 
        public 
        nonReentrant 
        onlyStakingPropertyOwner(config, _propertyId) 
        returns(uint256) {

        require(getStakingTokenAddress(_propertyId) != address(0), "Please, fractionalize your property first.");
        require(staking[_propertyId].creator == address(0), "Staking for this property was already created.");

        staking[_propertyId] = Models.Staking(
            {
                dividendsAddress: _dividendsAddress,
                dividendSize: _dividendSize,
                dividendPeriod: _dividendPeriod,
                minStakingTime: _minStakingTime,
                creator: msg.sender,
                active: false,
                forceDeactivated: false,
                startedAt: 0
            }
        );

        emit Events.StakingCreated(msg.sender, _propertyId);
        return _propertyId;
    }

    /**
     * @notice Change staking status
     * @dev Setting staking status to given bool; callable from staking creator or admin
     */
    function changeStakingStatus(uint _stakingId, bool _newStatus) 
        public 
        nonReentrant 
        onlyStakingPropertyOwner(config, _stakingId) 
        returns(bool) { 
            require(staking[_stakingId].creator == msg.sender, "You are not the creator of this staking.");

            if (_newStatus == true && staking[_stakingId].startedAt == 0) {
                staking[_stakingId].startedAt = block.number;
            }
            staking[_stakingId].active = _newStatus;

            emit Events.StakingStatusChanged(msg.sender, _newStatus);
            return staking[_stakingId].active;
    }


    /////////////////////////////////////////
    //                                     //
    //   Withdrawals and token transfers   //
    //                                     //
    /////////////////////////////////////////
    
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
    function sendERC20(address token, address walletAddress, uint amount) public onlyAdmin(config) nonReentrant {
        bool sent = internalSendERC20(token, walletAddress, amount);
        require(sent, "Failed to send ERC20");
        emit Events.ERC20Sent(walletAddress, token, amount);
    }

    /**
     * @dev Function allows taking payments in custom ERC-20 tokens from this smart contract [internal]
     */
    function getERC20(address token, address walletAddress, uint amount) internal returns(bool) {
        bool sent = ERC20Contract(token).transferFrom(walletAddress, address(this), amount);
        emit Events.ERC20Received(walletAddress, token, amount, sent);
        return sent;
    }

    /**
     * @dev Function allows sending ERC-20 tokens to the diven address [internal]
     */
    function internalSendERC20(address token, address walletAddress, uint amount) internal returns(bool) {
        bool increased = ERC20Contract(token).increaseAllowance(address(this), amount);
        require(increased, "Failed to increase ERC20 allowance");

        bool sent = ERC20Contract(token).transferFrom(address(this), walletAddress, amount);
        emit Events.ERC20Sent(walletAddress, token, amount);
        return sent;
    }

}