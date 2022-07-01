// SPDX-License-Identifier: GPL-3 
pragma solidity ^0.8.4;

interface IRegistryRule {
    function canRegister(string calldata _label, address _sender) external returns (bool);
    function canRegisterWithToken(string calldata _label, address _sender, uint _tokenId) external returns (bool);
}