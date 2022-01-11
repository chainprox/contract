var RoxToken = artifacts.require("RoxToken");
var RoxPresale = artifacts.require("RoxPresale");

module.exports = function(deployer) {
  deployer.deploy(RoxToken);
  deployer.deploy(RoxPresale);
};
