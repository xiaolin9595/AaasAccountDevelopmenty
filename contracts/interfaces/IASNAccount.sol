// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "../interfaces/UserOperation.sol";
import "../interfaces/DIDLibrary.sol";
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
        bytes data;
        bytes l1TxHash;
    }
    function _call(address target, uint256 value, bytes calldata data) external ;
    function getOwner() external view returns (bytes32);
    function payPrefund(uint256 missingAccountFunds) external payable;
    function addL1txInfo(
        uint64 _chainId,
        address _from,
        address _receiver,
        uint256 _value,
        bytes memory data
    ) external  returns (uint64);
    function updateTxState(
        address _from,
        uint64 _seqNum,
        uint _state,
        bytes memory _txHash
    ) external ;
    function setDIDDocument(DID_Document calldata _didDocument) external;
}