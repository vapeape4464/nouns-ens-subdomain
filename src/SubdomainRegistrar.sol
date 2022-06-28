// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import {AbstractSubdomainRegistrar} from "./AbstractSubdomainRegistrar.sol";
import {ENS} from "./ens/ENS.sol";
import {IBaseRegistrar} from "./ens/interfaces/IBaseRegistrar.sol";
import {IResolver} from "./ens/interfaces/IResolver.sol";
import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

contract SubdomainRegistrar is AbstractSubdomainRegistrar {

    struct Domain {
        string name;
        address payable owner;
        uint price;
    }

    mapping (bytes32 => Domain) domains;

    IResolver immutable public resolver;

    constructor(ENS ens, ERC721 token, IResolver _resolver) AbstractSubdomainRegistrar(ens, token) {
        resolver = _resolver;
    }

    /**
     * @dev owner returns the address of the account that controls a domain.
     *      Initially this is a null address. If the name has been
     *      transferred to this contract, then the internal mapping is consulted
     *      to determine who controls it. If the owner is not set,
     *      the owner of the domain in the TLD Registrar is returned.
     * @param label The label hash to check.
     * @return The address owning the label.
     */
    function owner(bytes32 label) public override view returns (address) {
        if (domains[label].owner != address(0x0)) {
            return domains[label].owner;
        }
        return IBaseRegistrar(registrar).ownerOf(uint256(label));
    }

    /**
     * @dev Transfers internal control of a name to a new account. Does not update ENS.
     * @param name The name to transfer.
     * @param newOwner The address of the new owner.
     */
    function transfer(string memory name, address payable newOwner) public owner_only(keccak256(bytes(name))) {
        bytes32 label = keccak256(bytes(name));
        emit OwnerChanged(label, domains[label].owner, newOwner);
        domains[label].owner = newOwner;
    }

    /**
     * @dev Configures and updates ownership of a domain.
     * @param name The name to configure.
     * @param _owner The address to assign ownership of this domain to.
     */
    function configureDomainFor(string memory name, address payable _owner) public override owner_only(keccak256(bytes(name))) {
        bytes32 label = keccak256(bytes(name));
        Domain storage domain = domains[label];

        if (IBaseRegistrar(registrar).ownerOf(uint256(label)) != address(this)) {
            IBaseRegistrar(registrar).transferFrom(msg.sender, address(this), uint256(label));
            IBaseRegistrar(registrar).reclaim(uint256(label), address(this));
        }

        if (domain.owner != _owner) {
            domain.owner = _owner;
        }

        if (keccak256(bytes(domain.name)) != label) {
            // New listing
            domain.name = name;
        }
        emit DomainConfigured(label);
    }

    /**
     * @dev Registers a subdomain.
     * @param label The label hash of the domain to register a subdomain of.
     * @param subdomain The desired subdomain label.
     * @param _subdomainOwner The account that should own the newly configured subdomain.
     */
    function register(bytes32 label, string calldata subdomain, address _subdomainOwner) external override not_stopped {
        address subdomainOwner = _subdomainOwner;
        bytes32 domainNode = keccak256(abi.encodePacked(TLD_NODE, label));
        bytes memory subdomainBytes = bytes(subdomain);
        bytes32 subdomainLabel = keccak256(subdomainBytes);

        // Subdomain must not be registered already.
        require(ens.owner(keccak256(abi.encodePacked(domainNode, subdomainLabel))) == address(0));

        Domain storage domain = domains[label];

        // Domain must be available for registration
        require(keccak256(bytes(domain.name)) == label);

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

        emit NewRegistration(label, subdomain, subdomainOwner);
    }

}