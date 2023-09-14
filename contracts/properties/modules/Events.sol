// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


library Events {
    event WithdrawExecuted(address walletAddress, uint amount);
    event ERC20Sent(address walletAddress, address token, uint amount);
    event ERC20Received(address walletAddress, address token, uint amount, bool success);

    event PropertySubmitted(address _owner, uint _propertyId);
    event PropertyVerified(address _by, uint _propertyId, uint _tokenId);
    event Minted(address _to, uint _tokenId);

    event AdminPaused(address _admin);
    event AdminUnpaused(address _admin);
    event AdminBaseUriUpdated(address _admin, string _newBaseURI);
    event AdminStatusFlipped(address _admin, address _walletAddress, bool _newStatus);
}