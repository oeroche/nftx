import { Contract } from "@ethersproject/contracts";
import chai from "chai";
import chaiAsPromised from "chai-as-promised";
const { expect } = chai.use(chaiAsPromised);

import { ethers, network, upgrades } from "hardhat";
import {
  GeneScience,
  GeneScience__factory,
  Nftx,
  Nftx__factory,
} from "../typechain";

const INITIAL_OFFER = 243;
const EVOLUTION_STEPS = 5;
const SEED = 1234567890;

describe("Greeter contract", () => {
  let NFTXContract: Nftx;
  let GeneScienceContract: GeneScience;
  let NFTXContractFactory: Nftx__factory;
  let GeneScienceFactory: GeneScience__factory;

  before(async () => {
    NFTXContractFactory = await ethers.getContractFactory("Nftx");
    GeneScienceFactory = await ethers.getContractFactory("GeneScience");
    GeneScienceContract = await GeneScienceFactory.deploy();
    NFTXContract = (await upgrades.deployProxy(NFTXContractFactory, [
      SEED,
      INITIAL_OFFER,
      EVOLUTION_STEPS,
      3,
    ])) as Nftx;
    NFTXContract.setGeneScience(GeneScienceContract.address);
  });

  // it("Should not allow deployment of contract with 0 evolution steps", () => {
  //   expect(NFTXContractFactory.deploy(SEED, 100, 0)).to.be.rejected;
  // });

  // it("Should not allow deployment of contract with incompatible initial supply and evolution steps", () => {
  //   expect(NFTXContractFactory.deploy(SEED, 100, 1)).to.be.rejected;
  // });

  // it("Should allow deployment of contract with compatible initial supply and evolution steps", async () => {});

  it("should start with the correct amount of token", async () => {
    const result = await NFTXContract.getTokenTotalCount();
    expect(result).to.equal(0);
  });
  // it("should initialize", async () => {
  //   const [owner] = await ethers.getSigners();
  //   const a = await NFTXContract.isInitialized();
  //   expect(a).to.equal(true);
  // });

  it("should preOrder a token", async () => {
    const [owner] = await ethers.getSigners();
    await NFTXContract.preOrderToken(1, {
      value: ethers.utils.parseEther("0.01"),
    });
    const balance = await NFTXContract.balanceOf(owner.address);
    expect(balance).to.equal(1);
  });

  it("should activate tokens when initial offering is over", async () => {
    const remaining = await NFTXContract.remainingSupply();
    for (let k = 1; remaining.gte(k); k++) {
      const value = await NFTXContract.getAuctionPrice();
      await NFTXContract.preOrderToken(1, { value });
      let btm = Math.floor(Math.random() * 3);
      for (let i = 0; i < btm; i++) {
        network.provider.send("evm_mine");
      }
    }
    console.log((await NFTXContract._blindAuctionStartingIndex()).toString());
    const result = await NFTXContract.getNft(1);
    expect(result._generation).to.equal(0);
    const dna = await GeneScienceContract.getNewDNA(
      (await NFTXContract._blindAuctionStartingIndex()).add(1).add(SEED)
    );
    expect(result._genes).to.equal(dna);
  }).timeout(60000);
});
