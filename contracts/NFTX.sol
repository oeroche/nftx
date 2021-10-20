pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";
import "./GeneScience.sol";
import "./Contributors.sol";

contract Nftx is ERC721URIStorage {
    address payable private owner;
    GeneScience private _geneScience;
    Contributors private _contributors;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    struct NFTX {
        uint32 _genes;
        uint8 _generation;
    }

    mapping(uint256 => NFTX) tokens;

    mapping(uint8 => uint256) public cursors;

    uint16 private INITIAL_SUPPLY;
    uint8 public MAX_EVOL;

    bool private INITIALIZED;
    bool private IS_BLIND_AUCTION;

    uint256 public BLIND_AUCTION_STARTING_INDEX;

    uint256 private seed;

    modifier afterBlindAuction() {
        require(IS_BLIND_AUCTION == false, "Blind auction is not ended");
        _;
    }

    modifier initialSupplyIsCompatibleWithEvolutionSteps(
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

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier distributePayment() {
        _;
        _contributors.distributePayment(msg.value);
    }

    modifier canWithdraw() {
        require(_contributors.withdrawable(msg.sender) > 0);
        _;
    }

    modifier recordWithdraw(uint256 amount) {
        _;
        _contributors.recordWithdraw(msg.sender, amount);
    }

    constructor(
        uint256 seed_,
        uint16 initialSupply_,
        uint8 evolution_steps_count_,
        GeneScience geneScience_,
        Contributors contributors_
    )
        ERC721("EvolutionToken", "EVOT")
        initialSupplyIsCompatibleWithEvolutionSteps(
            initialSupply_,
            evolution_steps_count_
        )
    {
        owner = payable(msg.sender);
        _geneScience = geneScience_;
        _contributors = contributors_;
        INITIAL_SUPPLY = initialSupply_;
        IS_BLIND_AUCTION = true;
        INITIALIZED = false;
        MAX_EVOL = evolution_steps_count_;
        seed = seed_;
        generateCursors(evolution_steps_count_);
        INITIALIZED = true;
    }

    function generateToken(uint256 seed_) internal view returns (NFTX memory) {
        return NFTX(_geneScience.getNewDNA(seed_), 0);
    }

    function mergeTokens(
        NFTX memory token1,
        NFTX memory token2,
        NFTX memory token3
    ) private view returns (NFTX memory) {
        require(
            token1._generation == token2._generation &&
                token2._generation == token3._generation
        );
        return
            NFTX(
                _geneScience.mergeDNA(
                    token1._genes,
                    token1._genes,
                    token1._genes
                ),
                token1._generation + 1
            );
    }

    function generateCursors(uint8 evolution_steps_count_) private {
        require(
            INITIALIZED == false,
            "The contract has already been initialized"
        );

        cursors[0] = 0;
        cursors[1] = INITIAL_SUPPLY;

        for (uint8 i = 2; i <= evolution_steps_count_; i++) {
            cursors[i] = SafeMath.add(
                cursors[i - 1],
                SafeMath.div(SafeMath.sub(cursors[i - 1], cursors[i - 2]), 3)
            );
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

    function getCurrentTokenPrice() public view returns (uint256) {
        if (_tokenIds.current() <= INITIAL_SUPPLY / 4) {
            return 0.001 ether;
        } else if (_tokenIds.current() <= (2 * INITIAL_SUPPLY) / 4) {
            return 0.01 ether;
        } else if (_tokenIds.current() <= (3 * INITIAL_SUPPLY) / 4) {
            return 0.1 ether;
        } else {
            return 1 ether;
        }
    }

    function mintGen0Nft(uint8 numberOfToken_)
        external
        payable
        distributePayment
    {
        require(
            _tokenIds.current() + numberOfToken_ <= INITIAL_SUPPLY,
            "Initial offering is over"
        );
        require(numberOfToken_ <= 3);
        require(msg.value == getCurrentTokenPrice() * numberOfToken_);
        for (uint8 i = 0; i < numberOfToken_; i++) {
            _safeMint(msg.sender, _tokenIds.current());
            _tokenIds.increment();
            tokens[_tokenIds.current()] = generateToken(seed);
            if (_tokenIds.current() == INITIAL_SUPPLY - 1) {
                turnBlindAuctionOff();
            }
        }
    }

    function mintEvolution(
        uint256 token1Id_,
        uint256 token2Id_,
        uint256 token3Id_
    ) external {
        require(ownerOf(token1Id_) == msg.sender);
        require(ownerOf(token2Id_) == msg.sender);
        require(ownerOf(token3Id_) == msg.sender);
        NFTX memory token1 = getNft(token1Id_);
        NFTX memory token2 = getNft(token2Id_);
        NFTX memory token3 = getNft(token3Id_);
        require(token2._generation == token1._generation);
        require(token3._generation == token1._generation);
        require(token1._generation < MAX_EVOL);
        _safeMint(msg.sender, cursors[token1._generation + 1]);
        tokens[cursors[token1._generation]] = mergeTokens(
            token1,
            token2,
            token3
        );
        cursors[token1._generation] = cursors[token1._generation + 1] + 1;
        _burn(token1Id_);
        _burn(token2Id_);
        _burn(token3Id_);
    }

    function turnBlindAuctionOff() internal {
        BLIND_AUCTION_STARTING_INDEX = SafeMath.mod(
            block.number,
            INITIAL_SUPPLY
        );
        IS_BLIND_AUCTION = false;
    }

    function withDraw(uint256 amount)
        public
        canWithdraw
        recordWithdraw(amount)
    {
        require(amount <= address(this).balance);
        owner.transfer(amount);
    }
}
