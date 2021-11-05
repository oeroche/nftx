import { BigNumber } from "@ethersproject/bignumber";
import { keccak256 } from "js-sha3";
import chai, { expect } from "chai";
import { ethers } from "hardhat";
import { GeneScience, GeneScience__factory } from "../typechain";

describe("GeneScience Contract", () => {
  let geneScienceFactory: GeneScience__factory;
  let geneScienceContract: GeneScience;
  before(async () => {
    geneScienceFactory = await ethers.getContractFactory("GeneScience");
    geneScienceContract = await geneScienceFactory.deploy();
  });

  describe("getGeneSequences", () => {
    it("should return a dna sequence", async () => {
      const dna = "12345678901234567891234567890";
      const expectation = dna
        .toString()
        .split("")
        .reduce<string[]>(
          (acc, value, k, arr) => {
            const result = acc;
            if ((arr.length - k) % 3 === 0) {
              result.push("");
            }
            result[result.length - 1] += value;
            return result;
          },
          [""]
        )
        .map((v) => "" + parseInt(v, 10));

      const result = await geneScienceContract.getGeneSequences(dna);
      const resultStr = result.map((s) => s.toString());

      expect(resultStr).to.deep.equal(expectation);
    });
  });

  describe("mergeDNA", () => {
    it("should be symetric", async () => {
      const p0 = "1287923009879833";
      const p1 = "29803984089432984";
      const p2 = "19082098430498320";
      expect(await geneScienceContract.mergeDNA([p0, p1, p2]))
        .to.equal(await geneScienceContract.mergeDNA([p1, p0, p2]))
        .to.equal(await geneScienceContract.mergeDNA([p2, p1, p0]));
    });

    it("should not return simple average of dnas", async () => {
      const p0 = 11001;
      const p1 = 110011;
      const p2 = 15003;
      const result = await geneScienceContract.mergeDNA([p0, p1, p2]);
      expect(result.toNumber()).not.to.equal(Math.floor((p0 + p1 + p2) / 3));
      expect(result.toNumber()).to.equal(Math.floor(13002));
    });
    it("should retain higher priority sequence", async () => {
      const p0 = 1;
      const p1 = 11;
      const p2 = 111;

      const result = await geneScienceContract.mergeDNA([p0, p1, p2]);
      expect(result.toNumber()).to.equal(p0);
    });

    it("should average higher priority sequences", async () => {
      const p0 = 1;
      const p1 = 3;
      const p2 = 11;

      const result = await geneScienceContract.mergeDNA([p0, p1, p2]);
      expect(result.toNumber()).to.equal(Math.floor((p0 + p1) / 2));
    });
  });
});
