const {ethers,upgrades} = require("hardhat");
const hre = require("hardhat");

async function main() {
  // Deploy the Dealer contract
  const Dealer = await hre.ethers.getContractFactory("Dealer");
  // config:0x5653a926668ff75B38c815cf3Fb0Fb6b9d4CEFE6
  console.log("Deploying Dealer contract...");
  const dealer = await hre.upgrades.deployProxy(Dealer,["0xcc830E09Ce867153B8e2ac12F875D68571d4bcC8"],{initializer:"initialize"});
  await dealer.waitForDeployment();
  console.log("Dealer contract deployed to:", dealer.target);

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

// Verifying implementation: 0x73d9F978106AC8383E91407cd57bF0B276b8D472
// Successfully submitted source code for contract
// contracts/Dealer.sol:Dealer at 0x73d9F978106AC8383E91407cd57bF0B276b8D472
// for verification on the block explorer. Waiting for verification result...

// Successfully verified contract Dealer on the block explorer.
// https://sepolia.etherscan.io/address/0x73d9F978106AC8383E91407cd57bF0B276b8D472#code

// Verifying proxy: 0x51B1C28f55d2Aed036deEe294Ce105f3952321bB
// Successfully verified contract TransparentUpgradeableProxy at 0x51B1C28f55d2Aed036deEe294Ce105f3952321bB.
// Linking proxy 0x51B1C28f55d2Aed036deEe294Ce105f3952321bB with implementation
// Successfully linked proxy to implementation.
// Verifying proxy admin: 0xb8458D5143832A83A52096B464A641Eba2450be2
// Contract at 0xb8458D5143832A83A52096B464A641Eba2450be2 already verified.

// Proxy fully verified.