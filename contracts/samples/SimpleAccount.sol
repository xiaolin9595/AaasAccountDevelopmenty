// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

import "../core/BaseAccount.sol";
import "./callback/TokenCallbackHandler.sol";
import "../interfaces/UserOperation.sol";
import "../core/TxState.sol";
import "../interfaces/DIDLibrary.sol";
/**
  * minimal account.
  *  this is sample minimal account.
  *  has execute, eth handling methods
  *  has a single signer that can send requests through the entryPoint.
  */
contract SimpleAccount is BaseAccount, TokenCallbackHandler, UUPSUpgradeable, Initializable {
    using ECDSA for bytes32;
    using UserOperationLib for UserOperation;
    using DIDLib for DID_Document;
    bytes public owner;

    IEntryPoint private immutable _entryPoint;
    TxState public immutable _txState;
   
    event SimpleAccountInitialized(IEntryPoint indexed entryPoint, bytes indexed owner);
    enum State {GENERATED, SENT, PENDING, SUCCESSFUL, FAILED}
    //交易的相关信息
    struct TransactionInfo{
        uint64 chainId; //L1链ID
        address from;    //在L1交易发起地址
        uint64 seqNum;   //from账户下交易序号
        address receiver; //L1交易接收地址
        uint256 amount;   //交易的金额大小
        State   state;   //交易的状态
        bytes   data;    //交易携带的合约调用数据 
        bytes   l1TxHash; //L1交易的哈希
    }
    //交易数对应的交易信息
    mapping(address=>mapping(uint64=>TransactionInfo)) public TxsInfo; 
    //L1地址对应的seqNum
    mapping (address=>uint64) public SequenceNumber;
    //DID对应的DID文档
    mapping (string=>DID_Document) public DID_Documents;
    modifier onlyItself() {
        _onlyItself();
        _;
    }

    /// @inheritdoc BaseAccount
    function entryPoint() public view virtual override returns (IEntryPoint) {
        return _entryPoint;
    }


    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    constructor(IEntryPoint anEntryPoint,TxState anTxState) {
        _entryPoint = anEntryPoint;
        _txState = anTxState;
        _disableInitializers();
    }

    function _onlyItself() internal view {
        //directly from EOA owner, or through the account itself (which gets redirected through execute())
        require( msg.sender == address(this), "only contact itself can call");
    }
    function _onlyTxState() internal view {
        //directly from EOA owner, or through the account itself (which gets redirected through execute())
        require( msg.sender == address(_txState), "only contact TxState can call");
    }
    /**
     * execute a transaction (called directly from owner, or by entryPoint)
     */
    function execute(address dest, uint256 value, bytes calldata func) external {
        _requireFromEntryPoint();
        _call(dest, value, func);
    }

    /**
     * execute a sequence of transactions
     */
    function executeBatch(address[] calldata dest, bytes[] calldata func) external {
        _requireFromEntryPoint();
        require(dest.length == func.length, "wrong array lengths");
        for (uint256 i = 0; i < dest.length; i++) {
            _call(dest[i], 0, func[i]);
        }
    }

    /**
     * @dev The _entryPoint member is immutable, to reduce gas consumption.  To upgrade EntryPoint,
     * a new implementation of SimpleAccount must be deployed with the new EntryPoint address, then upgrading
      * the implementation by calling `upgradeTo()`
     */
    function initialize(bytes calldata  anOwner) public virtual initializer {
        _initialize(anOwner);
    }

    function _initialize(bytes calldata anOwner) internal virtual {
        owner = anOwner;
        emit SimpleAccountInitialized(_entryPoint, owner);
    }

    // Require the function call went through EntryPoint or owner
    // function _requireFromEntryPoint() internal view {
    //     require(msg.sender == address(entryPoint()) , "account: not  EntryPoint");
    // }

    /// implement template method of BaseAccount
     function _validateSignature(UserOperation calldata userOp, bytes32 userOpHash)
      internal override virtual returns (uint256 validationData) {
    
        require(userOpHash==keccak256(abi.encode(userOp.hash(),address(entryPoint()), block.chainid)),"userOp verify failed");
        if (owner.length != userOp.fidoPubKey.length)  return SIG_VALIDATION_FAILED;
        for(uint i = 0; i < owner.length; i ++) {
            if(owner[i] != userOp.fidoPubKey[i]) return SIG_VALIDATION_FAILED;
        }
        return 0;
      }

    function _call(address target, uint256 value, bytes memory data) internal {
        (bool success, bytes memory result) = target.call{value : value}(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    /**
     * check current account deposit in the entryPoint
     */
    function getDeposit() public view returns (uint256) {
        return entryPoint().balanceOf(address(this));
    }

    /**
     * deposit more funds for this account in the entryPoint
     */
    function addDeposit() public payable {
        entryPoint().depositTo{value : msg.value}(address(this));
    }

    /**
     * withdraw value from the account's deposit
     * @param withdrawAddress target to send to
     * @param amount to withdraw
     */
    function withdrawDepositTo(address payable withdrawAddress, uint256 amount) public onlyItself{
        entryPoint().withdrawTo(withdrawAddress, amount);
    }

    function _authorizeUpgrade(address newImplementation) internal view override {
        (newImplementation);
        _onlyItself();
    }
    function  addL1txInfo(
        uint64 _chainId,
        address _from,
        address _receiver,
        uint256 _value,
        bytes memory data
    )external returns(uint64){
        //只有entryPoint可以调用
        _requireFromEntryPoint();
        //付款的L1账户所对应的seqNum递增
        SequenceNumber[_from]++;
        uint64 seqNum =SequenceNumber[_from];
       TxsInfo[_from][seqNum] = TransactionInfo(_chainId,_from,seqNum,_receiver,_value,State.GENERATED,data,'0x23010919');//0x23010919为wait的意思
       return seqNum;
    }
    //更新交易状态
    function updateTxState(address _from,uint64 _seqNum,uint _state)external{
        _onlyTxState();
      if (_state==1){
        TxsInfo[_from][_seqNum].state = State.SENT;
        }else if (_state==2){
             TxsInfo[_from][_seqNum].state = State.PENDING;
        }else if(_state==3){
            TxsInfo[_from][_seqNum].state = State.SUCCESSFUL;
        }else if(_state==4){
           TxsInfo[_from][_seqNum].state = State.FAILED;
        }else{
            revert("wrong state");
        }
    
    }
    //获取L1Txhash
    function getL1Txhash(address _from,uint64 _seqNum)public  returns(bytes memory){
           TxsInfo[_from][_seqNum].l1TxHash= _txState.getL1Txhash(_from,_seqNum);
           return TxsInfo[_from][_seqNum].l1TxHash;
    }
    //修改DID文档
    function modifyDIDDocument(DID_Document calldata _didDocument)public{
        //只有entryPoint可以调用
        //_requireFromEntryPoint();
       DID_Documents[_didDocument.id]= _didDocument;
    }
    //返回DID文档
    function getDIDDocument(string calldata _did)view public returns(DID_Document memory){
        
       return DID_Documents[_did];
    }

}