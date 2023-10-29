// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.19;

import {BaseAccount} from "account-abstraction/core/BaseAccount.sol";
import {UserOperation} from "account-abstraction/interfaces/UserOperation.sol";
import {IEntryPoint} from "account-abstraction/interfaces/IEntryPoint.sol";

import {TokenCallbackHandler} from "./TokenCallbackHandler.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

contract Wallet is
    BaseAccount,
    Initializable,
    UUPSUpgradeable,
    TokenCallbackHandler
{
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    address public immutable walletFactory;
    IEntryPoint private immutable _entryPoint;
    address[] public owners;

    event WalletInitialized(IEntryPoint indexed entryPoint, address[] owners);

    modifier _requireFromEntryPointOrFactory() {
        if (msg.sender != address(_entryPoint) || msg.sender != walletFactory)
            revert();
        _;
    }

    constructor(IEntryPoint __entryPoint, address factory) {
        _entryPoint = __entryPoint;
        walletFactory = factory;
    }

    // Initialization

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

    // Main Function

    function execute(
        address dest,
        uint256 value,
        bytes calldata fn
    ) external _requireFromEntryPointOrFactory {
        _call(dest, value, fn);
    }

    function executeBatch(
        address[] calldata dests,
        uint256[] calldata values,
        bytes[] calldata fns
    ) external _requireFromEntryPointOrFactory {
        if (dests.length != fns.length) revert();
        if (values.length != fns.length) revert();
        uint256 len = dests.length;
        for (uint256 i = 0; i < len; ) {
            _call(dests[i], values[i], fns[i]);
            unchecked {
                i++;
            }
        }
    }

    // Internals

    function _call(
        address targetAddress,
        uint256 value,
        bytes memory data
    ) internal {
        (bool success, bytes memory result) = targetAddress.call{value: value}(
            data
        );
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
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

    function _authorizeUpgrade(
        address
    ) internal override _requireFromEntryPointOrFactory {}

    // Helpers

    function encodeSignatures(
        bytes[] memory signatures
    ) public pure returns (bytes memory) {
        return abi.encode(signatures);
    }

    function getDeposit() public view returns (uint256) {
        return entryPoint().balanceOf(address(this));
    }

    function addDeposit() public payable {
        entryPoint().depositTo{value: msg.value}(address(this));
    }

    receive() external payable {}
}
