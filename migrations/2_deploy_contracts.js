const MasterChef = artifacts.require("MasterChef");
const CakeToken = artifacts.require("CakeToken");
const SampleToken = artifacts.require("SampleToken");

module.exports = async function (deployer) { 


    await deployer.deploy(CakeToken);
    //cakeToken = await CakeToken.new();
    //masterChef = await MasterChef.new(cakeToken.address, '1000', '100');

    //lp1 = await SampleToken.new('LPtoken', 'LP1', '1000');
    //lp2 = await SampleToken.new('LPtoken', 'LP2', '1000');





}