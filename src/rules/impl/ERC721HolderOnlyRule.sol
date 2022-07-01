// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import { IRegistryRule } from "../IRegistryRule.sol";
import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

contract ERC721HolderOnlyRule is IRegistryRule {
    
    ERC721 token; 
    constructor(ERC721 _token) {
        token = _token;
    }
    
    function canRegisterWithToken(string calldata label, address _sender,uint _tokenId) external view returns (bool) {
        return token.balanceOf(_sender) > 0;
    }

    function canRegister(string calldata label, address _sender) external view returns (bool) {
        return token.balanceOf(_sender) > 0;
    }
}