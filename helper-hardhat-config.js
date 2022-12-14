const { ethers } = require("hardhat")

const networkConfig = {
    default: {
        name: "hardhat",
        keepersUpdateInterval: "30",
    },
    31337: {
        name: "localhost",
        subscriptionId: "588",
        gasLane: "0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc", // 30 gwei
        keepersUpdateInterval: "30",
        lotteryEntranceFee: ethers.utils.parseEther("0.01"), // 0.01 ETH
        callbackGasLimit: "500000", // 500,000 gas
    },
    5: {
        name: "goerli",
        subscriptionId: "7354",
        gasLane: "0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15", // 30 gwei
        keepersUpdateInterval: "30",
        lotteryEntranceFee: ethers.utils.parseEther("0.01"), // 0.01 ETH
        callbackGasLimit: "500000", // 500,000 gas
        vrfCoordinatorV2: "0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D",
    },
    // 1: {
    //     name: "mainnet",
    //     keepersUpdateInterval: "30",
    // },
    80001: {
        name: "mumbai",
        subscriptionId: "2805",
        gasLane: "0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f", // 500 gwei
        keepersUpdateInterval: "30",
        lotteryEntranceFee: ethers.utils.parseEther("0.00073"), // Approx. 1 MATIC
        callbackGasLimit: "500000", // 500,000 gas
        vrfCoordinatorV2:
            "https://mumbai.polygonscan.com/address/0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed",
    },
    137: {
        name: "polygon",
        subscriptionId: "6926",
        gasLane: "0x6e099d640cde6de9d40ac749b4b594126b0169747122711109c9985d47751f93", // 200 gwei
        keepersUpdateInterval: "30",
        lotteryEntranceFee: ethers.utils.parseEther("0.00073"), // Approx. 1 MATIC
        callbackGasLimit: "500000", // 500,000 gas
        vrfCoordinatorV2: "0xAE975071Be8F8eE67addBC1A82488F1C24858067",
    },
}

const developmentChains = ["hardhat", "localhost"]
const VERIFICATION_BLOCK_CONFIRMATIONS = 6
const frontEndContractsFile = "../nextjs-smartcontract-lottery-fcc/constants/contractAddresses.json"
const frontEndAbiFile = "../nextjs-smartcontract-lottery-fcc/constants/abi.json"

module.exports = {
    networkConfig,
    developmentChains,
    VERIFICATION_BLOCK_CONFIRMATIONS,
    frontEndContractsFile,
    frontEndAbiFile,
}
