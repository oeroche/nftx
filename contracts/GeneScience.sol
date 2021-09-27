pragma solidity ^0.8.0;

contract GeneScience {
    constructor() {}

    function getNewDNA(string memory seed_) public pure returns (uint32) {
        return uint32(uint256(keccak256(abi.encode(seed_))));
    }

    function mergeDNA(
        uint32 dna1,
        uint32 dna2,
        uint32 dna3
    ) public pure returns (uint32) {
        return (dna1 + dna2 + dna3) / 3;
    }
}
