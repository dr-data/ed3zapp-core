const Migrations = artifacts.require("App");

module.exports = function (deployer) {
  deployer.deploy(Migrations);
};
