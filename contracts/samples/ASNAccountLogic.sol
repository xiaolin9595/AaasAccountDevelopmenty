// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

import "../core/BaseAccount.sol";
import "./callback/TokenCallbackHandler.sol";
import "../interfaces/UserOperation.sol";
import "../core/TxState.sol";
import "../interfaces/DIDLibrary.sol";
import "../interfaces/IASNAccount.sol";
import "./ASNAccount.sol";
import "../core/AccountList.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
contract ASNAccountLogic is
    BaseAccount,
    TokenCallbackHandler,
    UUPSUpgradeable,
    Initializable,
    ReentrancyGuard
{
    using ECDSA for bytes32;
    using UserOperationLib for UserOperation;
    using DIDLib for DID_Document;
    address public owner;
    IEntryPoint private immutable _entryPoint;
    event AccountLogicContractInitialized(
        IEntryPoint indexed entryPoint,
        address indexed owner
    );
    event L1transferEvent(
        address indexed account,
        address indexed from,
        uint64 indexed seqNum,
        TransactionInfo txInfo
    );
    event updateTxStateSuccess(bytes indexed L1Txhash, uint state);
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
    //function seletor table
    struct SelectorTable {
        bytes32 execute;
        bytes32 proposeTxToL1;
        bytes32 modifyDIDDocument;
    }
    SelectorTable public selectortable;
    // A memory copy of UserOp static fields only.
    // Excluding: callData, initCode and signature. Replacing paymasterAndData with paymaster.
    struct MemoryUserOp {
        address sender;
        uint256 nonce;
        bytes callData;
        uint256 callGasLimit;
        uint256 verificationGasLimit;
        uint256 preVerificationGas;
        address paymaster;
        uint256 maxFeePerGas;
        uint256 maxPriorityFeePerGas;
        bytes fidoPubkey;
    }
    modifier onlyItself() {
        _onlyItself();
        _;
    }
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /// @inheritdoc BaseAccount
    function entryPoint() public view virtual override returns (IEntryPoint) {
        return _entryPoint;
    }

    function onlyentrypoint() internal view {
        require(
            msg.sender == address(entryPoint()),
            "only entrypoint can call"
        );
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    constructor(IEntryPoint anEntryPoint) {
        _entryPoint = anEntryPoint;
        selectortable.execute = keccak256(
            "execute(address,address,uint256,bytes)"
        );
        selectortable.modifyDIDDocument = keccak256(
            "modifyDIDDocument(DID_Document)"
        );
        selectortable.proposeTxToL1 = keccak256(
            "proposeTxToL1(uint64,address,address,uint256,bytes)"
        );
        _disableInitializers();
    }

    function _onlyItself() internal view {
        //directly from EOA owner, or through the account itself (which gets redirected through execute())
        require(msg.sender == address(this), "only contact itself can call");
    }

    /**
     * Handle Useroperation
     */
    function handleUserOperation(
        address sender,
        bytes memory calldata1
    ) public nonReentrant returns (bool success) {
        _requireFromEntryPoint();
        (bytes32 selector, bytes memory pram) = abi.decode(
            calldata1,
            (bytes32, bytes)
        );
        if (selector == selectortable.execute) {
            execute(sender, pram);
        }
        if (selector == selectortable.proposeTxToL1) {
            proposeTxToL1(sender, pram);
        }
        if (selector == selectortable.modifyDIDDocument) {
            modifyDIDDocument(sender, pram);
        }
        return true;
    }

    /**
     *Retrieve account data contract address
     */
    function getSenderAccountAddr(
        bytes32 sender
    ) internal view returns (address) {
        return address(this);
    }

    /**
     * execute a transaction (called directly from owner, or by entryPoint)
     */
    function execute(address sender, bytes memory pram) internal {
        _onlyItself();
        (address dest, uint256 value, bytes memory func) = abi.decode(
            pram,
            (address, uint256, bytes)
        );
        IASNAccount(sender)._call(dest, value, func);
    }

    function _validateSignature(
        UserOperation calldata userOp,
        bytes32 userOpHash
    ) internal virtual override returns (uint256 validationData) {
        require(
            userOpHash ==
                keccak256(
                    abi.encode(
                        userOp.hash(),
                        address(entryPoint()),
                        block.chainid
                    )
                ),
            "userOp verify failed"
        );
        bytes32 ownerOfAccount = IASNAccount(userOp.sender).getOwner();
        bytes32 ownerhash = keccak256(userOp.fidoPubKey);
        if (ownerOfAccount == ownerhash) return 0;

        return SIG_VALIDATION_FAILED;
    }

    /**
     * execute a sequence of transactions
     */
    // function executeBatch(
    //     address[] calldata dest,
    //     bytes[] calldata func
    // ) external {
    //     _requireFromEntryPoint();
    //     //todo
    //     require(dest.length == func.length, "wrong array lengths");
    //     for (uint256 i = 0; i < dest.length; i++) {
    //         _call(dest[i], 0, func[i]);
    //     }
    // }
    /**
     * @dev The _entryPoint member is immutable, to reduce gas consumption.  To upgrade EntryPoint,
     * a new implementation of SimpleAccount must be deployed with the new EntryPoint address, then upgrading
     * the implementation by calling `upgradeTo()`
     */
    function initialize(address anOwner) public virtual initializer {
        _initialize(anOwner);
    }

    function _initialize(address anOwner) internal virtual {
        owner = anOwner;
        emit AccountLogicContractInitialized(_entryPoint, owner);
    }

    function proposeTxToL1(address senderAccount, bytes memory pram) internal {
        _onlyItself();
        (
            uint64 _chainId,
            address _from,
            address _receiver,
            uint256 _value,
            bytes memory _data
        ) = abi.decode(pram, (uint64, address, address, uint256, bytes));
        uint64 _seqNum = IASNAccount(senderAccount).addL1txInfo(
            _chainId,
            _from,
            _receiver,
            _value,
            _data
        );
        TransactionInfo memory txInfo = TransactionInfo(
            _chainId,
            _from,
            _seqNum,
            _receiver,
            _value,
            State.GENERATED,
            _data,
            ""
        );
        emit L1transferEvent(senderAccount, _from, _seqNum, txInfo);
    }

    /**
     * Update L1 transaction status
    /*The back-end obtains the corresponding account contract address through from and seqNum, and then calls the updateTxState method of the account contract to update the transaction status
    */
    function setL1TxState(
        bytes calldata _txHash,
        address l2Account,
        address _from,
        uint64 _seqNum,
        uint _state
    ) public payable onlyOwner {
        try
            IASNAccount(l2Account).updateTxState{gas: gasleft()}(
                _from,
                _seqNum,
                _state,
                _txHash
            )
        {
            emit updateTxStateSuccess(_txHash, _state);
        } catch {
            revert("updateTxState failed");
        }
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override {}

    function _payPrefund(
        uint256 missingAccountFunds,
        address sender
    ) internal virtual override {
        IASNAccount(sender).payPrefund(missingAccountFunds);
    }

    function modifyDIDDocument(address sender, bytes memory pram) internal {
        _onlyItself();
        DID_Document memory _didDocument = abi.decode(pram, (DID_Document));
        IASNAccount(sender).setDIDDocument(_didDocument);
    }

    function updateTxState(
        address _from,
        uint64 _seqNum,
        uint _state,
        bytes memory _txHash
    ) external override {}

    function addL1txInfo(
        uint64 _chainId,
        address _from,
        address _receiver,
        uint256 _value,
        uint256 gasLimt,
        bytes memory data
    ) external override returns (uint64) {}
}