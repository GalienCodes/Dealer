// const {ethers,upgrades} = require("hardhat");
// const hre = require("hardhat");


// async function main() {
//   // Deploy the L1Config contract
//   const L1Config = await hre.ethers.getContractFactory("L1Config");
//   // _sequencerAgentTemplate:"0x7D0537E6e1361B021d85D4513A33E3d832544A45"
//   // _metis:"0x7f49160EB9BB068101d445fe77E17ecDb37D0B47"
//   // _lockingPool:"0x7591940125cC0344a65D60319d1ADcD463B2D4c3"
//   // _l1Bridge:"0x9848dE505e6Aa301cEecfCf23A0a150140fc996e"
//   // _l2Minter:" 0xaF5f00Eb9418fa24a28B8CbF568C259D3678201f"
//   // _l2ChainId:"59902"
//   // _l2Gas:"30,000,000"

//   console.log("Deploying L1Config contract...");
//   const l1Config = await hre.upgrades.deployProxy(
//     L1Config,
//     [
//       "0x7D0537E6e1361B021d85D4513A33E3d832544A45",
//       "0x7f49160EB9BB068101d445fe77E17ecDb37D0B47",
//       "0x7591940125cC0344a65D60319d1ADcD463B2D4c3",
//       "0x9848dE505e6Aa301cEecfCf23A0a150140fc996e",
//       "0xaF5f00Eb9418fa24a28B8CbF568C259D3678201f",
//       59902,
//       30000000,
//     ],
//     { initializer: "initialize" }
//   );
//   await l1Config.waitForDeployment();
//   console.log("L1Config contract deployed to:", l1Config.target);
// }

// main()
//   .then(() => process.exit(0))
//   .catch(error => {
//     console.error(error);
//     process.exit(1);
//   });
 
// // Verifying implementation: 0x9E7EFc0297e7F7550bF49289bF058581F456eE5E
// // Successfully submitted source code for contract
// // contracts/L1Config.sol:L1Config at 0x9E7EFc0297e7F7550bF49289bF058581F456eE5E
// // for verification on the block explorer. Waiting for verification result...

// // Successfully verified contract L1Config on the block explorer.
// // https://sepolia.etherscan.io/address/0x9E7EFc0297e7F7550bF49289bF058581F456eE5E#code

// // Verifying proxy: 0x5653a926668ff75B38c815cf3Fb0Fb6b9d4CEFE6
// // Successfully verified contract TransparentUpgradeableProxy at 0x5653a926668ff75B38c815cf3Fb0Fb6b9d4CEFE6.
// // Linking proxy 0x5653a926668ff75B38c815cf3Fb0Fb6b9d4CEFE6 with implementation
// // Successfully linked proxy to implementation.
// // Verifying proxy admin: 0xc9962326E5e503C254BDb86415d92fFC9514A728
// // Contract at 0xc9962326E5e503C254BDb86415d92fFC9514A728 already verified.

// // Proxy fully verified.


// // ================New==========================
// // Verifying implementation: 0x9E7EFc0297e7F7550bF49289bF058581F456eE5E
// // The contract 0x9E7EFc0297e7F7550bF49289bF058581F456eE5E has already been verified on Etherscan.
// // https://sepolia.etherscan.io/address/0x9E7EFc0297e7F7550bF49289bF058581F456eE5E#code
// // Verifying proxy: 0xcc830E09Ce867153B8e2ac12F875D68571d4bcC8
// // Successfully verified contract TransparentUpgradeableProxy at 0xcc830E09Ce867153B8e2ac12F875D68571d4bcC8.
// // Linking proxy 0xcc830E09Ce867153B8e2ac12F875D68571d4bcC8 with implementation
// // Successfully linked proxy to implementation.
// // Verifying proxy admin: 0x56D81b37c58fdAb75A9593c49Eb65885c3AC1632
// // Contract at 0x56D81b37c58fdAb75A9593c49Eb65885c3AC1632 already verified.

// // Proxy fully verified.
// // Done in 19.65s.