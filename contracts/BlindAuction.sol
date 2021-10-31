pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "hardhat/console.sol";

contract BlindAuction is Initializable {
    bool public isBlindActionActive;
    uint256 public initialSupply;
    uint256 public remainingSupply;
    uint8 public maxBuy;
    uint256 public _blindAuctionStartingIndex;

    modifier afterBlindAuction() {
        require(isBlindActionActive == false, "blind auction is active");
        _;
    }

    modifier auctionner(uint8 buyCount) {
        require(isBlindActionActive == true, "blind auction is not active"); // TODO: handle premature end (we should have an end date)
        require(buyCount < maxBuy, "You cannot buy this many");
        uint256 cartPrice = 0;
        for (uint8 k = 0; k < buyCount; k++) {
            cartPrice += _getAuctionPrice(remainingSupply - k);
        }
        require(msg.value == cartPrice, "The price is not right");
        _;
        remainingSupply--;
        if (remainingSupply == 0) {
            _endBlindAuction();
        }
    }

    function __BlindAuction_init(uint256 initialSupply_, uint8 maxBuy_)
        public
        initializer
    {
        isBlindActionActive = true;
        remainingSupply = initialSupply_;
        initialSupply = initialSupply_;
        maxBuy = maxBuy_;
    }

    function _endBlindAuction() internal {
        _blindAuctionStartingIndex = block.number % initialSupply;
        isBlindActionActive = false;
    }

    function _getAuctionPrice(uint256 initialSupplyInvertedIndex_)
        private
        view
        returns (uint256)
    {
        require(
            initialSupplyInvertedIndex_ <= initialSupply,
            "token not in initial supply"
        );
        if (initialSupplyInvertedIndex_ >= (4 * initialSupply) / 5) {
            return 0.01 ether;
        }
        if (initialSupplyInvertedIndex_ >= (3 * initialSupply) / 5) {
            return 0.05 ether;
        }
        if (initialSupplyInvertedIndex_ >= (2 * initialSupply) / 5) {
            return 0.1 ether;
        }
        if (initialSupplyInvertedIndex_ >= initialSupply / 5) {
            return 0.5 ether;
        }
        return 1 ether;
    }

    function getAuctionPrice() public view returns (uint256) {
        return _getAuctionPrice(remainingSupply);
    }
}
