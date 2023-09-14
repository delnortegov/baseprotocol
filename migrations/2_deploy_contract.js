const DelnorteFractionalizer = artifacts.require("DelnorteFractionalizer");
const DelnorteProperties = artifacts.require("DelnorteProperties");
const dUSDTContract = artifacts.require("dUSDT");
const Staking = artifacts.require("DelnorteStaking");


module.exports = function(deployer) {
    deployer.then(async () => {
        /**
        await deployer.deploy(DelnorteProperties, "Delnorte Properties", "DTV", []);
        let _DelnorteProperties = await DelnorteProperties.deployed();
        
        await deployer.deploy(
            DelnorteFractionalizer, 
            _DelnorteProperties.address,
            18, 1);
        let _DelnorteFractionalizer = await DelnorteFractionalizer.deployed();

        await deployer.deploy(dUSDTContract);
         */
        await deployer.deploy(
            Staking, 
            "0x73A597834A0637BbB2bf033dd60B70b42f53De9B", 
            "0xFFc48E37296e2b6E2e7513729901D19AC9aD45cC",
            []);
    });        
}
