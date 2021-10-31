pragma solidity ^0.8.0;

contract GeneScience {
    //TODO handle permissions
    uint8 NUMBER_OF_GENES = 10;

    function getNewDNA(uint256 seed_) public view returns (uint32) {
        return
            uint32(
                uint256(keccak256(abi.encode(seed_))) % (10**NUMBER_OF_GENES)
            );
    }

    function mergeDNA(uint32[3] memory dnas_) public pure returns (uint32) {
        return (dnas_[0] + dnas_[1] + dnas_[2]) / 3;
    }
}
