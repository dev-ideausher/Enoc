// SPDX-License-Identifier: MIT

/// @title NFT market contract
/// @author The name of the author
/// @notice NFT MarketPlace contract to list and buy
/// @dev Explain to a developer any extra details

pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract CellarCoinNFTMarket is ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _nftIdCounter;
    Counters.Counter private _nftItemsSold;

    address payable owner;
    uint256 public listingPrice ;

    constructor(uint256 _listingPrice) {
        owner = payable(msg.sender);
        listingPrice = _listingPrice;
    }

    struct NFTItem {
        uint256 Itemid;
        address nftContract;
        uint256 nftTokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool isSold;
    }

    mapping(uint256 => NFTItem) private _nftItems;

    event NFTItemCreated(
        uint256 indexed Itemid,
        address indexed nftContract,
        uint256 indexed nftTokenId,
        address seller,
        address owner,
        uint256 price,
        bool isSold
    );    

    /// @notice Sets the new Listing Price;
    /// @param _newListingPrice The new Listing Price
    function setlistingPrice(uint256 _newListingPrice) external {
        require(msg.sender == owner, "Only the owner can set the Listing Price");
        require(
            listingPrice != _newListingPrice,
            "The new Listing Price must be different from the current one"
        );
        listingPrice = _newListingPrice;
    }

    /**
     * Check if a specific address is
     * a contract address
     * @param _addr: address to verify
     */
    function isContract(address _addr) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    /// @notice Place an Item for Sale
    ///@param nftContract Address of the NFT Contract
    ///@param nftTokenId  Token Id of the NFt
    ///@param price Price of the Item
    function placeItemForSale(
        address nftContract,
        uint256 nftTokenId,
        uint256 price
    ) public payable nonReentrant {
        require(isContract(nftContract), "NFT Contract is not a contract");
        require(price > 0, "Price must be greater than 0");
        require(
            msg.value >= listingPrice,
            "Amount must be greater than or equal to the Listing Price"
        );

        _nftIdCounter.increment();
        uint256 itemId = _nftIdCounter.current();

        _nftItems[itemId] = NFTItem(
            itemId,
            nftContract,
            nftTokenId,
            payable(msg.sender),
            payable(address(0)),
            price,
            false
        );
        IERC721(nftContract).safeTransferFrom(
            msg.sender,
            address(this),
            nftTokenId
        );

        //emit an event for the item created
        emit NFTItemCreated(
            itemId,
            nftContract,
            nftTokenId,
            msg.sender,
            address(0),
            price,
            false
        );
    }

    /// @notice Buy an Item
    ///@param nftContract Address of the NFT Contract
    function createMarketSale(uint256 itemId, address nftContract)
        public
        payable
        nonReentrant
    {
        uint256 price = _nftItems[itemId].price;
        uint256 nftTokenId = _nftItems[itemId].nftTokenId;

        require(
            msg.value >= price,
            "Amount must be greater than or equal to the price"
        );

        _nftItems[itemId].seller.transfer(msg.value);

        IERC721(nftContract).transferFrom(
            address(this),
            msg.sender,
            nftTokenId
        );

        _nftItems[itemId].owner = payable(msg.sender);
        _nftItems[itemId].isSold = true;

        _nftItemsSold.increment();
    }

    /// @notice Returns all Unsold Items
    function getUnsoldItems() public view returns (NFTItem[] memory) {
        uint256 itemCount = _nftIdCounter.current();
        uint256 unsoldItemCount = _nftIdCounter.current() -
            _nftItemsSold.current();
        uint256 currentIndex = 0;

        NFTItem[] memory unsoldItems = new NFTItem[](unsoldItemCount);

        for (uint256 index = 0; index < itemCount; index++) {
            if (_nftItems[index + 1].owner == msg.sender) {
                uint256 CurrentID = index + 1;
                NFTItem memory Currentitem = _nftItems[CurrentID];
                unsoldItems[currentIndex] = Currentitem;
                currentIndex++;
            }
        }
        return unsoldItems;
    }

    /// @notice Returns only items that a user has bought
    function fetchUserNFT() public view returns (NFTItem[] memory) {
        uint256 TotalItemCount = _nftIdCounter.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 index = 0; index < TotalItemCount; index++) {
            if (_nftItems[index + 1].owner == msg.sender) {
                itemCount++;
            }
        }
        NFTItem[] memory userNFT = new NFTItem[](itemCount);

        for (uint256 index = 0; index < TotalItemCount; index++) {
            if (_nftItems[index + 1].owner == msg.sender) {
                uint256 CurrentID = index + 1;
                NFTItem memory Currentitem = _nftItems[CurrentID];
                userNFT[currentIndex] = Currentitem;
                currentIndex++;
            }
        }
        return userNFT;
    }

    ///@notice Returns all items that are user has created
    function getUserItems() public view returns (NFTItem[] memory) {
        uint256 TotalItemCount = _nftIdCounter.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 index = 0; index < TotalItemCount; index++) {
            if (_nftItems[index + 1].seller == msg.sender) {
                itemCount++;
            }
        }
        NFTItem[] memory userNFT = new NFTItem[](itemCount);

        for (uint256 index = 0; index < TotalItemCount; index++) {
            if (_nftItems[index + 1].seller == msg.sender) {
                uint256 CurrentID = index + 1;
                NFTItem memory Currentitem = _nftItems[CurrentID];
                userNFT[currentIndex] = Currentitem;
                currentIndex++;
            }
        }
        return userNFT;
    }
}
