import { loadFixture } from "ethereum-waffle";
import { expect } from "chai";
import { ethers } from "hardhat";

async function basicFixture() {
  const [owner, user1, user2, accessPool, communityPool] =
    await ethers.getSigners();
  const user1Address = user1.address;
  const user2Address = user2.address;

  // GS Token deploy
  const GS50 = await ethers.getContractFactory("auto_pool");
  const gs50 = await GS50.deploy();
  const gs50Address = gs50.address;

  // PaymentEngine deploy
  const Payment = await ethers.getContractFactory("MasterPaymentContract");
  const payment = await Payment.deploy(
    gs50Address,
    accessPool.address,
    communityPool.address
  );
  const paymentAddress = payment.address;

  // NFT with referral deploy
  const NFT = await ethers.getContractFactory("ERC721NFT");
  const baseTokenURI = "ipfs://QmZbWNKJPAjxXuNFSEaksCJVd1M6DaKQViJBYPK2BdpDEP/";
  const nft = await NFT.deploy(
    true,
    100,
    1,
    baseTokenURI,
    1000,
    10000,
    paymentAddress,
    gs50Address
  );
  await nft.deployed();
  return { nft, owner, user1, user2, user1Address, user2Address };
}

describe("NFT created with a referral system included", () => {
  describe("adminMint", () => {
    it("should not be able to more than maxSupply", async () => {
      const { nft } = await loadFixture(basicFixture);
      await expect(nft.adminMint(100)).revertedWith("Not enough NFTs");
    });
    it("should be able to mint", async () => {
      const { nft, owner } = await loadFixture(basicFixture);
      await nft.adminMint(10);
      let tokens = await nft.tokensOfOwner(owner.address);
      console.log("Owner has tokens: ", tokens);
    });
  });
  describe("buyMint", () => {
    it("should not be able to mint before publicMint is started", async () => {
      const { nft, owner, user1 } = await loadFixture(basicFixture);
      await nft.setPublicMint(false);
      await nft.generateReferralCode(owner.address);
      const referralCode = await nft.addressToReferralCode(owner.address);

      // the referrer of the user1 is owner!
      await expect(nft.connect(user1).buyMint(50, referralCode)).revertedWith(
        "ERROR: Public mint has not started"
      );
    });
    it("should have to be changed the eth balance of only first minter when first NFT mint", async () => {
      const { nft, owner, user1 } = await loadFixture(basicFixture);
      await nft.setPublicMint(true);
      const blankhash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(""));

      // First NFT mint by Owner
      expect(
        await nft.buyMint(10, blankhash, {
          value: 10,
        })
      ).to.changeEtherBalance(owner, -10);
    });
    it("should be able to change the eth balance of the minter and referrer at the same time after first mint", async () => {
      const { nft, owner, user1 } = await loadFixture(basicFixture);
      const referralCode = await nft.addressToReferralCode(owner.address);
      console.log("referralCode", referralCode);

      // Second NFT mint by user1 with referralCode of Owner
      expect(
        await nft.connect(user1).buyMint(50, referralCode, {
          value: 50,
        })
      ).to.changeEtherBalances([user1, owner], [-50, 5]);
    });
    it("should be able to change the eth balance of the minter and referrer at the same time after first mint", async () => {
      const { nft, user1, user2 } = await loadFixture(basicFixture);
      const referralCode = await nft.addressToReferralCode(user1.address);
      console.log("referralCode", referralCode);

      // Second NFT mint by user1 with referralCode of Owner
      expect(
        await nft.connect(user2).buyMint(20, referralCode, {
          value: 20,
        })
      ).to.changeEtherBalances([user2, user1], [-20, 2]);
    });
  });
});
