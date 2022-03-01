// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

/// @title Enotecum NFT
/// @author The name of the author
/// @notice Mint NFT
/// @dev Batch Mints using Whitelisting
contract EnotNFT is ERC721A, ReentrancyGuard, Ownable, Pausable {
    using Strings for uint256;

    // Public vars
    string public baseTokenURI;
    uint256 public price = 0.01 ether; // Set the price

    // Immutable vars
    uint256 public immutable maxSupply; ///only if required
    uint256 public immutable maximumAllowedMintsPerAddress = 10; // Set the maximum number of NFTs that can be minted per address

    /**
     * @notice Construct a Enotecum NFT instance
     * @param name Token name
     * @param symbol Token symbol
     * @param baseTokenURI_ Base URI for all tokens
     * @param maxSupply_ Max Supply of tokens
     */
    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI_,
        uint256 maxSupply_
    ) ERC721A(name, symbol) {
        require(maxSupply_ > 0, "INVALID_SUPPLY");
        baseTokenURI = baseTokenURI_;
        maxSupply = maxSupply_;
    }

    // Used to validate authorized mint addresses
    // address private signerAddress = 0x290Df62917EAb5b06E3c04a583E2250A0B46d55f;//Change

    mapping(address => uint256) public totalMintsPerAddress;

    mapping(address => uint256) whitelistedAddresses;

    bool public isSaleActive = false;
    bool public isAllowListActive = false;

    ///@notice To get the Token URI
    ///@dev Returns the token URI
    ///@param tokenId The token ID
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");

        return
            string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"));
    }

    /// @notice returns the Base URI
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /// @notice Sets the Mint Price
    /// @param _newMintPrice New Mint Price
    function setMintPrice(uint256 _newMintPrice) public onlyOwner {
        require(price != _newMintPrice, "New Mint price cannot be the same");
        price = _newMintPrice;
    }

    /// @notice Sets isSaleActive to true or false
    /// @param _saleActiveState True or False
    function setSaleState(bool _saleActiveState) public onlyOwner {
        require(
            isSaleActive != _saleActiveState,
            "NEW_STATE_IDENTICAL_TO_OLD_STATE"
        );
        isSaleActive = _saleActiveState;
    }

    /// @notice To get the total number of NFTs owned by an address
    /// @param owner Address of the owner for which the tokens need to be shown
    function ownedTokensByAddress(address owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 totalTokensOwned = balanceOf(owner);
        uint256[] memory allTokenIds = new uint256[](totalTokensOwned);
        for (uint256 i = 0; i < totalTokensOwned; i++) {
            allTokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }
        return allTokenIds;
    }

    /**
     * @notice Update the base token URI
     */
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseTokenURI = _newBaseURI;
    }

    ///@notice Pause the contract
    function pause() public onlyOwner {
        _pause();
    }

    ///@notice Unpause the contract
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * When the contract is paused, all token transfers are prevented in case of emergency.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 tokenId,
        uint256 quantity
    ) internal override(ERC721A) whenNotPaused {
        super._beforeTokenTransfers(from, to, tokenId, quantity);
    }

    /// @notice Toggle the whitelist Status
    /// @param _isAllowListActive True or False
    function setIsAllowListActive(bool _isAllowListActive) external onlyOwner {
        require(
            isAllowListActive != _isAllowListActive,
            "NEW_STATE_IDENTICAL_TO_OLD_STATE"
        );
        isAllowListActive = _isAllowListActive;
    }

    modifier isWhitelisted(address _address) {
        require(
            whitelistedAddresses[_address] == 1,
            "Whitelist: You need to be whitelisted"
        );
        _;
    }

    /// @notice Whitelist an array of addresses to mint NFTs
    /// @param _addressToWhitelist array of addresses to be whitelisted
    function addArrayOfUsers(address[] calldata _addressToWhitelist)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _addressToWhitelist.length; i++) {
            require(
                whitelistedAddresses[_addressToWhitelist[i]] != 1,
                "ADDRESS_ALREADY_WHITELISTED"
            );
            whitelistedAddresses[_addressToWhitelist[i]] = 1;
        }
    }

    /// @notice Whitelist an array of addresses to mint NFTs
    /// @param _addressToWhitelist address to be whitelisted
    function addUser(address _addressToWhitelist) public onlyOwner {
        require(
            whitelistedAddresses[_addressToWhitelist] != 1,
            "ADDRESS_ALREADY_WHITELISTED"
        );
        whitelistedAddresses[_addressToWhitelist] = 1;
    }

    /// @notice Verify whether an address is whitelisted
    /// @param _addressToVerify The address to be verified
    /// @return Bool True if the address is whitelisted, false otherwise
    function verifyUser(address _addressToVerify) public view returns (bool) {
        if (whitelistedAddresses[_addressToVerify] == 1) {
            return true;
        } else {
            return false;
        }
    }
    /// @notice View the price required to mint the NFT
    /// @param mintNumber The number of NFTs to mint
    function viewPrice (uint256 mintNumber) public view returns (uint256) {
      return  ((price * mintNumber) - 0.0001 ether);
    }

    /// @notice Mint the NFT
    /// @param mintNumber Number of NFTs to mint
    function mint(uint256 mintNumber)
        external
        payable
        virtual
        nonReentrant
        isWhitelisted(msg.sender)
    {
        uint256 currentSupply = totalSupply();
        require(isSaleActive, "SALE_IS_NOT_ACTIVE");
        require(
            totalMintsPerAddress[msg.sender] + mintNumber <=
                maximumAllowedMintsPerAddress,
            "MINT_TOO_LARGE"
        );
        require(isAllowListActive, "Allow list is not active");

        // Imprecise floats are scary. Front-end should utilize BigNumber for safe precision, but adding margin just to be safe to not fail txs
        require(
            msg.value >= ((price * mintNumber) - 0.0001 ether),
            "INVALID_PRICE"
        );

        require(
            currentSupply + mintNumber <= maxSupply,
            "NOT_ENOUGH_MINTS_AVAILABLE"
        );

        totalMintsPerAddress[msg.sender] += mintNumber;

        _safeMint(msg.sender, mintNumber);

        if (currentSupply + mintNumber >= maxSupply) {
            isSaleActive = false;
        }
    }

    // /**
    //  * @notice Allow owner to send `mintNumber` tokens without cost to multiple addresses
    //  */
    // function gift(address[] calldata receivers, uint256 mintNumber) external onlyOwner {
    //     require((totalSupply() + (receivers.length * mintNumber)) <= maxSupply, "MINT_TOO_LARGE");

    //     for (uint256 i = 0; i < receivers.length; i++) {
    //         _safeMint(receivers[i], mintNumber);
    //     }
    // }

    /**
     * @notice Allow contract owner to withdraw funds to its own account.
     */
    function withdraw() external onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    }
}
