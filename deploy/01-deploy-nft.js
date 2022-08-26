 const {network} = require("hardhat")
const{ developmentChains, getContract} = require("../helper-hardhat-config")
const { verify } = require("../utils/verify")


module.exports = async({ getNamedAccounts, deployments}) => {
    const { deploy, log} = deployments;
    const { deployer } = await getNamedAccounts();

    args = []

    const nftMarketPlace = await deploy("NftMarketPlace", {
        from : deployer,
        args : args,
        log : true,
        waitConfirmation : network.config.blockConfirmations || 1,


    })

    if(!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY){
        log("VERIFYING.........................")
        await verify(nftMarketPlace.address, args)

    }
    log("-----------------------------------------")
}

module.exports.tags = ["all" , "NftMarketPlace"]