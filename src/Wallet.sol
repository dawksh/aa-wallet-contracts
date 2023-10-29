// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.19;

import {IEntryPoint} from "account-abstraction/interfaces/IEntryPoint.sol";

contract Wallet {
  address public immutable walletFactory;
  IEntryPoint private immutable _entryPoint;

  constructor(IEntryPoint entryPoint, address factory) {
    _entryPoint = entryPoint;
    walletFactory = factory;
  }

}

