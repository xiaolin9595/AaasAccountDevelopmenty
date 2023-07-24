// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "../interfaces/IEntryPoint.sol";
import "../interfaces/IAccount.sol";
import "../samples/ASNAccountLogic.sol";

contract TxState {
    address public DEPOSITOR_ACCOUNT;
    IEntryPoint private immutable _entryPoint;
    address public  accountLogic;
    address public owner;

    constructor(address _owner, IEntryPoint anEntryPoint) {
        owner = _owner;
        _entryPoint = anEntryPoint;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
     modifier onlyAccountLogic() {
        require(accountLogic == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    enum State {
        GENERATED,
        SENT,
        PENDING,
        SUCCESSFUL,
        FAILED
    }
    struct TransactionInfo {
        uint64 chainId;
        address from;
        uint64 seqNum;
        address receiver;
        uint256 amount;
        State state;
        uint256 gasLimit;
        bytes data;
    }

    //mapping(bytes32 => State) public L1txHashToState;
    event L1transferEvent(
        address indexed account,
        address indexed from,
        uint64 indexed seqNum,
        TransactionInfo txInfo
    );
    event updateTxStateSuccess(bytes indexed L1Txhash, uint state);
    function setAccountLogic (address _accountLogic) public onlyOwner {
        accountLogic = _accountLogic;
    }
    /**
     * @dev Returns the entry point.
     */
    function entryPoint() public view returns (IEntryPoint) {
        return _entryPoint;
    }

    /**
     * ensure the request comes from the known entrypoint.
     */
    function _requireFromEntryPoint() internal view virtual {
        require(
            msg.sender == address(entryPoint()),
            "account: not from EntryPoint"
        );
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
            IAccount(l2Account).updateTxState{gas: gasleft()}(
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

    function proposeTxToL1(
        uint64 _chainId,
        address senderAccount,
        address _from,
        uint64 _seqNum,
        address _receiver,
        uint256 _value,
        uint256 _gasLimit,
        bytes memory _data
    ) external onlyAccountLogic {
        TransactionInfo memory txInfo = (
            TransactionInfo(
                _chainId,
                _from,
                _seqNum,
                _receiver,
                _value,
                State.GENERATED,
                _gasLimit,
                _data
            )
        );

        emit L1transferEvent(senderAccount, _from, _seqNum, txInfo);
    }
}
