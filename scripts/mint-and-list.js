const { ethers } = require("hardhat")


const PRICE = ethers.utils.parseEther("0.1")

async function mintandlist(){
    const nftMarketPlace = await ethers.getContract("NftMarketPlace")
    const basicNft = await ethers.getContract("BasicNft")
    console.log("minting..........")
    const mintTx = await basicNft.mintNft()
    const mintTxReceipt = await mintTx.wait(1)
    const tokenId  = mintTxReceipt.events[0].args.tokenId
    console.log("Approving Nft.....................")

    const approvalTx = await basicNft.approve(nftMarketPlace.address, tokenId, PRICE)
    await approvalTx.wait(1)
    console.log("Listing Nft............")
    const tx = await nftMarketPlace.listItems(basicNft.address, tokenId, PRICE)
    await tx.wait(1)
    console.log("yuor items is listed!!!!!!")



}

mintandlist()
.then(() => process.exit(0))
.catch((error) =>{
    console.error(error)
    process.exit(1)
})