// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "./callback/TokenCallbackHandler.sol";
import "../interfaces/UserOperation.sol";
import "../interfaces/DIDLibrary.sol";
import "./ASNAccountLogic.sol";
import "../interfaces/IEntryPoint.sol";
import "../interfaces/IASNAccount.sol";
contract ASNAccount is
    TokenCallbackHandler,
    UUPSUpgradeable,
    Initializable,
    IASNAccount
{
    bytes32 public owner;
    ASNAccountLogic private immutable accountLogic;
    IEntryPoint private immutable _entryPoint;
    event ASNAccountInitialized(
        IEntryPoint indexed entryPoint,
        ASNAccountLogic indexed accountLogic,
        bytes32 indexed owner
    );

    //Transaction information corresponding to the number of transactions
    mapping(address => mapping(uint64 => TransactionInfo)) public TxsInfo;
    //SeqNum corresponding to L1 address
    mapping(address => uint64) public SequenceNumber;
    //DID document corresponding to DID
    mapping(string => DID_Document) public DID_Documents;
    modifier onlyItself() {
        _onlyItself();
        _;
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    constructor(IEntryPoint entryPoint, ASNAccountLogic _accountLogic) {
        _entryPoint = entryPoint;
        accountLogic = _accountLogic;
        _disableInitializers();
    }

    function _onlyItself() internal view {
        //directly from EOA owner, or through the account itself (which gets redirected through execute())
        require(msg.sender == address(this), "only contact itself can call");
    }
    function _onlyaccountLogic() internal view {
        //directly from EOA owner, or through the account itself (which gets redirected through execute())
        require(msg.sender == address(accountLogic), "only accountLogic contact  can call");
    }
    function initialize(bytes32 anOwner) public virtual initializer {
        _initialize(anOwner);
    }

    function _initialize(bytes32 anOwner) internal virtual {
        owner = anOwner;
        emit ASNAccountInitialized(_entryPoint, accountLogic, owner);
    }

    function _call(address target, uint256 value, bytes memory data) external {
        (bool success, bytes memory result) = target.call{value: value}(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override {}

    function getOwner() external view returns (bytes32){
        return owner;
    }
    function payPrefund(uint256 missingAccountFunds) external payable{
        _onlyaccountLogic();
        if (missingAccountFunds != 0) {
            (bool success,) = payable(address(_entryPoint)).call{value : missingAccountFunds, gas : type(uint256).max}("");
            (success);
            //ignore failure (its EntryPoint's job to verify, not account.)
        }
    }
    function addL1txInfo(
        uint64 _chainId,
        address _from,
        address _receiver,
        uint256 _value,
        bytes memory data
    ) external override returns (uint64) {
        _onlyaccountLogic();
        uint64 seqNum = SequenceNumber[_from] + 1;
        SequenceNumber[_from] = seqNum;
        TxsInfo[_from][seqNum] = TransactionInfo(
            _chainId,
            _from,
            seqNum,
            _receiver,
            _value,
            State.GENERATED,
            data,
            "");
        return seqNum;
    }
    function updateTxState(
        address _from,
        uint64 _seqNum,
        uint _state,
        bytes memory _txHash
    ) external  {
        _onlyaccountLogic();
        if (_state == 1) {
            TxsInfo[_from][_seqNum].state = State.SENT;
        } else if (_state == 2) {
            TxsInfo[_from][_seqNum].state = State.PENDING;
        } else if (_state == 3) {
            TxsInfo[_from][_seqNum].state = State.SUCCESSFUL;
        } else if (_state == 4) {
            TxsInfo[_from][_seqNum].state = State.FAILED;
        } else {
            revert("wrong state");
        }
        TxsInfo[_from][_seqNum].l1TxHash = _txHash;
    }
    function getDIDDocument(
        string calldata _did
    ) public view returns (DID_Document memory) {
        return DID_Documents[_did];
    }
    function setDIDDocument(DID_Document calldata _didDocument) external override {
        _onlyaccountLogic();
        DID_Documents[_didDocument.id] = _didDocument;
    }
}