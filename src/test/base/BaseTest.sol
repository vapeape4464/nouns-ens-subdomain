// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {DSTest} from "ds-test/test.sol";

import "forge-std/Vm.sol";
import {console} from "../utils/console.sol";

contract BaseTest is DSTest {
    Vm internal constant vm = Vm(HEVM_ADDRESS);
}
