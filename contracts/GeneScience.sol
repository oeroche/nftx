pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract GeneScience {
    //TODO handle permissions
    uint8 constant NUMBER_OF_GENES = 10;
    uint8 constant GENES_BASE = 3;

    function getNewDNA(uint256 seed_) public view returns (uint256) {
        return
            uint256(keccak256(abi.encode(seed_))) %
            (10**(NUMBER_OF_GENES * GENES_BASE));
    }

    function getGeneSequences(uint256 dna)
        public
        view
        returns (uint16[10] memory)
    {
        uint16[10] memory sequence;
        uint256 dnaLeft = dna;
        for (uint8 k = 1; k <= NUMBER_OF_GENES; k++) {
            sequence[k - 1] = uint16(
                dnaLeft / (10**((NUMBER_OF_GENES - k) * GENES_BASE))
            );
            dnaLeft = dna % (10**((NUMBER_OF_GENES - k) * GENES_BASE));
        }
        return sequence;
    }

    function mergeGeneSequence(uint16[3] memory seqs_)
        private
        view
        returns (uint16)
    {
        bool seqFound;
        uint256 sum;
        uint256 count;
        for (uint8 k = 1; k < NUMBER_OF_GENES; k++) {
            for (uint8 j = 0; j < 3; j++) {
                if (seqs_[j] % 10**k == seqs_[j]) {
                    sum += seqs_[j];
                    count += 1;
                    seqFound = true;
                }
            }
            if (seqFound) {
                break;
            }
        }
        return uint16(sum / count);
    }

    function mergeDNA(uint256[3] memory dnas_) public view returns (uint256) {
        uint16[NUMBER_OF_GENES][3] memory sequences;
        uint256 result;

        for (uint8 k = 0; k < 3; k++) {
            sequences[k] = getGeneSequences(dnas_[k]);
        }

        for (uint8 j = 1; j <= NUMBER_OF_GENES; j++) {
            result +=
                mergeGeneSequence(
                    [
                        sequences[0][j - 1],
                        sequences[1][j - 1],
                        sequences[2][j - 1]
                    ]
                ) *
                10**((NUMBER_OF_GENES - j) * GENES_BASE);
        }

        return result;
    }
}
