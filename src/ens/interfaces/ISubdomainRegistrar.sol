// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

interface ISubdomainRegistrar {
    event OwnerChanged(bytes32 indexed label, address indexed oldOwner, address indexed newOwner);
    event DomainConfigured(bytes32 indexed label);
    event DomainUnlisted(bytes32 indexed label);
    event NewRegistration(bytes32 indexed label, string subdomain, address indexed owner);
    event DomainTransferred(bytes32 indexed label, string name);

    function isSubdomainAvailable(bytes32 label, string calldata subdomain) external view returns (bool);
    function register(bytes32 label, string calldata subdomain, address owner) external;
}
