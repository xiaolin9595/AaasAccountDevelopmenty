//本地Aaas交易测试
import './aa.init'
import { BigNumber, Event, Wallet } from 'ethers'
import { expect } from 'chai'
import {
  EntryPoint,
  SimpleAccount,
  SimpleAccountFactory,
  
  TestCounter,
  TestCounter__factory,
  TestExpirePaymaster,
  TestExpirePaymaster__factory,
 
  TestPaymasterAcceptAll,
  TestPaymasterAcceptAll__factory,
  
  
  TestSignatureAggregator,
  TestSignatureAggregator__factory,
 
} from '../typechain'
import {
  AddressZero,
  createAccountOwner,
  fund,
  checkForGeth,
  rethrow,
  tostr,
  getAccountInitCode,
  calcGasUsage,
  checkForBannedOps,
  ONE_ETH,
  TWO_ETH,
  deployEntryPoint,
  getBalance,
  createAddress,
  getAccountAddress,
 
  HashZero,
  simulationResultCatch,
  createAccount,
  getAggregatedAccountInitCode,
  simulationResultWithAggregationCatch
} from './testutils'
import { DefaultsForUserOp, fillAndSign, getUserOpHash,fillUserOpDefaults, fillUserOp } from './UserOp'
import { UserOperation } from './UserOperation'
import { DefaultsForDID_Document } from './DID_Document'
import { PopulatedTransaction, Transaction } from 'ethers/lib/ethers'
import { ethers } from 'hardhat'
import { arrayify, defaultAbiCoder, hexConcat, hexZeroPad, parseEther, TransactionTypes } from 'ethers/lib/utils'
import { debugTransaction } from './debugTx'
import { BytesLike } from '@ethersproject/bytes'
import { toChecksumAddress } from 'ethereumjs-util'
import { signer } from '@thehubbleproject/bls'
import { bytes32 } from './solidityTypes'
import { Transform } from 'stream'
import { DID_DocumentStructOutput,PublicKeyStructOutput,PublicKeyStruct } from '../typechain/contracts/samples/SimpleAccount';
import { Console } from 'console'
describe('EntryPoint', function () {
    let entryPoint: EntryPoint
    let Account: SimpleAccount
  
    let accountOwner: Wallet
    const ethersSigner = ethers.provider.getSigner()

 
   
describe('#generate account address and initcode', () => {
     it('generate account address and initcode', async () => {
       
      //let address2=await ethersSigner.getAddress();
      const [address1,] = await ethers.getSigners();
      // let banlance=await ethers.provider.getBalance(address1);
      // let banlance2=await ethers.provider.getBalance(address2);
      let banlance=await address1.getBalance();
     // let banlance2=await address2.getBalance();
      console.log(" address1=",address1.address)
      console.log(" banlance=",banlance)
     // console.log(" address2=",address2.address)
      // let banlance2=await address2.getBalance();
      // console.log(" banlance2=",banlance2)
     //实例化入口点合约
      let entryPoint_factory= await ethers.getContractFactory("EntryPoint")
      entryPoint=await entryPoint_factory.attach('0x9963d1862D0B1bE3113C96AD5FFa877D844855A4');
      
      //let balance=await entryPoint.balanceOf("0x7c6BC3c288065CddDCa1877ea66a6E923E8356D3")
      console.log("entrypoint address=",entryPoint.address)
      
     //实例化SimpleAccount合约
      let simpleAccount_factor=await ethers.getContractFactory("SimpleAccount")
      Account=await simpleAccount_factor.attach('0x17b65DD1A26a06B83D484B6afF99e3bF66601521');
      console.log("Account address=",Account.address)





      
      await Account.modifyDIDDocument(DefaultsForDID_Document);
      let diddocument=await Account.getDIDDocument(DefaultsForDID_Document.id);
      console.log("diddocument=",diddocument)
      // let trans= await address1.populateTransaction({
      //   to: Account.address ,
      //   value: parseEther('0.003'),
      //   gasLimit: 1e7,
      // });

      //let rec=await address1.sendTransaction(trans)
      let FidoPubKey1='0xa50102032620012158207b71e94311177f954739ed075bd867d35bb59ab562c4f2fd61c48cef861e77c1225820eff2a13e424510fb5d4ae30dee1531d7837d6e3452139ac9056789a70b07b325'
     //生成userop的calldata
      const callData1 = Account.interface.encodeFunctionData('modifyDIDDocument',DefaultsForDID_Document ) 
      const userOp = await fillAndSign({
        sender: Account.address,
        callData: callData1,
        fidoPubKey:FidoPubKey1,
      }, ethersSigner, entryPoint)
      console.log("userOp:",userOp)
      
      const recp = await entryPoint.handleOps([userOp], address1.address, {
        maxFeePerGas: 1e9,
        gasLimit: 1e7
      }).then(async t => await t.wait())
      console.log('rcpt.gasUsed=', recp.gasUsed.toString())
      let seqNum=await Account.SequenceNumber(address1.address)
      console.log("seqNum=",seqNum)
      let txInfo = await Account.TxsInfo(address1.address,seqNum)
      console.log("txInfo=",txInfo)
   
      }
      )
    
     

})
})