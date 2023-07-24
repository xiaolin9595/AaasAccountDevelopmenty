// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../core/TxState.sol";
import "../samples/ASNAccountLogic.sol";
/**
 * helper contract for EntryPoint, to call userOp.initCode from a "neutral" address,
 * which is explicitly not the entryPoint itself.
 */
contract SenderCreator {

    /**
     * call the "initCode" factory to create and return the sender account address
     * @param initCode the initCode value from a UserOp. contains 20 bytes of factory address, followed by calldata
     * @return sender the returned address of the created account, or zero address on failure.
     */
    function createSender(bytes calldata initCode) external returns (address sender) {
        address factory = address(bytes20(initCode[0 : 20]));
        bytes memory initCallData = initCode[20 :];
        bool success;
        /* solhint-disable no-inline-assembly */
        assembly {
            success := call(gas(), factory, 0, add(initCallData, 0x20), mload(initCallData), 0, 32)
            sender := mload(0)
        }
        if (!success) {
            sender = address(0);
        }
    }
    function createAccountLogic( 
        IEntryPoint _entryPoint, address owner) public returns (ASNAccountLogic ret) {
        ASNAccountLogic accountImplementation = new ASNAccountLogic(_entryPoint );
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

