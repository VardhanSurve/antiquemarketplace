// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;



//INTERNAL IMPORT FOR NFT OPENZIPLINE
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "hardhat/console.sol";

contract NFTMarketplace is ERC721URIStorage{
    using Counters for Counters.Counter;
        
    Counters.Counter private _tokenIds;//Token ID Counters
    Counters.Counter private _tokensSold;//Token Sold Counters

    uint256 listingPrice = 0.0015 ether; //Marketplace Commission Price

    address payable owner;//NFT Owner's address

    mapping(uint256 => MarketItem) private idMarketItem;//Mapping Each NFT with MarketItem id

    struct MarketItem {
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }//MarketItem Structure
    event idMarketItemCreated(
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );//Event called when Market Item is created

    modifier onlyOwner() {
        require(
            msg.sender == owner,"Only owner of the MarketPlace is allowed to Change the Listing Price");
            _;
    }//Modifier to allow only the owner to make changes

    constructor() ERC721("Antique Token", "MY_ANTIQUE"){
        owner == payable(msg.sender);
    }// Token Constructor

    function updateListingPrice(uint256 _listingprice) public payable onlyOwner{
        listingPrice = _listingprice;

    }//Function to Change the Listing Price

    function getListingPrice() public view returns (uint256){
        return listingPrice;
    }//Function to get the Listing Price

    

    function createToken(string memory tokenURI, uint256 price) public payable returns(uint256){
        _tokenIds.increment();

        uint256 newTokenId = _tokenIds.current();
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);

        createMarketItem(newTokenId, price);

        return newTokenId;

    }// Create a NFT token

    function createMarketItem(uint256 tokenId, uint256 price)private{
        require(price > 0, "Price cannot be 0");
        require(msg.value == listingPrice, "Price must be equal to Listing Price");
        idMarketItem[tokenId] = MarketItem(
            tokenId,
            payable(msg.sender),
            payable(address(this)),//SmartContract Address
            price,
            false
        );//makes a MarketItem Id
        _transfer(msg.sender, address(this), tokenId);//Transfers NFT to Contract Address
        emit idMarketItemCreated(
            tokenId,
            msg.sender,
            address(this),
            price,
            false
            );// Assign Initial Token Data
    }// Creates a NFT Item
    
    function resaleToken(uint256 tokenId, uint256 price)public payable{
        require(idMarketItem[tokenId].owner == msg.sender,"Only Item Owner can Do this Action");
        require(msg.value == listingPrice);
        idMarketItem[tokenId].sold =  false;
        idMarketItem[tokenId].price = price;
        idMarketItem[tokenId].seller = payable(msg.sender);
        idMarketItem[tokenId].owner = payable(address(this));

        _tokensSold.decrement();
        _transfer(msg.sender, address(this), tokenId);
    }//Function to Resale NFT

    function createMarketSale(uint256 tokenId)public payable{
        uint256 price = idMarketItem[tokenId].price;
        require(msg.value == price,"Please Submit the Asking Price to Complete this Action");

        idMarketItem[tokenId].owner = payable(msg.sender);
        idMarketItem[tokenId].sold = true;
        idMarketItem[tokenId].owner = payable(address(0));

        _tokensSold.increment();
        _transfer(address(this),msg.sender,tokenId);
        payable(owner).transfer(listingPrice);
        payable(idMarketItem[tokenId].seller).transfer(msg.value);
        
    }//Function to Create Sale Event

    function fetchMarketItem() public view returns(MarketItem[] memory){
        uint256 itemCount = _tokenIds.current();
        uint256 unSoldItemCount = _tokenIds.current() - _tokensSold.current();
        uint256 currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unSoldItemCount);
        for (uint256 i = 0; i < itemCount; i++){
            if(idMarketItem[i +1].owner == address(this)){
                uint256 currentId = i + 1;
            MarketItem storage currentItem = idMarketItem[currentId];
            items[currentIndex] = currentItem;
            currentIndex++;
            }
        }
        return items;
    
    }//Function to get the no. of Unsold items

    function fetchMyNFT() public view returns(MarketItem[] memory){
        uint256 totalCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalCount; i++){
            if(idMarketItem[i+1].owner == msg.sender){
                itemCount++;
            }
        }
        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i=0; i < itemCount; i++){
                if(idMarketItem[i+1].owner == msg.sender){
                    uint256 currentId = i+1;
                    MarketItem storage currentItems = idMarketItem[currentId];
                    items[currentIndex] = currentItems;
                    currentIndex++;
                }
        }return items;

    }//Function to Get my NFTs

    function fetchItemsListed() public view returns(MarketItem[] memory){
        uint256 totalCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalCount; i++){
            if(idMarketItem[i+1].seller == msg.sender){
                itemCount++;
            }
        }
        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i=0; i < itemCount; i++){
                if(idMarketItem[i+1].seller == msg.sender){
                    uint256 currentId = i+1;
                    MarketItem storage currentItems = idMarketItem[currentId];
                    items[currentIndex] = currentItems;
                    currentIndex++;
                }
        }return items;

    }//Function to get Listed NFTs
    
}