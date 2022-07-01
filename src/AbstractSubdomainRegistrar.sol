// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import { ENS } from "./ens/ENS.sol";
import { ISubdomainRegistrar } from "./ens/interfaces/ISubdomainRegistrar.sol";
import { IRegistryRule } from "./rules/IRegistryRule.sol";
import { ERC721 } from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

/// @title Abstract implementation of a SubdomainRegistrar
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

    /// @param _ens The ENS instance.
    /// @param _token The ERC721 token used to enforce permissions.
    constructor(ENS _ens, ERC721 _token) {
        ens = _ens;
        token = _token;
        registrar = ens.owner(TLD_NODE);
        registrarOwner = msg.sender;
    }

    /// @notice Configure a domain for subdomain registrations.
    /// @param _name The domain name.
    function configureDomain(string memory _name) public {
        configureDomainFor(_name, payable(msg.sender), IRegistryRule(address(0)));
    }

    /// @notice Stop the registrar from configuring new domains.
    function stop() public not_stopped registrar_owner_only {
        stopped = true;
    }

    /// @notice Set a domain registrar migration address.
    /// @param _migration Address of the new registrar.
    function setMigrationAddress(address _migration) public registrar_owner_only {
        require(stopped);
        migration = _migration;
    }

    /// @notice Transfer ownership of this registrar.
    /// @param _newOwner Address of the new owner.
    function transferOwnership(address _newOwner) public registrar_owner_only {
        registrarOwner = _newOwner;
    }

    /// @notice Return if a subdomain is available to register.
    /// @param _label The ENS hash/label for the domain.
    /// @param _subdomain The desired subdomain.
    /// @return True If the subdomain is available to register.
    function isSubdomainAvailable(bytes32 _label, string calldata _subdomain) external override view returns (bool) {
        bytes32 node = keccak256(abi.encodePacked(TLD_NODE, _label));
        bytes32 subnode = keccak256(abi.encodePacked(node, keccak256(bytes(_subdomain))));

        if (ens.owner(subnode) != address(0x0)) {
            return false;
        }
        return true;
    }

    function owner(bytes32 _label) public virtual view returns (address);
    function configureDomainFor(string memory _name, address payable _owner, IRegistryRule _rule) public virtual;
}
