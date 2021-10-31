pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";

contract Mergeable is Initializable, ERC721URIStorageUpgradeable {
    modifier ownTokens(uint256[3] memory tokenIds_) {
        for (uint8 k = 0; k < tokenIds_.length; k++) {
            require(
                ownerOf(tokenIds_[k]) == msg.sender,
                "you do not own this token"
            );
        }
        _;
    }

    function __Mergeable_init(string memory name_, string memory symbol_)
        public
        initializer
    {
        __ERC721_init(name_, symbol_);
    }

    function _safeMerge(uint256 targetTokenId_, uint256[3] memory tokenIds_)
        internal
        ownTokens(tokenIds_)
    {
        _safeMint(msg.sender, targetTokenId_);

        _burn(tokenIds_[0]);
        _burn(tokenIds_[1]);
        _burn(tokenIds_[2]);
    }
}
