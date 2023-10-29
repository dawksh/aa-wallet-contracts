// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.19;

import {BaseAccount} from "account-abstraction/core/BaseAccount.sol";
import {UserOperation} from "account-abstraction/interfaces/UserOperation.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {IEntryPoint} from "account-abstraction/interfaces/IEntryPoint.sol";

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract Wallet is BaseAccount, Initializable {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    address public immutable walletFactory;
    IEntryPoint private immutable _entryPoint;
    address[] public owners;

    event WalletInitialized(IEntryPoint indexed entryPoint, address[] owners);

    constructor(IEntryPoint __entryPoint, address factory) {
        _entryPoint = __entryPoint;
        walletFactory = factory;
    }

    function initialize(address[] memory initialOwners) public initializer {
        _initialize(initialOwners);
    }

    function _initialize(address[] memory initialOwners) internal {
        if (initialOwners.length == 0) revert();
        owners = initialOwners;
        emit WalletInitialized(_entryPoint, owners);
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
