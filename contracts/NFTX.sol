pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "hardhat/console.sol";
import "./GeneScience.sol";
import "./BlindAuction.sol";
import "./Mergeable.sol";

contract Nftx is Initializable, OwnableUpgradeable, BlindAuction, Mergeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    struct NFTX {
        uint256 _genes;
        uint16 _generation;
    }

    CountersUpgradeable.Counter private _gen0CurrentCounter;
    CountersUpgradeable.Counter private _evolutionCurrentCounter;
    GeneScience private _geneScience;

    mapping(uint256 => NFTX) private tokens;

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
        __Mergeable_init("NFTX", "NFTX");
        __BlindAuction_init(initialSupply_, maxBuy_);
        seed = seed_;
    }

    function setGeneScience(GeneScience geneScience_) public onlyOwner {
        _geneScience = geneScience_;
    }

    function generateToken(uint256 seed_) internal view returns (NFTX memory) {
        return NFTX(_geneScience.getNewDNA(seed_), 0);
    }

    function getTokenTotalCount() external view returns (uint256) {
        return
            _gen0CurrentCounter.current() + _evolutionCurrentCounter.current();
    }

    function getGen0Nft(uint256 id_)
        internal
        view
        afterBlindAuction
        returns (NFTX memory)
    {
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
        auctionner(buyCount)
    {
        _safeMint(msg.sender, _gen0CurrentCounter.current());
        _gen0CurrentCounter.increment();
        tokens[_gen0CurrentCounter.current()] = generateToken(
            seed + _gen0CurrentCounter.current()
        );
    }

    function mergeTokens(uint256[3] memory tokenIds_) public {
        //TODO make payable
        uint16 generation = getNft(tokenIds_[0])._generation;
        for (uint256 k = 1; k < tokenIds_.length; k++) {
            require(
                tokens[tokenIds_[k]]._generation == generation,
                "your token are not of the same generation"
            );
        }

        uint256 nextGenes = _geneScience.mergeDNA(
            [
                getNft(tokenIds_[0])._genes,
                getNft(tokenIds_[1])._genes,
                getNft(tokenIds_[2])._genes
            ]
        );

        tokens[initialSupply + _evolutionCurrentCounter.current()] = NFTX(
            nextGenes,
            generation++
        );

        _safeMerge(
            initialSupply + _evolutionCurrentCounter.current(),
            tokenIds_
        );

        _evolutionCurrentCounter.increment();
    }
}
