import { Contract } from '@ethersproject/contracts';
import chai from 'chai';
import chaiAsPromised from 'chai-as-promised';
const { expect } = chai.use(chaiAsPromised);

import { ethers, network } from 'hardhat';
import { Nftx, Nftx__factory } from '../typechain';

const INITIAL_OFFER = 2430;
const EVOLUTION_STEPS = 5;
const SEED = 1234567890;

describe('Greeter contract', () => {
  let NFTXContract: Nftx;
  let NFTXContractFactory: Nftx__factory;

  before(async () => {
    NFTXContractFactory = await ethers.getContractFactory('Nftx');
  });

  it('Should not allow deployment of contract with 0 evolution steps', () => {
    expect(NFTXContractFactory.deploy(SEED, 100, 0)).to.be.rejected;
  });

  it('Should not allow deployment of contract with incompatible initial supply and evolution steps', () => {
    expect(NFTXContractFactory.deploy(SEED, 100, 1)).to.be.rejected;
  });

  it('Should allow deployment of contract with compatible initial supply and evolution steps', async () => {
    NFTXContract = await NFTXContractFactory.deploy(
      SEED,
      INITIAL_OFFER,
      EVOLUTION_STEPS,
    );
    expect(await NFTXContract.cursors(0)).to.equal(0);
    expect(await NFTXContract.cursors(1)).to.equal(INITIAL_OFFER);
    expect(await NFTXContract.cursors(2)).to.equal(
      INITIAL_OFFER + INITIAL_OFFER / 3,
    );
  });

  it('should start with the correct amount of token', async () => {
    const result = await NFTXContract.getTokenTotalCount();
    expect(result).to.equal(INITIAL_OFFER);
  });
  it('should initialize', async () => {
    const [owner] = await ethers.getSigners();
    const a = await NFTXContract.isInitialized();
    expect(a).to.equal(true);
  });

  it('should preOrder a token', async () => {
    const [owner] = await ethers.getSigners();
    await NFTXContract.preOrderToken();
    const balance = await NFTXContract.balanceOf(owner.address);
    expect(balance).to.equal(1);
  });

  it('should activate tokens when initial offering is over', async () => {
    for (let k = 0; k < INITIAL_OFFER - 1; k++) {
      await NFTXContract.preOrderToken();
      let btm = Math.floor(Math.random() * 3);
      for (let i = 0; i < btm; i++) {
        network.provider.send('evm_mine');
      }
    }
    const result = await NFTXContract.getNft(1);
    expect(result._generation).to.equal(0);
    expect(result._genes).to.equal(855891239);
  }).timeout(60000);
});
