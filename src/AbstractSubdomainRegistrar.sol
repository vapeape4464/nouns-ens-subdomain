// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import { ENS } from "./ens/ENS.sol";
import { ISubdomainRegistrar } from "./ens/interfaces/ISubdomainRegistrar.sol";
import { ERC721 } from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

abstract contract AbstractSubdomainRegistrar is ISubdomainRegistrar {

    // namehash('eth')
    bytes32 constant public TLD_NODE = 0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae;

    bool public stopped = false;
    address public registrarOwner;
    address public migration;

    address immutable public registrar;

    ENS public ens;
    ERC721 public token;

    modifier owner_only(bytes32 label) {
        require(owner(label) == msg.sender);
        _;
    }

    modifier not_stopped() {
        require(!stopped);
        _;
    }

    modifier registrar_owner_only() {
        require(msg.sender == registrarOwner);
        _;
    }

    constructor(ENS _ens, ERC721 _token) {
        ens = _ens;
        token = _token;
        registrar = ens.owner(TLD_NODE);
        registrarOwner = msg.sender;
    }

    /**
     * @dev Sets the resolver record for a name in ENS.
     * @param name The name to set the resolver for.
     * @param resolver The address of the resolver.
     */
    function setResolver(string memory name, address resolver) public owner_only(keccak256(bytes(name))) {
        bytes32 label = keccak256(bytes(name));
        bytes32 node = keccak256(abi.encodePacked(TLD_NODE, label));
        ens.setResolver(node, resolver);
    }

    /**
     * @dev Configures a domain for subdomain registrations.
     * @param name The name to configure.
     */
    function configureDomain(string memory name) public {
        configureDomainFor(name, payable(msg.sender));
    }

    /**
     * @dev Stops the registrar, disabling configuring of new domains.
     */
    function stop() public not_stopped registrar_owner_only {
        stopped = true;
    }

    /**
     * @dev Sets the address where domains are migrated to.
     * @param _migration Address of the new registrar.
     */
    function setMigrationAddress(address _migration) public registrar_owner_only {
        require(stopped);
        migration = _migration;
    }

    /**
     * @dev Transfer ownership of this registrar to a new owner.
     * @param newOwner Address of the new owner.
     */
    function transferOwnership(address newOwner) public registrar_owner_only {
        registrarOwner = newOwner;
    }

    /**
     * @dev Returns if a subdomain is available to register.
     * @param label The label hash for the domain.
     * @param subdomain The label for the subdomain.
     * @return True if the subdomain is available.
     */
    function isSubdomainAvailable(bytes32 label, string calldata subdomain) external override view returns (bool) {
        bytes32 node = keccak256(abi.encodePacked(TLD_NODE, label));
        bytes32 subnode = keccak256(abi.encodePacked(node, keccak256(bytes(subdomain))));

        if (ens.owner(subnode) != address(0x0)) {
            return false;
        }
        return true;
    }

    function owner(bytes32 label) public virtual view returns (address);
    function configureDomainFor(string memory name, address payable _owner) public virtual;
}
