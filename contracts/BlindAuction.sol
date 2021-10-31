pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract BlindAuction is Initializable {
    bool public isBlindActionActive;
    uint256 public initialSupply;
    uint8 public maxBuy;
    uint256 internal _blindAuctionStartingIndex;

    modifier afterBlindAuction() {
        require(isBlindActionActive == false, "blind auction is active");
        _;
    }

    modifier auctionner(uint256 lastTokenId, uint8 buyCount) {
        require(isBlindActionActive == true, "blind auction is not active"); // TODO: handle premature end (we should have an end date)
        require(buyCount < maxBuy, "You cannot buy this many"); // TODO: handle tresholds in blind auction
        require(
            msg.value == buyCount * getAuctionPrice(lastTokenId),
            "The price is not right"
        );
        _;
        if (lastTokenId == initialSupply - 1) {
            _endBlindAuction();
        }
    }

    function __BlindAuction_init(uint256 initialSupply_, uint8 maxBuy_)
        public
        initializer
    {
        isBlindActionActive = true;
        initialSupply = initialSupply_;
        maxBuy = maxBuy_;
    }

    function _endBlindAuction() internal {
        _blindAuctionStartingIndex = block.number % initialSupply;
        isBlindActionActive = false;
    }

    function getAuctionPrice(uint256 tokenId_) public view returns (uint256) {
        require(tokenId_ <= initialSupply, "token not in initial supply");
        if (tokenId_ < initialSupply / 5) {
            return 0.01 ether;
        }
        if (tokenId_ < (2 * initialSupply) / 5) {
            return 0.05 ether;
        }
        if (tokenId_ < (3 * initialSupply) / 5) {
            return 0.1 ether;
        }
        if (tokenId_ < (4 * initialSupply) / 5) {
            return 0.5 ether;
        }
        return 1 ether;
    }
}
