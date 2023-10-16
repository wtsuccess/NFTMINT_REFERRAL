import { ethers } from "hardhat";

async function main() {
  const NFTReferal = await ethers.getContractFactory("NFTReferal");
  const baseTokenURI = "";
  const paymentEngineAdd = "";
  const GS50Address = "";
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
