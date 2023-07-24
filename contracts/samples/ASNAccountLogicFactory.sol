// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../core/TxState.sol";
import "./ASNAccountLogic.sol";

/**
 * A sample factory contract for ASNAccountLogic
 * A UserOperations "initCode" holds the address of the factory, and a method call (to createAccount, in this sample factory).
 * The factory's createAccount returns the target account address even if it is already installed.
 * This way, the entryPoint.getSenderAddress() can be called either before or after the account is created.
 */
contract ASNAccountLogicFactory {
    ASNAccountLogic public immutable accountImplementation;

    constructor(IEntryPoint _entryPoint) {
        accountImplementation = new ASNAccountLogic(_entryPoint);
    }

    /**
     * create an account, and return its address.
     * returns the address even if the account is already deployed.
     * Note that during UserOperation execution, this method is called only if the account is not deployed.
     * This method returns an existing account address so that entryPoint.getSenderAddress() would work even after account creation
     */
    function createAccount(
        address  owner
    ) public returns (ASNAccountLogic ret) {
        
        ret = ASNAccountLogic(
            payable(
                new ERC1967Proxy(
                    address(accountImplementation),
                    abi.encodeCall(ASNAccountLogic.initialize, (owner))
                )
            )
        );
    }

}
