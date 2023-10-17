import { ethers } from "hardhat";

async function main() {
  const NFTReferal = await ethers.getContractFactory("ERC721NFT");
  const baseTokenURI = "ipfs/QmZbWNKJPAjxXuNFSEaksCJVd1M6DaKQViJBYPK2BdpDEP/";
  const paymentEngineAdd = "0xf93E68b07f8F0fe9344Cdd2913BD84Fd757ec9f3";
  const GS50Address = "0xC862066F0D8076976A9CB1084839179dd5334AD0";
  const nftReferal = await NFTReferal.deploy(
    true,
    100,
    ethers.utils.parseEther("0.1"),
    baseTokenURI,
    1000,
    10000,
    paymentEngineAdd,
    GS50Address
  );
  await nftReferal.deployed();
  console.log("NFTReferal address", nftReferal.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
