// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import { ENS } from "../ens/ENS.sol";
import { ENSRegistry } from "../ens/ENSRegistry.sol";
import { IResolver } from "../ens/interfaces/IResolver.sol";
import { IBaseRegistrar } from "../ens/interfaces/IBaseRegistrar.sol";
import { BaseRegistrarImplementation } from "../ens/BaseRegistrarImplementation.sol";
import { SubdomainRegistrar } from "../SubdomainRegistrar.sol";
import { BaseTest, console } from "./base/BaseTest.sol";
import { Namehash } from "./utils/namehash.sol";
import { TestResolver } from "./utils/TestResolver.sol";
import { TestErc721Token } from "./utils/TestErc721Token.sol";
import { IRegistryRule } from "../rules/IRegistryRule.sol";
import { ERC721HolderOnlyRule } from "../rules/impl/ERC721HolderOnlyRule.sol";
import { OnePerTokenRule } from "../rules/impl/OnePerTokenRule.sol";
import { ReservedTokenIdNames } from "../rules/impl/ReserverdTokenIdNames.sol";
import "forge-std/Vm.sol";

contract ContractTest is BaseTest {
    address controller = address(0x1337c);
    address bob = address(0x133702);
    address alice = address(0x133706969);
    bytes32 namehashEth = Namehash.namehash('eth');
    uint256 hashedTldNouns = uint256(keccak256(abi.encodePacked('nouns')));

    ENS ens;
    IBaseRegistrar registrar;
    SubdomainRegistrar subdomainRegistrar;
    IResolver resolver;
    TestErc721Token token;

    // Rules
    IRegistryRule reservedTokenIdsRule;
    IRegistryRule perTokenRule; 
    IRegistryRule tokenHolderRule;

    function setUp() public {
        vm.label(controller, "Controller");
        vm.label(bob, "Bob");
        vm.label(alice, "Alice");
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
        
        // Initialize SubdomainRegistrar and register nouns.eth.
        resolver = new TestResolver();
        token = new TestErc721Token();
        subdomainRegistrar = new SubdomainRegistrar(ens, token, resolver);
        // available rule sets 
        reservedTokenIdsRule = new ReservedTokenIdNames(token);
        perTokenRule = new OnePerTokenRule(token);
        tokenHolderRule = new ERC721HolderOnlyRule(token);

        registerTld(hashedTldNouns);
    }

    function testRegisterNounsDomain() public {
        assertEq(ens.owner(namehashEth), address(registrar));
        assertEq(ens.owner(Namehash.namehash('nouns.eth')), bob);
        assertEq(registrar.ownerOf(hashedTldNouns), bob);
    }
    
    function testRegisterSubdomainNoRules() public {
        vm.startPrank(bob);
        // must be the owner of the token to register 
        registrar.approve(address(subdomainRegistrar), hashedTldNouns);
        subdomainRegistrar.configureDomain('nouns');
        vm.stopPrank();

        vm.startPrank(alice);
        token.mint(alice, 111);
        token.mint(alice, 101);
        subdomainRegistrar.register(keccak256(abi.encodePacked('nouns')), 'alice', alice);
        subdomainRegistrar.register(keccak256(abi.encodePacked('nouns')), '111', alice);
        vm.stopPrank();

        vm.startPrank(bob);
        subdomainRegistrar.register(keccak256(abi.encodePacked('nouns')), 'bob', bob);
        subdomainRegistrar.register(keccak256(abi.encodePacked('nouns')), '2', bob);
        vm.stopPrank();

        assertEq(ens.owner(Namehash.namehash('alice.nouns.eth')), address(subdomainRegistrar));
        assertEq(resolver.addr(Namehash.namehash('alice.nouns.eth')), alice);
        assertEq(ens.owner(Namehash.namehash('111.nouns.eth')), address(subdomainRegistrar));
        assertEq(resolver.addr(Namehash.namehash('111.nouns.eth')), alice);
        assertEq(ens.owner(Namehash.namehash('bob.nouns.eth')), address(subdomainRegistrar));
        assertEq(resolver.addr(Namehash.namehash('bob.nouns.eth')), bob);
        assertEq(ens.owner(Namehash.namehash('2.nouns.eth')), address(subdomainRegistrar));
        assertEq(resolver.addr(Namehash.namehash('2.nouns.eth')), bob);
    }

    function testRegisterSubdomainTokenHoldersOnly() public {
        vm.startPrank(bob);
        // must be the owner of the token to register 
        registrar.approve(address(subdomainRegistrar), hashedTldNouns);
        subdomainRegistrar.configureDomainFor('nouns', payable(bob), tokenHolderRule);
        vm.stopPrank();

        vm.startPrank(alice);
        token.mint(alice, 1);
        subdomainRegistrar.register(keccak256(abi.encodePacked('nouns')), 'alice', alice);
        subdomainRegistrar.register(keccak256(abi.encodePacked('nouns')), '111', alice);
        vm.stopPrank();

        vm.startPrank(bob);
        vm.expectRevert(); // should not be able to register when not holding token
        subdomainRegistrar.register(keccak256(abi.encodePacked('nouns')), '101', bob);
        vm.stopPrank();

        assertEq(ens.owner(Namehash.namehash('alice.nouns.eth')), address(subdomainRegistrar));
        assertEq(resolver.addr(Namehash.namehash('alice.nouns.eth')), alice);
        assertEq(ens.owner(Namehash.namehash('111.nouns.eth')), address(subdomainRegistrar));
        assertEq(resolver.addr(Namehash.namehash('111.nouns.eth')), alice);
    }

    function testRegisterSubdomainReservedNames() public {
        vm.startPrank(bob);
        registrar.approve(address(subdomainRegistrar), hashedTldNouns);
        subdomainRegistrar.configureDomainFor('nouns', payable(bob), reservedTokenIdsRule);
        vm.stopPrank();

        vm.startPrank(alice);
        token.mint(alice, 111);
        subdomainRegistrar.registerWithToken(keccak256(abi.encodePacked('nouns')), '111', alice, 111);
        vm.expectRevert(); 
        subdomainRegistrar.registerWithToken(keccak256(abi.encodePacked('nouns')), 'alice', alice, 111);
        vm.expectRevert(); 
        subdomainRegistrar.register(keccak256(abi.encodePacked('nouns')), 'alice', alice);
        vm.stopPrank();

        vm.startPrank(bob);
        vm.expectRevert(); // should not be able to register when not holding token
        subdomainRegistrar.register(keccak256(abi.encodePacked('nouns')), 'bob', bob);
        vm.stopPrank();

        assertEq(ens.owner(Namehash.namehash('111.nouns.eth')), address(subdomainRegistrar));
        assertEq(resolver.addr(Namehash.namehash('111.nouns.eth')), alice);
    }

    function testRegisterSubdomainOnlyOne() public {
        vm.startPrank(bob);
        registrar.approve(address(subdomainRegistrar), hashedTldNouns);
        subdomainRegistrar.configureDomainFor('nouns', payable(bob), reservedTokenIdsRule);
        vm.stopPrank();

        vm.startPrank(alice);
        token.mint(alice, 111);
        subdomainRegistrar.registerWithToken(keccak256(abi.encodePacked('nouns')), '111', alice, 111);
        vm.expectRevert(); 
        subdomainRegistrar.register(keccak256(abi.encodePacked('nouns')), '222', alice);
        vm.expectRevert(); 
        subdomainRegistrar.registerWithToken(keccak256(abi.encodePacked('nouns')), 'alice', alice, 111);
        vm.stopPrank();

        vm.startPrank(bob);
        vm.expectRevert(); // should not be able to register when not holding token
        subdomainRegistrar.register(keccak256(abi.encodePacked('nouns')), 'bob', bob);
        vm.stopPrank();

        assertEq(ens.owner(Namehash.namehash('111.nouns.eth')), address(subdomainRegistrar));
        assertEq(resolver.addr(Namehash.namehash('111.nouns.eth')), alice);
    }
    
    function registerTld(uint256 hashedTld) private {
        vm.startPrank(controller);
        registrar.register(
            hashedTld,
            bob,
            1 days
        );
        vm.stopPrank();
    }
}
