import './aa.init'
import { BigNumber, Event, Wallet } from 'ethers'
import { expect } from 'chai'
import {
  AaasCreationPaymaster,
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
import { DefaultsForUserOp, fillAndSign, getUserOpHash, fillUserOpDefaults, fillUserOp } from './UserOp'
import { UserOperation } from './UserOperation'
import { PopulatedTransaction, Transaction } from 'ethers/lib/ethers'
import { ethers } from 'hardhat'
import { arrayify, defaultAbiCoder, hexConcat, hexZeroPad, parseEther, TransactionTypes } from 'ethers/lib/utils'
import { debugTransaction } from './debugTx'
import { BytesLike } from '@ethersproject/bytes'
import { toChecksumAddress } from 'ethereumjs-util'
import { signer } from '@thehubbleproject/bls'
import { bytes32 } from './solidityTypes'
import { Transform } from 'stream'
import { DID_DocumentStructOutput, PublicKeyStructOutput, PublicKeyStruct } from '../typechain/contracts/samples/SimpleAccount';
import { DefaultsForDID_Document, DID_Document } from './DID_Document'
describe('EntryPoint', function () {
  let entryPoint: EntryPoint
  let simpleAccountFactory: SimpleAccountFactory
  let aaasCreationPaymaster: AaasCreationPaymaster
  let accountOwner: Wallet
  const ethersSigner = ethers.provider.getSigner()




  describe('#generate account address and initcode', () => {
    it('generate account address and initcode', async () => {

      const [address1] = await ethers.getSigners();

      console.log(" address1=", address1.address)


      let entryPoint_factory = await ethers.getContractFactory("EntryPoint")
      entryPoint = await entryPoint_factory.attach('0xc2ccD892A088dd40E22A668fA2d78a95B2E1F1ae')
      

      console.log("entrypoint address=", entryPoint.address)




      let txStateaddress = await entryPoint.txState()

      console.log("txState address=", txStateaddress)
      let txState_factory = await ethers.getContractFactory("TxState")
      let txState = await txState_factory.attach(txStateaddress)
      
    
     
 
      let simpleAccount_factor = await ethers.getContractFactory("SimpleAccount")
      let Account = await simpleAccount_factor.attach('0x5a42091e66447aA51055c6D2B247701C3AfaAa9A');
  
      //txState.setL1TxState('0x1234567890','0x4eF19d53265085e5211d407e8e8a7713ecbA089b', Account.address, 1,1)
      let hash=await Account.getL1Txhash(Account.address,1)
      console.log("hash=",hash)
    }
    )



  })
})