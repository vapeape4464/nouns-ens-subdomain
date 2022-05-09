// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {IResolver} from "../../ens/interfaces/IResolver.sol";

contract TestResolver is IResolver {
    mapping (bytes32 => address) addresses;

    function supportsInterface(bytes4 interfaceID) public override pure returns (bool) {
        return interfaceID == 0x01ffc9a7 || interfaceID == 0x3b3b57de;
    }

    function addr(bytes32 node) public view override returns (address) {
        return addresses[node];
    }

    function setAddr(bytes32 node, address _addr) public override {
        addresses[node] = _addr;
    }
}
