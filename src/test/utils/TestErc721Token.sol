// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

contract TestErc721Token is ERC721 {
    constructor() ERC721('Template', 'TEMPLATE') {}
}
