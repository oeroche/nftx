/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import { Provider, TransactionRequest } from "@ethersproject/providers";
import type { GeneScience, GeneScienceInterface } from "../GeneScience";

const _abi = [
  {
    inputs: [],
    stateMutability: "nonpayable",
    type: "constructor",
  },
  {
    inputs: [
      {
        internalType: "string",
        name: "seed_",
        type: "string",
      },
    ],
    name: "getNewDNA",
    outputs: [
      {
        internalType: "uint32",
        name: "",
        type: "uint32",
      },
    ],
    stateMutability: "pure",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint32",
        name: "dna1",
        type: "uint32",
      },
      {
        internalType: "uint32",
        name: "dna2",
        type: "uint32",
      },
      {
        internalType: "uint32",
        name: "dna3",
        type: "uint32",
      },
    ],
    name: "mergeDNA",
    outputs: [
      {
        internalType: "uint32",
        name: "",
        type: "uint32",
      },
    ],
    stateMutability: "pure",
    type: "function",
  },
];

const _bytecode =
  "0x608060405234801561001057600080fd5b506104d9806100206000396000f3fe608060405234801561001057600080fd5b50600436106100365760003560e01c8063067de3291461003b578063af0b63aa1461006b575b600080fd5b610055600480360381019061005091906101ba565b61009b565b6040516100629190610273565b60405180910390f35b61008560048036038101906100809190610179565b6100c9565b6040516100929190610273565b60405180910390f35b600060038284866100ac9190610300565b6100b69190610300565b6100c0919061033a565b90509392505050565b6000816040516020016100dc9190610251565b6040516020818303038152906040528051906020012060001c9050919050565b600061010f61010a846102b3565b61028e565b90508281526020810184848401111561012757600080fd5b61013284828561037b565b509392505050565b600082601f83011261014b57600080fd5b813561015b8482602086016100fc565b91505092915050565b6000813590506101738161048c565b92915050565b60006020828403121561018b57600080fd5b600082013567ffffffffffffffff8111156101a557600080fd5b6101b18482850161013a565b91505092915050565b6000806000606084860312156101cf57600080fd5b60006101dd86828701610164565b93505060206101ee86828701610164565b92505060406101ff86828701610164565b9150509250925092565b6000610214826102e4565b61021e81856102ef565b935061022e81856020860161038a565b6102378161047b565b840191505092915050565b61024b8161036b565b82525050565b6000602082019050818103600083015261026b8184610209565b905092915050565b60006020820190506102886000830184610242565b92915050565b60006102986102a9565b90506102a482826103bd565b919050565b6000604051905090565b600067ffffffffffffffff8211156102ce576102cd61044c565b5b6102d78261047b565b9050602081019050919050565b600081519050919050565b600082825260208201905092915050565b600061030b8261036b565b91506103168361036b565b92508263ffffffff0382111561032f5761032e6103ee565b5b828201905092915050565b60006103458261036b565b91506103508361036b565b9250826103605761035f61041d565b5b828204905092915050565b600063ffffffff82169050919050565b82818337600083830152505050565b60005b838110156103a857808201518184015260208101905061038d565b838111156103b7576000848401525b50505050565b6103c68261047b565b810181811067ffffffffffffffff821117156103e5576103e461044c565b5b80604052505050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601160045260246000fd5b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601260045260246000fd5b7f4e487b7100000000000000000000000000000000000000000000000000000000600052604160045260246000fd5b6000601f19601f8301169050919050565b6104958161036b565b81146104a057600080fd5b5056fea2646970667358221220fdd8f866783d4c3bf69a8c6c4ce969e79dc8793b7d9f11686aaa84d70dcf58be64736f6c63430008030033";

export class GeneScience__factory extends ContractFactory {
  constructor(signer?: Signer) {
    super(_abi, _bytecode, signer);
  }

  deploy(
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<GeneScience> {
    return super.deploy(overrides || {}) as Promise<GeneScience>;
  }
  getDeployTransaction(
    overrides?: Overrides & { from?: string | Promise<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(overrides || {});
  }
  attach(address: string): GeneScience {
    return super.attach(address) as GeneScience;
  }
  connect(signer: Signer): GeneScience__factory {
    return super.connect(signer) as GeneScience__factory;
  }
  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): GeneScienceInterface {
    return new utils.Interface(_abi) as GeneScienceInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): GeneScience {
    return new Contract(address, _abi, signerOrProvider) as GeneScience;
  }
}
