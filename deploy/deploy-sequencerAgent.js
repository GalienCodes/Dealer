const { verify } = require("../utils/verify");

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();

  const arguments = [
    "0x972C84B2d8a4678e4ee08DE19a027279847C6451",
    "0x7591940125cC0344a65D60319d1ADcD463B2D4c3",
    "0x390A6fE63385522E87e248BC5200f7d3a02F994b",
    "0x7f49160EB9BB068101d445fe77E17ecDb37D0B47",
  ];

  const sequencerAgent = await deploy("SequencerAgent", {
    from: deployer,
    proxy: {
      proxyContract: "OpenZeppelinTransparentProxy",
      execute: {
        init: {
          methodName: "initialize",
          args: arguments,
        },
      },
    },
    waitConfirmations: 1,
  });

  console.log("========Deploying SequencerAgent========");
  console.log("Contract address: ", sequencerAgent.address);
  log("Verifying...");
  await verify(sequencerAgent.address, arguments);
};

module.exports.tags = ["all", "SequencerAgent"];
