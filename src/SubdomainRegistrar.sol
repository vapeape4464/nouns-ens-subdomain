// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import { AbstractSubdomainRegistrar } from "./AbstractSubdomainRegistrar.sol";
import { ENS } from "./ens/ENS.sol";
import { IBaseRegistrar } from "./ens/interfaces/IBaseRegistrar.sol";
import { IResolver } from "./ens/interfaces/IResolver.sol";
import { ERC721 } from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import { console } from "./test/utils/console.sol";
import { IRegistryRule } from "./rules/IRegistryRule.sol";

/// @title SubdomainRegistrar
/// @notice This contract owns ENS domains and enforces token permissioning for registering subdomains.
contract SubdomainRegistrar is AbstractSubdomainRegistrar {

    struct Domain {
        string name;
        address payable owner;
        uint price;
        IRegistryRule rule;
    }

    /// @dev Domain name hash/label => Domain.
    mapping (bytes32 => Domain) domains;

    IResolver public immutable resolver;

    /// @param _ens The ENS instance.
    /// @param _token The ERC721 token used to enforce permissions.
    /// @param _resolver The default ENS resolver for subdomains.
    constructor(ENS _ens, ERC721 _token, IResolver _resolver) AbstractSubdomainRegistrar(_ens, _token) {
        resolver = _resolver;
    }

    /// @notice If the domain is configured returns the internal owner, otherwise returns ENS owner.
    /// @param _label The domain name hash/label.
    /// @return address The current owner.
    function owner(bytes32 _label) public override view returns (address) {
        if (domains[_label].owner != address(0x0)) {
            return domains[_label].owner;
        }
        return IBaseRegistrar(registrar).ownerOf(uint256(_label));
    }

    /// @notice Transfer internal domain ownership to a new owner.
    /// @param _name The domain name eg. nouns.
    /// @param _newOwner The address of the new owner.
    function transfer(string memory _name, address payable _newOwner) public owner_only(keccak256(bytes(_name))) {
        bytes32 label = keccak256(bytes(_name));
        emit OwnerChanged(label, domains[label].owner, _newOwner);
        domains[label].owner = _newOwner;
    }

    /// @notice Configure a domain for internal use.
    /// @param _name The domain name eg. nouns.
    /// @param _owner The address of the internal owner.
    function configureDomainFor(string memory _name, address payable _owner, IRegistryRule _rule) public override owner_only(keccak256(bytes(_name))) {
        bytes32 label = keccak256(bytes(_name));
        Domain storage domain = domains[label];
        domain.rule = _rule;

        if (IBaseRegistrar(registrar).ownerOf(uint256(label)) != address(this)) {
            // Transfer ENS ownership to this.
            IBaseRegistrar(registrar).transferFrom(msg.sender, address(this), uint256(label));
            IBaseRegistrar(registrar).reclaim(uint256(label), address(this));
        }

        if (domain.owner != _owner) {
            domain.owner = _owner;
        }

        if (keccak256(bytes(domain.name)) != label) {
            // New listing
            domain.name = _name;
        }

        emit DomainConfigured(label);
    }

     /// @dev Registers a subdomain.
     /// @param _label The label hash of the domain to register a subdomain of.
     /// @param _subdomain The desired subdomain label.
     /// @param _subdomainOwner The account that should own the newly configured subdomain.
    function register(bytes32 _label, string calldata _subdomain, address _subdomainOwner) 
                external override not_stopped canRegisterSubdomain(domains[_label].rule, _subdomain) {
        _register(_label, _subdomain, _subdomainOwner);
    }

    function registerWithToken(bytes32 _label, string calldata _subdomain, address _subdomainOwner, uint tokenId) 
                external not_stopped canRegisterSubdomainWithToken(domains[_label].rule, _subdomain, tokenId) {
        _register(_label, _subdomain, _subdomainOwner);
    }

    function _register(bytes32 _label, string calldata _subdomain, address _subdomainOwner) internal {
        address subdomainOwner = _subdomainOwner;
        bytes32 domainNode = keccak256(abi.encodePacked(TLD_NODE, _label));
        bytes memory subdomainBytes = bytes(_subdomain);
        bytes32 subdomainLabel = keccak256(subdomainBytes);

        // Subdomain must not be registered already.
        require(ens.owner(keccak256(abi.encodePacked(domainNode, subdomainLabel))) == address(0));

        Domain storage domain = domains[_label];

        // Domain must be available for registration
        require(keccak256(bytes(domain.name)) == _label);

        // Register the domain
        if (subdomainOwner == address(0x0)) {
            subdomainOwner = msg.sender;
        }

        bytes32 subnode = keccak256(abi.encodePacked(domainNode, subdomainLabel));

        // Set the subdomain owner so we can configure it
        ens.setSubnodeOwner(domainNode, subdomainLabel, address(this));

        // Set the subdomain's resolver
        ens.setResolver(subnode, address(resolver));

        // Set the address record on the resolver
        resolver.setAddr(subnode, subdomainOwner);

        // uint256 tokenId = uint256(subnode);
        // _safeMint(_subdomainOwner, tokenId);
        // _setTokenURI(tokenId, metadata.uri);

        emit NewRegistration(_label, _subdomain, subdomainOwner);
    }

    modifier canRegisterSubdomainWithToken(IRegistryRule rule, string calldata subdomain, uint tokenId) {
        require(rule.canRegisterWithToken(subdomain, msg.sender, tokenId));
        _;
    }

    modifier canRegisterSubdomain(IRegistryRule rule, string calldata subdomain) {
        require(address(rule) == address(0) || rule.canRegister(subdomain, msg.sender));
        _;
    }
}