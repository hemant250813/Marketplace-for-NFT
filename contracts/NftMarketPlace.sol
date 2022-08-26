//SPDX-License-Identifier: MIT


// create a decentralisedNFts MarketPlace
// 1. `list` : item in a market place
// 2. `buy` : item in a marketPlace
// 3.`cancel Item` : cancel the listing
// 4. `Update Price`: updating Nft Price
// 5. `Withdraw`: withdraw payments from my sold Nfts

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";




error NftMarketPlace__PriceMustBeAboveZero();
error NftMarketPlace__NotApprovedForMarketPlace();
error NftMarketPlace__AlreadyListed(address nftAddress, uint256 tokenId );
error NftMarketPlace__NotOwner();
error NftMarketPlace__NotListed(address nftAddress, uint256 tokenId);
error NftMarketPlace__PriceNotMet(address nftAddress, uint256 tokenId, uint256 price);
error NftMarketPlace__NoProceeds();
error NftMarketPlace__TransferFailed();

contract NftMarketPlace is ReentrancyGuard{

    struct Listing{ 
        uint256 price;
        address seller;
    }

event ItemListed(
    address indexed seller,
    address indexed nftAddress,
    uint256 indexed tokenId,
    uint256 price
);

event ItemBought(
    address indexed buyer,
      address indexed nftAddress,
      uint256 indexed tokenId,
      uint256 price

) ;

event ItemCanceled(
    address indexed seller,
    address indexed nftAddress,
    uint256 indexed tokenId

);



    //NFTCOntract address ==> nft tokenId ==> listing;

    mapping(address => mapping(uint256 => Listing )) private s_listings;

    //seller adress ---> amount earn
    mapping(address => uint256) private s_proceeds;

    ////////////////////
    ///Modifiers///////
    //////////////////


    modifier notListed(
        address nftAddress,
        uint256 tokenId,
        address owner) {
        Listing memory listing = s_listings[nftAddress][tokenId];
        if(listing.price > 0){
            revert NftMarketPlace__AlreadyListed(nftAddress, tokenId );
        }
        _;
    }

    modifier isOwner(
        address nftAddress,
        uint256 tokenId,
        address spender) {
            IERC721 nft =IERC721(nftAddress);
            address owner = nft.ownerOf(tokenId);
            if(spender != owner){
                revert NftMarketPlace__NotOwner();
            }
            _;
        }

        modifier isListed(
            address nftAddress,
            uint256 tokenId
        ){
            Listing memory listing = s_listings[nftAddress][tokenId];
            if(listing.price <= 0){
                revert NftMarketPlace__NotListed(nftAddress, tokenId);
            }
            _;
        }


    //////////////////////
    ///Main Function/////
    ////////////////////

    function listItem( 
        address nftAddress,
         uint256 tokenId, 
         uint256 price) 
         external
          notListed (nftAddress, tokenId, msg.sender) 
          isOwner(nftAddress, tokenId, msg.sender)
           {
            if(price <= 0)
            {
                revert NftMarketPlace__PriceMustBeAboveZero();

                // send NFT to the contract ====> contract Hold the NFt
                // Owner csn still holf thier NFt , and give the maarket place approval 
                //to sell the NFT for them
             }

             IERC721 nft = IERC721(nftAddress);
             if(nft.getApproved(tokenId) != address(this)){

                revert NftMarketPlace__NotApprovedForMarketPlace();

             }
             s_listings[nftAddress][tokenId] = Listing(price, msg.sender);
             emit ItemListed( msg.sender, nftAddress, tokenId,  price);

    }
    function  buyItem(
        address nftAddress,
         uint256 tokenId)
         external payable 
         nonReentrant
        isListed(nftAddress , tokenId) {

            Listing memory listedItem = s_listings[nftAddress][tokenId];
            if(msg.value < listedItem.price){
                revert NftMarketPlace__PriceNotMet(nftAddress, tokenId, listedItem.price);
            }
            s_proceeds [listedItem.seller] =  s_proceeds [listedItem.seller] + msg.value;
            delete (s_listings[nftAddress][tokenId]);
            IERC721(nftAddress).safeTransferFrom(listedItem.seller, msg.sender, tokenId);
            emit ItemBought(msg.sender, nftAddress, tokenId, listedItem.price);
        }

        function cancelListing(address nftAddress, uint256 tokenId)
         external isOwner(nftAddress, tokenId, msg.sender) 
         isListed(nftAddress, tokenId) 
         {
            delete (s_listings[nftAddress][tokenId]);
            emit ItemCanceled(msg.sender, nftAddress, tokenId);

        }

        function updateListing(address nftAddress, uint256 tokenId, uint256 newPrice)
        external isListed(nftAddress, tokenId) 
        isOwner(nftAddress, tokenId, msg.sender){
            s_listings[nftAddress][tokenId].price = newPrice;
            emit ItemListed(msg.sender, nftAddress, tokenId, newPrice);

        }

        function widthrawProceeds() external{

            uint256 proceeds = s_proceeds[msg.sender];
            if(proceeds <= 0){
                revert NftMarketPlace__NoProceeds();
            }
            s_proceeds[msg.sender] = 0;
            (bool success, ) = payable(msg.sender).call{value: proceeds}("");
            if(!success){
                revert NftMarketPlace__TransferFailed();
            }
        }
                   ///////////////////////
                   ///getter Function/////
                  ///////////////////////

        function getListing(address nftAddress, uint256 tokenId)
         external view returns(Listing memory){
            return s_listings[nftAddress][tokenId];

        }

        function getProceeds(address seller) public view returns(uint256){
            return s_proceeds[seller];

        } 

}