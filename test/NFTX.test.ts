import { Contract } from '@ethersproject/contracts';
import chai from 'chai';
import chaiAsPromised from 'chai-as-promised';
const { expect } = chai.use(chaiAsPromised);

import { ethers, network } from 'hardhat';
import {
  Contributors,
  Contributors__factory,
  GeneScience,
  GeneScience__factory,
  Nftx,
  Nftx__factory,
} from '../typechain';

const INITIAL_OFFER = 243;
const EVOLUTION_STEPS = 5;
const SEED = 1234567890;

describe('Greeter contract', () => {
  let NFTXContract: Nftx;
  let NFTXContractFactory: Nftx__factory;
  let ContributorsFactory: Contributors__factory;
  let ContributorsContract: Contributors;
  let GeneScienceContractFactory: GeneScience__factory;
  let GeneScienceContract: GeneScience;

  before(async () => {
    NFTXContractFactory = await ethers.getContractFactory('Nftx');
    ContributorsFactory = await ethers.getContractFactory('Contributors');
    ContributorsContract = await ContributorsFactory.deploy();
    GeneScienceContractFactory = await ethers.getContractFactory('GeneScience');
    GeneScienceContract = await GeneScienceContractFactory.deploy();
  });

  it('Should not allow deployment of contract with 0 evolution steps', () => {
    expect(
      NFTXContractFactory.deploy(
        SEED,
        100,
        0,
        GeneScienceContract.address,
        ContributorsContract.address,
      ),
    ).to.be.rejected;
  });

  it('Should not allow deployment of contract with incompatible initial supply and evolution steps', () => {
    expect(
      NFTXContractFactory.deploy(
        SEED,
        100,
        1,
        GeneScienceContract.address,
        ContributorsContract.address,
      ),
    ).to.be.rejected;
  });

  it('Should allow deployment of contract with compatible initial supply and evolution steps', async () => {
    NFTXContract = await NFTXContractFactory.deploy(
      SEED,
      INITIAL_OFFER,
      EVOLUTION_STEPS,
      GeneScienceContract.address,
      ContributorsContract.address,
    );
    await ContributorsContract.initialize(NFTXContract.address);
    await ContributorsContract.setDistribution(
      [(await ethers.getSigners())[0].address],
      [ethers.utils.parseEther('1')],
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
    const a = await NFTXContract.isInitialized();
    expect(a).to.equal(true);
  });

  it('should preOrder a token', async () => {
    const [owner] = await ethers.getSigners();
    const tokenPrice = await NFTXContract.getCurrentTokenPrice();
    await NFTXContract.mintGen0Nft(1, {
      value: tokenPrice,
    });
    const balance = await NFTXContract.balanceOf(owner.address);
    expect(balance).to.equal(1);
  });

  it('should not allow withdraw from non-owners', async () => {
    const [, address1] = await ethers.getSigners();
    const amount = await NFTXContract.provider.getBalance(NFTXContract.address);
    expect(NFTXContract.connect(address1).withDraw(amount)).to.be.rejected;
  });

  it('should withdraw Contract Balance', async () => {
    const [owner] = await ethers.getSigners();
    const withdrawable = await ContributorsContract.withdrawable(owner.address);
    const initialOwnerBalance = await owner.getBalance();
    const amount = await NFTXContract.provider.getBalance(NFTXContract.address);
    const tx = await NFTXContract.withDraw(withdrawable);
    const gasFee =
      tx.gasPrice &&
      (await ethers.provider.getTransactionReceipt(tx.hash)).gasUsed.mul(
        tx.gasPrice,
      );
    const newOwnerBalance = await owner.getBalance();
    expect(
      (await NFTXContract.provider.getBalance(NFTXContract.address)).toString(),
    ).to.equal('0');
    expect(newOwnerBalance.sub(initialOwnerBalance).toString()).to.equal(
      amount.sub(gasFee || 0).toString(),
    );
  });

  it('should activate tokens when initial offering is over', async () => {
    for (let k = 0; k < INITIAL_OFFER - 1; k++) {
      await NFTXContract.mintGen0Nft(1, {
        value: await NFTXContract.getCurrentTokenPrice(),
      });
      let btm = Math.floor(Math.random() * 3);
      for (let i = 0; i < btm; i++) {
        network.provider.send('evm_mine');
      }
    }
    const result = await NFTXContract.getNft(1);
    expect(result._generation).to.equal(0);
    expect(result._genes).to.equal(855891239);
  }).timeout(60000);

  it('should evolve tokens', async () => {
    const [owner] = await ethers.getSigners();
    const initialBalance = await NFTXContract.balanceOf(owner.address);
    await NFTXContract.mintEvolution(1, 2, 3);
    const newBalance = await NFTXContract.balanceOf(owner.address);
    expect(initialBalance.sub(newBalance).toNumber()).to.equal(2);
  });
});
