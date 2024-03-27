const {ethers,upgrades} = require("hardhat");
const hre = require("hardhat");

async function main() {
  // Deploy the SequencerAgent contract
  console.log("Deploying SequencerAgent contract")
  const SequencerAgent = await hre.ethers.getContractFactory("SequencerAgent");
  const sequencerAgent = await hre.upgrades.deployProxy(SequencerAgent,[
    "0xBdb7fDbc1211F9eF09Aa9c006ebD389c59ffdBF9",
    "0x7f49160EB9BB068101d445fe77E17ecDb37D0B47"
  ],{initializer:"initialize"});
  await sequencerAgent.waitForDeployment();
  console.log("SequencerAgent contract deployed to:", sequencerAgent.target);
}
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

// Verifying implementation: 0xca37B5408AA564402b554bd8Fd25CFc117239529
// Successfully submitted source code for contract
// contracts/SequencerAgent.sol:SequencerAgent at 0xca37B5408AA564402b554bd8Fd25CFc117239529
// for verification on the block explorer. Waiting for verification result...

// Successfully verified contract SequencerAgent on the block explorer.
// https://sepolia.etherscan.io/address/0xca37B5408AA564402b554bd8Fd25CFc117239529#code

// Verifying proxy: 0x7D0537E6e1361B021d85D4513A33E3d832544A45
// Successfully verified contract TransparentUpgradeableProxy at 0x7D0537E6e1361B021d85D4513A33E3d832544A45.
// Linking proxy 0x7D0537E6e1361B021d85D4513A33E3d832544A45 with implementation
// Successfully linked proxy to implementation.
// Verifying proxy admin: 0x8c3878d43AE4217cDF3270fADf38c14C66fDdd11
// Contract at 0x8c3878d43AE4217cDF3270fADf38c14C66fDdd11 already verified.

// Proxy fully verified.