// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */
import "/home/node/workspace/AaasAcountTest/account-abstraction/node_modules/@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "/home/node/workspace/AaasAcountTest/account-abstraction/node_modules/@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "../interfaces/~UserOperation.sol";
import "../interfaces/~DIDLibrary.sol";
interface IASNAccount {

    enum State {
        GENERATED,
        SENT,
        PENDING,
        SUCCESSFUL,
        FAILED
    }
    /**
     * TransactionInfo struct
     * @param chainId L1 Chain ID.
     * @param from L1 transaction initiation address.
     * @param seqNum from account transaction sequence number
     * @param receiver L1 transaction receiving address
     * @param amount The size of the transaction amount.
     * @param state Transaction status
     * @param data Contract call data carried by transactions.
     * @param l1TxHash L1 transaction hash
     */

    struct TransactionInfo {
        uint64 chainId;
        address from;
        uint64 seqNum;
        address receiver;
        uint256 amount;
        State state;
        uint256 gasLimit;
        bytes data;
        bytes l1TxHash;
    }
    function _call(address target, uint256 value, bytes calldata data,) external ;
}