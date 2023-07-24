import './aa.init'
import { BigNumber, Event, Wallet } from 'ethers'
import { expect } from 'chai'
import {
  AaasCreationPaymaster,
  EntryPoint,
  ASNAccount,
  ASNAccount__factory,
  ASNAccountLogic,
  ASNAccountLogic__factory,
  ASNAccountFactory,
  ASNAccountFactory__factory,
  ASNAccountLogicFactory,
  ASNAccountLogicFactory__factory,
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
  let ASNAccountFactory: AccountFactory
  let aaasCreationPaymaster: AaasCreationPaymaster
  let accountOwner: Wallet
  const ethersSigner = ethers.provider.getSigner()




  describe('#generate account address and initcode', () => {
    it('generate account address and initcode', async () => {

      //let address2=await ethersSigner.getAddress();
      const [address1] = await ethers.getSigners();
      // let banlance=await ethers.provider.getBalance(address1);
      // let banlance2=await ethers.provider.getBalance(address2);
      let banlance = await address1.getBalance();
      // let banlance2=await address2.getBalance();
      console.log(" address1=", address1.address)
      console.log(" banlance=", banlance)
      // console.log(" address2=",address2.address)
      // let banlance2=await address2.getBalance();
      //console.log(" banlance2=",banlance2)
      //accountOwner = createAccountOwner();
      //console.log("woner address=",accountOwner.address)
      // let block=await ethers.provider.getBlock("latest").then(t=>t.gasLimit)
      //console.log("gasLimit=",block.)
      let entryPoint_factory = await ethers.getContractFactory("EntryPoint")
      entryPoint = await entryPoint_factory.deploy({ gasPrice: 875000000, gasLimit: 1e07 });

      //entryPoint=await entryPoint_factory.attach("0xba77eaa474c1b2c3ba1a754c6a765796a13ac3d8")
      //let balance=await entryPoint.balanceOf("0x7c6BC3c288065CddDCa1877ea66a6E923E8356D3")
      console.log("entrypoint address=", entryPoint.address)

      //获取account list的地址
      let address_list = await entryPoint.accountList()
      console.log("accountList address=", address_list)
      //创建Paymaster合约
      let aaasCreationPaymaster_factory = await ethers.getContractFactory("AaasCreationPaymaster")
      aaasCreationPaymaster = await aaasCreationPaymaster_factory.deploy(entryPoint.address)
      console.log("aaasCreationPaymaster address=", aaasCreationPaymaster.address)
      //console.log("entrypoint banlance=",balance)
      //创建Txstate合约
      let txStateaddress = await entryPoint.txState()

      console.log("txState address=", txStateaddress)
      let txState_factory = await ethers.getContractFactory("TxState")
      let txState = await txState_factory.attach(txStateaddress)

      let simpleAccountFactory_factory = await ethers.getContractFactory("SimpleAccountFactory")
      simpleAccountFactory = await simpleAccountFactory_factory.deploy(entryPoint.address, txStateaddress);
      //simpleAccountFactory=await simpleAccountFactory_factory.attach("0x6a61a1e3C1c329d01F909e7767760473D65C7170")

      const salt = 40
      console.log("simpleAccountFactory=", simpleAccountFactory.address)
      const fidoPubKey1: BytesLike = "0xa50102032620012158207b71e94311177f954739ed075bd867d35bb59ab562c4f2fd61c48cef861e77c1225820eff2a13e424510fb5d4ae30dee1531d7837d6e3452139ac9056789a70b07b325a50102032620012158207b71e94311177f954739ed075bd867d35bb59ab562c4f2fd61c48cef861e77c1225820eff2a13e424510fb5d4ae30dee1531d7837d6e3452139ac9056789a70b07b325";
      let preAddrandfidokey = await simpleAccountFactory.getAddress(fidoPubKey1, salt)
      let preAddr = preAddrandfidokey[0]
      let fidokeyhash = preAddrandfidokey[1]
      console.log("simpleaccount address=", preAddr)
      console.log("FidoPubKey:%s", fidokeyhash)

      let rep = await aaasCreationPaymaster.deposit({ value: ethers.utils.parseEther("5.0"), gasLimit: 1e7 }).then(async t => await t.wait())
      let banlanceofpaymaster = await ethers.provider.getBalance(aaasCreationPaymaster.address);
      let depositofpaymaster = await aaasCreationPaymaster.getDeposit()
      console.log("banlanceofpaymaster =", banlanceofpaymaster)
      console.log("depositofpaymaster=", depositofpaymaster)

      let deposit = await aaasCreationPaymaster.getDeposit()
      console.log("deposit=", deposit)
      let initCode: BytesLike
      initCode = getAccountInitCode(fidoPubKey1, simpleAccountFactory, salt)

      console.log("initCode:", initCode)
      let MOCK_VALID_AFTER = await ethers.provider.getBlock('latest').then(t => t.timestamp)
      console.log("MOCK_VALID_AFTER=", MOCK_VALID_AFTER)
      let MOCK_VALID_UNTIL = MOCK_VALID_AFTER + 10000;
      const paymasterAndData = hexConcat([aaasCreationPaymaster.address, defaultAbiCoder.encode(['uint48', 'uint48'], [MOCK_VALID_UNTIL, MOCK_VALID_AFTER])])
      const userOp = await fillAndSign({
        sender: preAddr,
        initCode: initCode,
        fidoPubKey: fidoPubKey1,
        paymasterAndData: paymasterAndData,

      }, ethersSigner, entryPoint)
      console.log("userOp:", userOp)

      const recp = await entryPoint.handleOps([userOp], address1.address, {
        maxFeePerGas: 1e9,
        gasLimit: 1e7
      }).then(async t => await t.wait())
      console.log('rcpt.gasUsed=', recp.gasUsed.toString())
      let simpleAccount_factor = await ethers.getContractFactory("SimpleAccount")
      let Account = await simpleAccount_factor.attach(preAddr);
      //const recp1 = await Account.modifyDIDDocument(DefaultsForDID_Document).then(async t => await t.wait())
      //console.log('rcpt.gasUsed=', recp1.gasUsed.toString())
      // let diddocument:DID_Document=await Account.getDIDDocument(DefaultsForDID_Document.id);
      // console.log("diddocument=",diddocument)
      // let banlance2=await ethers.provider.getBalance(preAddr);
      // console.log(" sender balance=",banlance2)
      // let trans = await address1.populateTransaction({
      //   to: Account.address,
      //   value: parseEther('0.003'),
      //   gasLimit: 1e7,
      // });

      //let rec = await address1.sendTransaction(trans)
      const txdata = hexConcat([defaultAbiCoder.encode(['uint64', 'address', 'address', 'uint256', 'uint256','bytes'], [1, Account.address, Account.address, ethers.utils.parseEther("0.1"), 84000000,'0x1234567890'])])
      const userOp1 = await fillAndSign({
        sender: preAddr,
        l1TxData: txdata,
        fidoPubKey: fidoPubKey1,
        paymasterAndData: paymasterAndData,
      }, ethersSigner, entryPoint)
      console.log("userOp:", userOp1)

      const recp2 = await entryPoint.handleOps([userOp1], address1.address, {
        maxFeePerGas: 1e9,
        gasLimit: 1e7
      }).then(async t => await t.wait())
      console.log('rcpt.event=', recp2.events)
      //写入哈希值
      await txState.setL1TxState('0x1234567890', preAddr,preAddr, 1, 1)

    }
    )



  })
})