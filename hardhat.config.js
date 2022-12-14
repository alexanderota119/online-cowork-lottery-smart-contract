require("@nomiclabs/hardhat-waffle")
require("@nomiclabs/hardhat-etherscan")
require("hardhat-deploy")
require("solidity-coverage")
require("hardhat-gas-reporter")
require("hardhat-contract-sizer")
require("dotenv").config()

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
const PRIVATE_KEY = process.env.PRIVATE_KEY || "your private key"
const MNEMONIC = process.env.MNEMONIC || "your mnemonic"

const MAINNET_RPC_URL =
    process.env.MAINNET_RPC_URL || "https://eth-mainnet.alchemyapi.io/v2/your-api-key"
const GOERLI_RPC_URL =
    process.env.GOERLI_RPC_URL || "https://eth-goerli.g.alchemy.com/v2/your-api-key"
const POLYGON_MAINNET_RPC_URL =
    process.env.POLYGON_MAINNET_RPC_URL || "https://polygon-mainnet.alchemyapi.io/v2/your-api-key"
const POLYGON_MUMBAI_RPC_URL =
    process.env.POLYGON_MUMBAI_RPC_URL || "https://polygon-mumbai.g.alchemy.com/v2/your-api-key"

const REPORT_GAS = process.env.REPORT_GAS

const accounts =
    typeof PRIVATE_KEY !== "undefined"
        ? [PRIVATE_KEY]
        : typeof MNEMONIC !== "undefined"
        ? { mnemonic: MNEMONIC }
        : []

module.exports = {
    defaultNetwork: "mumbai",
    networks: {
        localhost: {
            url: "http://127.0.0.1:8545",
        },
        hardhat: {
            // // If you want to do some forking, uncomment this
            // forking: {
            //   url: MAINNET_RPC_URL
            // }
            chainId: 31337,
        },
        goerli: {
            url: GOERLI_RPC_URL,
            accounts,
            saveDeployments: true,
            chainId: 5,
        },
        mainnet: {
            url: MAINNET_RPC_URL,
            accounts,
            saveDeployments: true,
            chainId: 1,
        },
        polygon: {
            url: POLYGON_MAINNET_RPC_URL,
            accounts,
            saveDeployments: true,
            chainId: 137,
        },
        mumbai: {
            url: POLYGON_MUMBAI_RPC_URL,
            accounts,
            saveDeployments: true,
            chainId: 80001,
        },
    },
    solidity: {
        version: "0.8.7",
        settings: {
            optimizer: {
                enabled: true,
                runs: 1000,
            },
        },
    },
    gasReporter: {
        enabled: REPORT_GAS,
        currency: "USD",
        outputFile: "gas-report.txt",
        noColors: true,
        coinmarketcap: process.env.COINMARKETCAP_API_KEY,
    },
    contractSizer: {
        runOnCompile: false,
        only: ["Lottery"],
    },
    namedAccounts: {
        deployer: {
            default: 0, // here this will by default take the first account as deployer
            1: 0, // similarly on mainnet it will take the first account as deployer. Note though that depending on how hardhat network are configured, the account 0 on one network can be different than on another
        },
        player: {
            default: 1,
        },
    },
    mocha: {
        timeout: 500000, // 500 seconds max for running tests
    },
}
