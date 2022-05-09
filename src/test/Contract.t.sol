// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {ENS} from "../ens/ENS.sol";
import {ENSRegistry} from "../ens/ENSRegistry.sol";
import {IBaseRegistrar} from "../ens/interfaces/IBaseRegistrar.sol";
import {BaseRegistrarImplementation} from "../ens/BaseRegistrarImplementation.sol";
import {BaseTest, console} from "./base/BaseTest.sol";
import {Namehash} from "./utils/namehash.sol";
import "forge-std/Vm.sol";

contract ContractTest is BaseTest {

    address controller = address(0x1337c);
    address bob = address(0x133702);
    bytes32 namehashEth = Namehash.namehash('eth');

    ENS ens;
    IBaseRegistrar registrar;

    function setUp() public {
        vm.label(controller, "Controller");
        vm.label(bob, "Bob");
        vm.label(address(this), "TestContract");

        ens = new ENSRegistry();
        registrar = new BaseRegistrarImplementation(ens, namehashEth);

        // Bootstrap ENS.
        registrar.addController(controller);
        ens.setSubnodeOwner(
            bytes32(0),
            keccak256(abi.encodePacked('eth')),
            address(registrar)
        );
        vm.warp(90 days + 1); // Warp ahead of the ENS grace period.
    }

    function testValidateSetUp() public {
        assertEq(Namehash.namehash('eth'), 0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae);
        assertEq(ens.owner(namehashEth), address(registrar));
    }

    function testRegisterNounsDomain() public {
        uint256 hashedNouns = uint256(keccak256(abi.encodePacked('nouns')));
        vm.startPrank(controller);
        registrar.register(
            hashedNouns,
            bob,
            1 days
        );
        vm.stopPrank();

        assertEq(ens.owner(Namehash.namehash('nouns.eth')), bob);
        assertEq(registrar.ownerOf(hashedNouns), bob);
    }
}
