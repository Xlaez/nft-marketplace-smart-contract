// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Used to keep track of NFTs created
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "hardhat/console.sol";

contract NFTMarketplace is ERC721URIStorage {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIDs;
    Counters.Counter private _itemsSold;

    uint256 listingPrice = 0.0025 ether;

    address payable owner;

    mapping(uint256 => MarketItem) private marketItemsID;

    struct MarketItem {
        uint256 tokenID;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    event marketItemIDCreated(
        uint256 indexed tokenID,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    modifier isOwner() {
        require(
            msg.sender == owner,
            "UNAUTHORIZED: only contract owner can change the lising price."
        );
        _;
    }

    constructor() ERC721("NFT MetaVerse Token", "MYNFT") {
        owner == payable(msg.sender);
    }

    function updateListingPrice(uint256 _lisitngPrice) public payable isOwner {
        listingPrice = _lisitngPrice;
    }

    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    function createToken(
        string memory tokenURI,
        uint256 price
    ) public payable returns (uint256) {
        _tokenIDs.increment();

        uint256 newTokenID = _tokenIDs.current();
        _mint(msg.sender, newTokenID);
        _setTokenURI(newTokenID, tokenURI);

        createMarketItem(newTokenID, price);
        return newTokenID;
    }

    function createMarketItem(uint256 tokenID, uint256 price) private {
        require(price > 0, "Price must be at least 1.00");
        require(
            msg.value == listingPrice,
            "Price must be equal to listing price."
        );
        marketItemsID[tokenID] = MarketItem(
            tokenID,
            payable(msg.sender),
            payable(address(this)),
            price,
            false
        );

        _transfer(msg.sender, address(this), tokenID);
        emit marketItemIDCreated(
            tokenID,
            msg.sender,
            address(this),
            price,
            false
        );
    }

    // Function for resale NFT
    function reSellToken(uint256 tokenID, uint256 price) public payable {
        require(
            marketItemsID[tokenID].owner == msg.sender,
            "UNAUTHORIZED: NFT can be sold only by owner"
        );
        require(
            msg.value == listingPrice,
            "Price must be equal to listing price"
        );
        marketItemsID[tokenID].sold = false;
        marketItemsID[tokenID].price = price;
        marketItemsID[tokenID].seller = payable(msg.sender);
        marketItemsID[tokenID].owner = payable(address(this));

        _itemsSold.decrement();
        _transfer(msg.sender, address(this), tokenID);
    }

    function createMarketSale(uint256 tokenID) public payable {
        uint256 price = marketItemsID[tokenID].price;
        require(
            msg.value == price,
            "TRANSACTION FAILED: Please submit exact price for the token in order to complete transaction."
        );
        marketItemsID[tokenID].owner = payable(msg.sender);
        marketItemsID[tokenID].sold = true;
        marketItemsID[tokenID].seller = payable(address(0));

        _itemsSold.increment();
        _transfer(address(this), msg.sender, tokenID);
        payable(owner).transfer(listingPrice);
        payable(marketItemsID[tokenID].seller).transfer(msg.value);
    }

    // GET UNSOLD NFT ITEMS
    function fetchMarketItems() public view returns (MarketItem[] memory) {
        uint256 totalItems = _tokenIDs.current();
        uint256 totalUnSoldItems = _tokenIDs.current() - _itemsSold.current();
        uint256 currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](totalUnSoldItems);
        for (uint256 i = 0; i < totalItems; i++) {
            if (marketItemsID[i + 1].owner == address(this)) {
                uint256 currentID = i + 1;

                MarketItem storage currentItems = marketItemsID[currentID];
                items[currentIndex] = currentItems;
                currentIndex += 1;
            }
        }

        return items;
    }

    function fetchUserNFT() public view returns (MarketItem[] memory) {
        uint256 totalCount = _tokenIDs.current();
        uint256 totalItems = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; 1 < totalCount; i++) {
            if (marketItemsID[i + 1].owner == msg.sender) {
                totalItems += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](totalItems);
        for (uint256 i = 0; i < totalCount; i++) {
            if (marketItemsID[i + 1].owner == msg.sender) {
                uint256 currentID = i + 1;
                MarketItem storage currentItem = marketItemsID[currentID];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function fetchItemsListed() public view returns (MarketItem[] memory) {
        uint256 totalCount = _tokenIDs.current();
        uint256 totalItems = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalCount; i++) {
            if (marketItemsID[1 + 1].seller == msg.sender) {
                totalItems += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](totalItems);
        for (uint256 i = 0; 1 < totalCount; i++) {
            if (marketItemsID[i + 1].seller == msg.sender) {
                uint256 currentID = 1 + 1;
                MarketItem storage currentItem = marketItemsID[currentID];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }
}
