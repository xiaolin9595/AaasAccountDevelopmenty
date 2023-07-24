// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "/home/node/workspace/AaasAcountTest/account-abstraction/node_modules/@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "/home/node/workspace/AaasAcountTest/account-abstraction/node_modules/@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "/home/node/workspace/AaasAcountTest/account-abstraction/node_modules/@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

import "../core/~BaseAccount.sol";
import "./callback/~TokenCallbackHandler.sol";
import "../interfaces/~UserOperation.sol";
import "../core/~TxState.sol";
import "../interfaces/~DIDLibrary.sol";
import "../interfaces/~IASNAccount.sol";
contract ASNAccountLogic is
    BaseAccount,
    TokenCallbackHandler,
    UUPSUpgradeable,
    Initializable
{
    using ECDSA for bytes32;
    using UserOperationLib for UserOperation;
    using DIDLib for DID_Document;
    address public owner;
    IEntryPoint private immutable _entryPoint;
    TxState public immutable _txState;
    event AccountLogicContractInitialized(
        IEntryPoint indexed entryPoint,
        address indexed owner
    );
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
    modifier onlyItself() {
        _onlyItself();
        _;
    }
    modifier onlyTxState() {
        _onlyTxState();
        _;
    }

    /// @inheritdoc BaseAccount
    function entryPoint() public view virtual override returns (IEntryPoint) {
        return _entryPoint;
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    constructor(IEntryPoint anEntryPoint, TxState anTxState) {
        _entryPoint = anEntryPoint;
        _txState = anTxState;
        _disableInitializers();
    }

    function _onlyItself() internal view {
        //directly from EOA owner, or through the account itself (which gets redirected through execute())
        require(msg.sender == address(this), "only contact itself can call");
    }

    function _onlyTxState() internal view {
        //directly from EOA owner, or through the account itself (which gets redirected through execute())
        require(
            msg.sender == address(_txState),
            "only contact TxState can call"
        );
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
    function execute(
        bytes32 sender,
        address dest,
        uint256 value,
        bytes calldata func
    ) external {
        _requireFromEntryPoint();
        //todo
        address accountAddr = getSenderAccountAddr(sender);
        IASNAccount(accountAddr)._call(dest, value, func);
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

    function _validateSignature(
        UserOperation calldata userOp,
        bytes32 userOpHash
    ) internal virtual override returns (uint256 validationData) {}

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override {}
}