
const hre = require("hardhat");

async function main() {
  const BaseURI =
    "https://gateway.pinata.cloud/ipfs/QmcuydTDSpqFUqz3SsgtJJEpoH8pBBjbiT1ySu6rTLTJto/";
  const NFT = await hre.ethers.getContractFactory("CellarCoinNFT");
  const nft = await NFT.deploy("Enotecum", "ENT", BaseURI, 100000);

  await nft.deployed();

  console.log("NFT deployed to:", nft.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
