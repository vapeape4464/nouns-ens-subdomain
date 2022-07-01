// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import { AbstractSubdomainRegistrar } from "./AbstractSubdomainRegistrar.sol";
import { ENS } from "./ens/ENS.sol";
import { IBaseRegistrar } from "./ens/interfaces/IBaseRegistrar.sol";
import { IResolver } from "./ens/interfaces/IResolver.sol";
import { ERC721 } from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import { console } from "./test/utils/console.sol";

/// @title SubdomainRegistrar
/// @notice This contract owns ENS domains and enforces token permissioning for registering subdomains.
contract SubdomainRegistrar is AbstractSubdomainRegistrar {

    struct Domain {
        string name;
        address payable owner;
        uint price;
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
    function configureDomainFor(string memory _name, address payable _owner) public override owner_only(keccak256(bytes(_name))) {
        bytes32 label = keccak256(bytes(_name));
        Domain storage domain = domains[label];

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

    /// @notice Register and configure a subdomain.
    /// @param _label The domain hash/label used in ENS.
    /// @param _subdomain The subdomain name to register.
    /// @param _subdomainOwner TODO remove - since registration is deterministic we don't care who calls
    function register(bytes32 _label, string calldata _subdomain, address _subdomainOwner) external override not_stopped canRegisterSubdomain(_subdomain) {
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

    /// @notice Only can register if holding token
    /// @dev A simple auth model for allowing just token holders to register the subdomain that 
    /// coresponds to their token id. 
    /// This is not a perfect model because:
    /// 1. User can register unlimited submodules
    /// 2. User can transfer the subdomain to non-token holding account
    /// 3. User can transfer the token and still keep the subdomain
    modifier canRegisterSubdomain(string calldata subdomain) {
        // some subdomains are reserved for holders of the actual token. 
        uint p_int = parseInt(subdomain);
        require(p_int == 0 || token.ownerOf(p_int) == msg.sender);
        _;
    }

    /// @notice Convert string to uint if possible, if not return 0
    /// Seems slightly unsafe. lol 
    function parseInt(string calldata value) public pure returns (uint _ret) {
        unchecked {
            bytes memory _bytesValue = bytes(value);
            uint j = 1;
            for (uint i = _bytesValue.length - 1; i >= 0 && i < _bytesValue.length; i--) {
                if (uint8(_bytesValue[i]) >= 48 && uint8(_bytesValue[i]) <= 57) {
                    _ret += (uint8(_bytesValue[i]) - 48) * j;
                    j *= 10;
                } else {
                    return 0;
                }
            }
        }
    }

    // function isPotentialId(string calldata value) internal purereturns (bool) {
    //     return parseInt(value) != 0;
    // }
}