const ANV = artifacts.require("ANVToken");
const NFT = artifacts.require("ANV_NFT");
const gorvernance = artifacts.require("KANV_Gorvanance");

module.exports = function(deployer,network, accounts) {
  deployer.deploy(ANV);
  deployer.deploy(NFT,'aa','aa')
  deployer.deploy(gorvernance, ANV.address, NFT.address, ANV.address);


};
