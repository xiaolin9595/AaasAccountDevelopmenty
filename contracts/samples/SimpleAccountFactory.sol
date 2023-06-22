// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../core/TxState.sol";
import "./SimpleAccount.sol";

/**
 * A sample factory contract for SimpleAccount
 * A UserOperations "initCode" holds the address of the factory, and a method call (to createAccount, in this sample factory).
 * The factory's createAccount returns the target account address even if it is already installed.
 * This way, the entryPoint.getSenderAddress() can be called either before or after the account is created.
 */
contract SimpleAccountFactory {
    SimpleAccount public immutable accountImplementation;

    constructor(IEntryPoint _entryPoint, TxState _TxState) {
        accountImplementation = new SimpleAccount(_entryPoint, _TxState);
    }

    /**
     * create an account, and return its address.
     * returns the address even if the account is already deployed.
     * Note that during UserOperation execution, this method is called only if the account is not deployed.
     * This method returns an existing account address so that entryPoint.getSenderAddress() would work even after account creation
     */
    function createAccount(
        bytes calldata owner,
        uint256 salt
    ) public returns (SimpleAccount ret) {
        (address addr, bytes32 ownerhash) = getAddress(owner, salt);
        uint codeSize = addr.code.length;
        if (codeSize > 0) {
            return SimpleAccount(payable(addr));
        }
        ret = SimpleAccount(
            payable(
                new ERC1967Proxy{salt: bytes32(salt)}(
                    address(accountImplementation),
                    abi.encodeCall(SimpleAccount.initialize, (ownerhash))
                )
            )
        );
    }

    /**
     * calculate the counterfactual address of this account as it would be returned by createAccount()
     */
    function getAddress(
        bytes calldata owner,
        uint256 salt
    ) public view returns (address, bytes32) {
        bytes32 ownerhash = keccak256(owner);
        address addr = Create2.computeAddress(
            bytes32(salt),
            keccak256(
                abi.encodePacked(
                    type(ERC1967Proxy).creationCode,
                    abi.encode(
                        address(accountImplementation),
                        abi.encodeCall(SimpleAccount.initialize, (ownerhash))
                    )
                )
            )
        );
        return (addr, ownerhash);
    }
}
