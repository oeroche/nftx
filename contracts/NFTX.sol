pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "hardhat/console.sol";
import "./GeneScience.sol";
import "./BlindAuction.sol";

contract Nftx is
    Initializable,
    OwnableUpgradeable,
    BlindAuction,
    ERC721URIStorageUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    struct NFTX {
        uint32 _genes;
        uint16 _generation;
    }

    CountersUpgradeable.Counter private _tokenIds;
    GeneScience private _geneScience;

    mapping(uint256 => NFTX) tokens;

    mapping(uint8 => uint256) public cursors;

    uint256 private seed;

    modifier initialSupplyisCompatibleWithEvolutionSteps(
        uint16 initialSupply_,
        uint8 evolution_steps_count_
    ) {
        require(
            evolution_steps_count_ != 0,
            "evolution steps count can't be 0"
        );
        require(
            initialSupply_ -
                ((3**evolution_steps_count_ * initialSupply_) /
                    (3**evolution_steps_count_)) ==
                0,
            "Initial supply cannot support evolution steps count"
        );
        _;
    }

    function initialize(
        uint256 seed_,
        uint16 initialSupply_,
        uint8 evolution_steps_count_,
        uint8 maxBuy_
    )
        public
        initialSupplyisCompatibleWithEvolutionSteps(
            initialSupply_,
            evolution_steps_count_
        )
        initializer
    {
        __Ownable_init();
        __ERC721_init("NFTX", "NFTX");
        __BlindAuction_init(initialSupply_, maxBuy_);
        seed = seed_;

        // Cursor generation for multiple generations
        cursors[0] = 0;
        cursors[1] = initialSupply;

        for (uint8 i = 2; i <= evolution_steps_count_; i++) {
            cursors[i] =
                cursors[i - 1] +
                ((cursors[i - 1] - cursors[i - 2]) / 3);
        }
    }

    function setGeneScience(GeneScience geneScience_) public onlyOwner {
        _geneScience = geneScience_;
    }

    function generateToken(uint256 seed_) internal view returns (NFTX memory) {
        return NFTX(_geneScience.getNewDNA(seed_), 0);
    }

    function getTokenTotalCount() external view returns (uint256) {
        if (initialSupply < _tokenIds.current() + 1) {
            return _tokenIds.current() + 1; //TODO: remove burned tokens
        } else {
            return initialSupply;
        }
    }

    function getGen0Nft(uint256 id_) internal view returns (NFTX memory) {
        return tokens[_blindAuctionStartingIndex + (id_ % initialSupply)];
    }

    function getNft(uint256 id_)
        public
        view
        afterBlindAuction
        returns (NFTX memory)
    {
        if (id_ <= initialSupply) {
            return getGen0Nft(id_);
        } else {
            return tokens[id_];
        }
    }

    function preOrderToken(uint8 buyCount)
        external
        payable
        auctionner(_tokenIds.current(), buyCount)
    {
        _safeMint(msg.sender, _tokenIds.current());
        _tokenIds.increment();
        tokens[_tokenIds.current()] = generateToken(seed);
    }
}
