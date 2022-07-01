// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import { IRegistryRule } from "../IRegistryRule.sol";
import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

contract OnePerTokenRule is IRegistryRule {
    
    ERC721 token; 
    mapping (uint256 => bool) _usedTokens;
    constructor(ERC721 _token) {
        token = _token;
    }
    
    function canRegister(string calldata _label, address _sender) external pure returns (bool) {
        return false;
    }

    function canRegisterWithToken(string calldata _label, address _sender, uint _tokenId) external view returns (bool) {
        require(!_usedTokens[_tokenId]);
        require(token.ownerOf(_tokenId) == _sender);
        return true;
    }
}