// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {WalletFactory} from "../src/WalletFactory.sol";
import {Wallet} from "../src/Wallet.sol";
import {IEntryPoint} from "account-abstraction/interfaces/IEntryPoint.sol";
import {Test, console2} from "forge-std/Test.sol";

contract CounterTest is Test {
    WalletFactory factory;
    address[] owners = [address(this)];
    uint256 immutable salt = 20193;
    address deployedWallet;

    function setUp() public {
        factory = new WalletFactory(
            IEntryPoint(0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789)
        );
        deployedWallet = address(factory.createAccount(owners, salt));
    }

    function testCreateAccount() public {
        address wallet = factory.getAddress(owners, salt);
        assert(wallet == deployedWallet);
    }

    function testRevertAccount() public {
        address wallet = factory.getAddress(owners, 0);
        assert(wallet != address(factory.createAccount(owners, salt)));
    }

    function testDeployedWallet() public {
        uint size;
        assembly {
            size := extcodesize(sload(deployedWallet.slot))
        }
        if (size == 0) revert();
    }
}
