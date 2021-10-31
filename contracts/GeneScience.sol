pragma solidity ^0.8.0;

contract GeneScience {
    uint8 NUMBER_OF_GENES = 10;
    uint256 MODULUS = 10**NUMBER_OF_GENES;

    constructor() {}

    function getNewDNA(uint256 seed_) public view returns (uint32) {
        return uint32(uint256(keccak256(abi.encode(seed_))) % MODULUS);
    }

    function mergeDNA(
        uint32 dna1,
        uint32 dna2,
        uint32 dna3
    ) public pure returns (uint32) {
        return (dna1 + dna2 + dna3) / 3;
    }
}
