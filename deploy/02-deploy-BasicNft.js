const {network} = require("hardhat")
const{ developmentChains} = require("../helper-hardhat-config")
const { verify } = require("../utils/verify")


module.exports = async({ getNamedAccounts, deployments}) => {
    const { deploy, logs} = deployments;
    const { deployer } = await getNamedAccounts();

    const args = []
    const BasicNft = await deploy("BasicNft" , {
        from : deployer,
        args : args,
        log : true,
        waitConfirmations :  network.config.blockConfirmations || 1,
    })

    if(!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY){
        log("verifying..............")
        await verify(BasicNft.address, args)
    }
}

module.exports.tags = ["all" , "basicNft"]