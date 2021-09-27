import '@nomiclabs/hardhat-waffle';
import '@typechain/hardhat';
import 'hardhat-gas-reporter';
import * as dotenv from 'dotenv';

dotenv.config();

/**
 * @type import('hardhat/config').HardhatUserConfig
 */

export default {
  solidity: '0.8.3',
  gasReporter: {
    coinmarketcap: process.env.COINMARKETCAP_API_KEY,
  },
};
