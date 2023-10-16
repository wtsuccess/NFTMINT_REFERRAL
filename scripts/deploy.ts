import { ethers } from "hardhat";

async function main() {
  const NFTReferal = await ethers.getContractFactory("NFTReferal");
  const baseTokenURI = "ipfs://QmZbWNKJPAjxXuNFSEaksCJVd1M6DaKQViJBYPK2BdpDEP/";
  const nftReferal = await NFTReferal.deploy(true, 100, 500, 0.1, baseTokenURI);
  await nftReferal.deployed();
  console.log("NFTReferal address", nftReferal.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
