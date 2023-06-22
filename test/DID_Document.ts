import * as typ from './solidityTypes'
import { DID_DocumentStruct,PublicKeyStructOutput, } from '../typechain/contracts/samples/SimpleAccount';
import { Type } from 'typescript';
export interface DID_Document {

    context: string;
    id: string;
    version :string;
    timeCreated :string;
    timeUpdated :string;
    authenticationPublicKey: PublicKey ;
    recoveryPublicKey : PublicKey;
    service : Service;
    proof : Proof;

}


interface PublicKey{
 id:string;
 algriothmType :string;
 publicKeyHex:typ.bytes;
}
interface Service{
id:string;
serviceType:string;
serviceEndpoint:string;
}

interface Proof{
proofType:string;
creator:string;
signatureValue :string;
}

export const DefaultsForDID_Document: DID_Document = {
    context: 'SmartContractAddress',
    id: 'did:cedu:szu',
    version :'1',
    timeCreated :'2023/05/06',
    timeUpdated :'await',
    authenticationPublicKey: {
        id: 'id:cedu:szu#key-1',
        algriothmType :'FIDO',
        publicKeyHex :'0xa50102032620012158207b71e94311177f954739ed075bd867d35bb59ab562c4f2fd61c48cef861e77c1225820eff2a13e424510fb5d4ae30dee1531d7837d6e3452139ac9056789a70b07b325',
    },
    recoveryPublicKey : {
        id: 'id:cedu:szu#key-2',
        algriothmType :'Secp256k1',
        publicKeyHex :'0xdF08a214A807640Dfc9DA47f2f83591Eed40E3c1',
    },
    service : {
        id: 'did:cedu:szu#resolver',
        serviceType :'DIDResolve',
        serviceEndpoint :'https://did.cn.edu.com',
    },
    proof : {
        proofType :'Secp256k1',
        creator :'did:cn:edu#keys-1',
        signatureValue :'QNB13Y7Q9',
    },
}
