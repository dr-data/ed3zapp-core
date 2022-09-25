const Migrations = artifacts.require("Purchase");
const host = "0xEB796bdb90fFA0f28255275e16936D25d3418603";
module.exports = function (deployer) {
  deployer.deploy(Migrations, host);
};
