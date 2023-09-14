// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Models.sol";
import "./Interfaces.sol";


abstract contract Modifiers {

    modifier onlyStakingPropertyOwner(Models.Configuration storage _config, uint _stakingId) {
        address _tokenOwner = IPropertiesContract(_config.propertiesContractAddress).getTokenMinter(_stakingId);
        require(_tokenOwner == msg.sender, "You cannot create staking for this token as you haven't minted it.");
        _;
    }

    modifier onlyActiveStaking(Models.Staking storage _staking) {
        require(_staking.active && !_staking.forceDeactivated, "You cannot perform this action as given staking is not active or does not exist.");
        _;
    }

    modifier onlyAdmin(Models.Configuration storage _config) {
        require(_config.admins[msg.sender], "You're not an admin.");
        _;
    }

}
