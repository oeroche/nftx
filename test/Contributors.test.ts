import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import chai from 'chai';
import chaiAsPromised from 'chai-as-promised';
import { cp } from 'fs';
const { expect } = chai.use(chaiAsPromised);
import { ethers } from 'hardhat';
import { Contributors, Contributors__factory } from '../typechain';

describe('Contributors', () => {
  let ContributorsFactory: Contributors__factory;
  let ContributorsContract: Contributors;
  let owner: SignerWithAddress;
  let userB: SignerWithAddress;
  let userC: SignerWithAddress;
  let userD: SignerWithAddress;
  let unauthorizedUser: SignerWithAddress;

  before(async () => {
    ContributorsFactory = await ethers.getContractFactory('Contributors');
    ContributorsContract = await ContributorsFactory.deploy();
    [owner, userB, userC, unauthorizedUser, userD] = await ethers.getSigners();
    await ContributorsContract.initialize(owner.address);
  });

  it('should not allow second initialization', () => {
    expect(ContributorsContract.initialize(owner.address)).to.be.rejected;
  });

  it('should record distribution', async () => {
    const contributors = [owner.address, userB.address, userC.address];
    const distribution = [
      ethers.utils.parseEther('0.5'),
      ethers.utils.parseEther('0.3'),
      ethers.utils.parseEther('0.2'),
    ];
    await ContributorsContract.setDistribution(contributors, distribution);
    expect(await ContributorsContract.distribution(owner.address)).to.equal(
      ethers.utils.parseEther('0.5'),
    );
  });

  it('should distribute payment', async () => {
    await ContributorsContract.distributePayment(ethers.utils.parseEther('1'));
    expect(await ContributorsContract.withdrawable(owner.address)).to.equal(
      ethers.utils.parseEther('0.5'),
    );
    expect(await ContributorsContract.withdrawable(userB.address)).to.equal(
      ethers.utils.parseEther('0.3'),
    );
    expect(await ContributorsContract.withdrawable(userC.address)).to.equal(
      ethers.utils.parseEther('0.2'),
    );
  });

  it('should not allow withdraw over contributor balance', async () => {
    await expect(
      ContributorsContract.recordWithdraw(
        owner.address,
        ethers.utils.parseEther('0.6'),
      ),
    ).to.be.rejected;
  });

  it('should  allow withdraw within contributor balance', async () => {
    await ContributorsContract.recordWithdraw(
      owner.address,
      ethers.utils.parseEther('0.5'),
    );
    expect(await ContributorsContract.withdrawable(owner.address)).to.equal(
      ethers.utils.parseEther('0'),
    );
  });

  it('should  not have touched other contributors balance', async () => {
    expect(await ContributorsContract.withdrawable(owner.address)).to.equal(
      ethers.utils.parseEther('0'),
    );
    expect(await ContributorsContract.withdrawable(userB.address)).to.equal(
      ethers.utils.parseEther('0.3'),
    );
    expect(await ContributorsContract.withdrawable(userC.address)).to.equal(
      ethers.utils.parseEther('0.2'),
    );
  });

  it('should keep balance history while distributing payement', async () => {
    await ContributorsContract.distributePayment('1000000000000000000');
    expect(
      (await ContributorsContract.withdrawable(owner.address)).toString(),
    ).to.equal(ethers.utils.parseEther('0.5'));
    expect(
      (await ContributorsContract.withdrawable(userB.address)).toString(),
    ).to.equal(ethers.utils.parseEther('0.6'));
    expect(
      (await ContributorsContract.withdrawable(userC.address)).toString(),
    ).to.equal(ethers.utils.parseEther('0.4'));
  });

  it('should not allow user with no withdrawable to withdraw', async () => {
    await expect(
      ContributorsContract.recordWithdraw(unauthorizedUser.address, '1'),
    ).to.be.rejected;
  });

  it('should reset distribution when setting a new one', async () => {
    const contributors = [owner.address, userB.address, userD.address];
    const distribution = [
      ethers.utils.parseEther('0.5'),
      ethers.utils.parseEther('0.3'),
      ethers.utils.parseEther('0.2'),
    ];
    await ContributorsContract.setDistribution(contributors, distribution);
    expect(await ContributorsContract.distribution(userC.address)).to.equal(
      ethers.utils.parseEther('0'),
    );
  });

  it('should let user withdraw even without distribution if he has withdrawable', async () => {
    const withdrawable = await ContributorsContract.withdrawable(userC.address);
    await ContributorsContract.recordWithdraw(
      userC.address,
      ethers.utils.parseEther('0.1'),
    );
    expect(await ContributorsContract.withdrawable(userC.address)).to.equal(
      withdrawable.sub(ethers.utils.parseEther('0.1')),
    );
  });
});
