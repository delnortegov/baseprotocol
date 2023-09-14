// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Models.sol";


abstract contract Modifiers {

    modifier onlyAdmin(Models.Configuration storage _config) {
        require(_config.admins[msg.sender], "You're not an admin.");
        _;
    }

}