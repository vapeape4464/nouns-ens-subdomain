// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import {IRegistryRule} from '../IRegistryRule.sol';
import {ERC721} from 'openzeppelin-contracts/contracts/token/ERC721/ERC721.sol';

contract ReservedTokenIdNames is IRegistryRule {
    ERC721 token;

    constructor(ERC721 _token) {
        token = _token;
    }

    function canRegister(string calldata _label, address _sender) external pure returns (bool) {
        return false;
    }

    function canRegisterWithToken(
        string calldata _label,
        address _sender,
        uint256 _tokenId
    ) external view returns (bool) {
        // some subdomains are reserved for holders of the actual token.
        uint256 p_int = parseInt(_label);
        return (p_int == _tokenId && token.ownerOf(p_int) == _sender);
    }

    /// @notice Convert string to uint if possible, if not return 0
    /// Seems slightly unsafe. lol
    function parseInt(string calldata _value) public pure returns (uint256 _ret) {
        unchecked {
            bytes memory _bytesValue = bytes(_value);
            uint256 j = 1;
            for (uint256 i = _bytesValue.length - 1; i >= 0 && i < _bytesValue.length; i--) {
                if (uint8(_bytesValue[i]) >= 48 && uint8(_bytesValue[i]) <= 57) {
                    _ret += (uint8(_bytesValue[i]) - 48) * j;
                    j *= 10;
                } else {
                    return 0;
                }
            }
        }
    }
}
