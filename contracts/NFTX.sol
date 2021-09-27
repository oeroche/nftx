pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";

contract Nftx is ERC721URIStorage {
    uint8 NUMBER_OF_GENES = 10;
    uint256 MODULUS = 10**NUMBER_OF_GENES;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    struct NFTX {
        uint32 _genes;
        uint16 _generation;
    }

    mapping(uint256 => NFTX) tokens;

    mapping(uint8 => uint256) public cursors;

    uint16 private INITIAL_SUPPLY;

    bool private INITIALIZED;
    bool private IS_BLIND_AUCTION;

    uint256 public BLIND_AUCTION_STARTING_INDEX;

    uint256 private seed;

    modifier afterBlindAuction() {
        require(IS_BLIND_AUCTION == false, "Blind auction is not ended");
        _;
    }

    modifier initialSupplyisCompatibleWithEvolutionSteps(
        uint16 initialSupply_,
        uint8 evolution_steps_count_
    ) {
        require(
            evolution_steps_count_ != 0,
            "evolution steps count can't be 0"
        );
        require(
            SafeMath.sub(
                initialSupply_,
                SafeMath.mul(
                    3**evolution_steps_count_,
                    initialSupply_ / (3**evolution_steps_count_)
                )
            ) == 0,
            "Initial supply cannot support evolution steps count"
        );
        _;
    }

    constructor(
        uint256 seed_,
        uint16 initialSupply_,
        uint8 evolution_steps_count_
    )
        ERC721("EvolutionToken", "EVOT")
        initialSupplyisCompatibleWithEvolutionSteps(
            initialSupply_,
            evolution_steps_count_
        )
    {
        INITIAL_SUPPLY = initialSupply_;
        IS_BLIND_AUCTION = true;
        INITIALIZED = false;
        seed = seed_;
        generateCursors(evolution_steps_count_);
        INITIALIZED = true;
    }

    function generateToken(uint256 seed_) internal view returns (NFTX memory) {
        uint256 rand = uint256(keccak256(abi.encode(seed_)));
        return NFTX(uint32(SafeMath.mod(rand, MODULUS)), 0);
    }

    function generateCursors(uint8 evolution_steps_count_) private {
        require(
            INITIALIZED == false,
            "The contract has already been initialized"
        );

        cursors[0] = 0;
        cursors[1] = INITIAL_SUPPLY;

        for (uint8 i = 2; i <= evolution_steps_count_; i++) {
            console.log("i is %s", i);
            cursors[i] = SafeMath.add(
                cursors[i - 1],
                SafeMath.div(SafeMath.sub(cursors[i - 1], cursors[i - 2]), 3)
            );
            console.log("cursors[i] is %s", cursors[i]);
        }
    }

    function isInitialized() external view returns (bool) {
        return INITIALIZED;
    }

    function getTokenTotalCount() external view returns (uint256) {
        if (INITIAL_SUPPLY < _tokenIds.current() + 1) {
            return _tokenIds.current() + 1;
        } else {
            return INITIAL_SUPPLY;
        }
    }

    function getGen0Nft(uint256 id_) internal view returns (NFTX memory) {
        return
            tokens[
                SafeMath.mod(BLIND_AUCTION_STARTING_INDEX + id_, INITIAL_SUPPLY)
            ];
    }

    function getNft(uint256 id_)
        public
        view
        afterBlindAuction
        returns (NFTX memory)
    {
        if (id_ <= INITIAL_SUPPLY) {
            return getGen0Nft(id_);
        } else {
            return tokens[id_];
        }
    }

    function preOrderToken() external {
        require(
            _tokenIds.current() + 1 <= INITIAL_SUPPLY,
            "Initial offering is over"
        );
        _safeMint(msg.sender, _tokenIds.current());
        _tokenIds.increment();
        tokens[_tokenIds.current()] = generateToken(seed);
        if (_tokenIds.current() == INITIAL_SUPPLY - 1) {
            turnBlindAuctionOff();
        }
    }

    function turnBlindAuctionOff() internal {
        BLIND_AUCTION_STARTING_INDEX = SafeMath.mod(
            block.number,
            INITIAL_SUPPLY
        );
        IS_BLIND_AUCTION = false;
    }
}
