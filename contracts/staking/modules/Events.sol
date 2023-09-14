// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


library Events {
    event WithdrawExecuted(address walletAddress, uint amount);
    event ERC20Sent(address walletAddress, address token, uint amount);
    event ERC20Received(address walletAddress, address token, uint amount, bool success);

    event AssetsStaked(address _staker, uint _stakingId, uint _depositId, uint _amount);
    event AssetsUnstaked(address _staker, uint _stakingId, uint _depositId, uint _claimedDividends);
    event DividendsClaimed(address _staker, uint _depositId, uint _claimedDividends);
    event StakingCreated(address _creator, uint _propertyId);
    event StakingStatusChanged(address _by, bool _newStatus);

    event AdminPaused(address _admin);
    event AdminUnpaused(address _admin);
    event AdminStatusFlipped(address _admin, address _walletAddress, bool _newStatus);
    event AdminStakingForceDeactivated(address _admin, uint _stakingId, bool _status);
    event AdminUpdatedUserDepositsNumber(address _admin, address _walletAddress, uint _newDepositsNumber);
    event AdminParentContractsUpdated(
        address _admin, 
        address _propertiesContractAddress, 
        address _fractionalizationContractAddress
    );
    event AdminUpdatedUserDeposit(
        address _admin,
        address _user,
        uint _depositId,
        bool _isOpen, 
        uint _amount, 
        uint _stakingId, 
        uint _creationTime, 
        uint _lastClaimTime
    );
    event AdminUpdatedStaking(
        address _admin,
        uint _stakingId,
        address _dividendsAddress,
        uint _dividendSize,
        uint _dividendPeriod,
        uint _minStakingTime,
        bool _active,
        bool _forceDeactivated,
        uint _startedAt,
        address _creator
    );
}
