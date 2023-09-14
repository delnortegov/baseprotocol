// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ERC20Contract {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function increaseAllowance(address spender, uint addedValue) external returns (bool);
    function balanceOf(address account) external returns (uint256);
}
