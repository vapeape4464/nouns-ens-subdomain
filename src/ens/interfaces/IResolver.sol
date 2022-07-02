pragma solidity >=0.8.4;

/**
 * @dev A basic interface for ENS resolvers.
 */
interface IResolver {
    function supportsInterface(bytes4 interfaceID) external pure returns (bool);

    function addr(bytes32 node) external view returns (address);

    function setAddr(bytes32 node, address _addr) external;
}
