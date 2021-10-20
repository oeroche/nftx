pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract Contributors is Initializable {
    bool private _initialized;
    address[] contributors;
    mapping(address => uint256) public distribution;
    mapping(address => uint256) public withdrawable;

    address private _owner;
    address private _nftxAddress;

    modifier onlyNftx() {
        require(msg.sender == _nftxAddress, "You cannot call this method");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "You cannot call this method");
        _;
    }

    constructor() {
        _owner = msg.sender;
    }

    function initialize(address nftxAddress_) public onlyOwner {
        require(
            !_initialized,
            "Contract instance has already been initialized"
        );
        _initialized = true;
        _nftxAddress = nftxAddress_;
    }

    function setDistribution(
        address[] memory contributors_,
        uint256[] memory amounts_
    ) public onlyOwner {
        uint256 totalAmount;
        for (uint256 i = 0; i < amounts_.length; i++) {
            totalAmount += amounts_[i];
        }
        for (uint256 k = 0; k < contributors.length; k++) {
            distribution[contributors[k]] = 0;
        }
        require(
            totalAmount == 1 ether && contributors_.length == amounts_.length,
            "The distribution is not valid"
        );
        _clearDistribution();
        contributors = contributors_;
        for (uint256 k = 0; k < contributors_.length; k++) {
            distribution[contributors_[k]] = amounts_[k];
        }
    }

    function distributePayment(uint256 payment) public onlyNftx {
        for (uint256 k = 0; k < contributors.length; k++) {
            withdrawable[contributors[k]] +=
                (payment * distribution[contributors[k]]) /
                1 ether;
        }
    }

    function recordWithdraw(address contributor_, uint256 amount_)
        public
        onlyNftx
    {
        require(
            amount_ <= withdrawable[contributor_],
            "You cannot withdraw such and amount"
        );
        withdrawable[contributor_] -= amount_;
    }

    function getWithdrawable(address contributor_)
        public
        view
        onlyNftx
        returns (uint256)
    {
        return withdrawable[contributor_] / 1 ether;
    }

    function _clearDistribution() private {
        for (uint256 k = 0; k < contributors.length; k++) {
            distribution[contributors[k]] = 0;
        }
    }
}
