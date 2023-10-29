// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.19;

import {BaseAccount} from "account-abstraction/core/BaseAccount.sol";
import {UserOperation} from "account-abstraction/interfaces/UserOperation.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IEntryPoint} from "account-abstraction/interfaces/IEntryPoint.sol";

contract Wallet is BaseAccount {
    address public immutable walletFactory;
    IEntryPoint private immutable _entryPoint;

    using ECDSA for bytes32;
    address[] public owners;

    constructor(IEntryPoint __entryPoint, address factory) {
        _entryPoint = __entryPoint;
        walletFactory = factory;
    }

    function entryPoint() public view override returns (IEntryPoint) {
        return _entryPoint;
    }

    function _validateSignature(
        UserOperation calldata userOp,
        bytes32 userOpHash
    ) internal view override returns (uint256) {
        bytes32 hash = userOpHash.toEthSignedMessageHash();
        bytes[] memory signatures = abi.decode(userOp.signature, (bytes[]));

        for (uint i = 0; i < owners.length; i++) {
            if (owners[i] != hash.recover(signatures[i])) {
                return SIG_VALIDATION_FAILED;
            }
        }

        return 0;
    }
}
