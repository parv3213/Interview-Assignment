// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract DemurrageERC721 is ERC721 {
    event TokenMinted(address _to, uint256 _price, uint256 _tokenId);
    event DemurragePaid(
        uint256 _tokenId,
        uint256 _payTill,
        uint256 _demurrageFee
    );

    struct DemurrageToken {
        uint256 price;
        uint256 paidTill;
    }

    uint256 public constant DEMURRAGE_FEE = 3;
    uint256 public constant PERCENT_DIVISOR = 1000;

    IERC20 public immutable dai;
    address payable public immutable demurrageCollector;
    uint256 public totalTokens;

    mapping(uint256 => DemurrageToken) public demurrageTokens;

    /**
     * @dev Initializes the contract by setting `_demurrageCollector` and a `_daiAddress`
     */
    constructor(address payable _demurrageCollector, address _daiAddress)
        ERC721("ACME", "ACME")
    {
        demurrageCollector = _demurrageCollector;
        dai = IERC20(_daiAddress);
    }

    /**
     * @dev Function to mint a NFT token
     * @param _to owner of NFT
     * @param _price price of NFT equivalent to physical asset
     * Requirements
     * - _price must be greater than PERCENT_DIVISOR, ie 1000
     */
    function mint(address _to, uint256 _price) external {
        totalTokens++;
        _mint(_to, totalTokens);
        require(_price/PERCENT_DIVISOR*PERCENT_DIVISOR == _price, "Too high precision"); // This is done to maintain precision
        demurrageTokens[totalTokens].price = _price;
        demurrageTokens[totalTokens].paidTill = block.timestamp;
        emit TokenMinted(_to, _price, totalTokens);
    }

    /**
     * @dev Function to pay for Demurrage
     * @param _tokenId token id for which Demurrage needs to be paid
     * @param _payTill timestamp of the day till user wants to pre-pay
     * Requirements
     * - only owner of approved owner can call this
     * - _payTill must be at least one full day more than token paidTill
     * - msg.sender must have approve DAI to this contract
     */
    function payDemurrage(uint256 _tokenId, uint256 _payTill) external {
        require(
            _isApprovedOrOwner(msg.sender, _tokenId),
            "Caller is not owner nor approved"
        );
        require(_payTill > block.timestamp);
        DemurrageToken memory _demurrageToken = demurrageTokens[_tokenId];
        uint256 _prepayDays = (_payTill - _demurrageToken.paidTill) / 86400; // 86400 is number of seconds in one day
        require(_prepayDays > 0, "Too low pay till");
        uint256 _demurrageFee = (_demurrageToken.price *
            _prepayDays *
            DEMURRAGE_FEE) / PERCENT_DIVISOR;
        demurrageTokens[_tokenId].paidTill = _payTill;
        require(
            dai.transferFrom(msg.sender, demurrageCollector, _demurrageFee),
            "Token transfer failed"
        );
        emit DemurragePaid(_tokenId, _payTill, _demurrageFee);
    }

    /**
     * @dev Check if pre-paid demurrage timestamp is greater than block time
     * Requirements
     * - pre-paid demurrage timestamp is greater than block time
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId); // Call parent hook
        if (_exists(tokenId)) {
            require(
                demurrageTokens[tokenId].paidTill >= block.timestamp,
                "Unpaid demurrage"
            );
        }
    }
}
