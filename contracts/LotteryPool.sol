// Lottery Pool

// Enter the lottery pool (paying some amount)
// Pick a random winner (verifiably random)
// Winner to be selected every X seconds -> completely automated
// Chainlink Oracle -> Randomness, Automated execution (Chainlink UpKeeper)

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

error LotteryPool__NotEnoughETHEntered();
error LotteryPool__TransferFailed();
error LotteryPool__NotOpen();
error LotteryPool__UpkeepNotNeeded(
    uint256 currentBalance,
    uint256 numPlayers,
    uint256 lotteryPoolState
);

contract LotteryPool is VRFConsumerBaseV2, AutomationCompatibleInterface, ConfirmedOwner {
    using SafeMath for uint256;
    /* Type Declarations */
    enum LotteryPoolState {
        OPEN,
        CALCULATING
    } // uint256 0 = OPEN , 1 = CALCULATING

    /* Chainlink State variables */
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint8 private constant REQUEST_CONFIRMATIONS = 3;
    uint8 private constant NUM_WORDS = 1;

    /* Lottery Pool State variables */
    uint256 private s_interval;
    uint256 private s_lastTimeStamp;
    LotteryPoolState private s_lotteryPoolState;
    address payable[] private s_players;
    uint256 private s_entranceFee;
    address private s_recentWinner;
    uint8 private immutable i_withdrawPercentageForWinner;
    uint8 private immutable i_withdrawPercentageForOwner;

    /* Events */
    event PlayerEnteredToLotteryPool(address indexed player);
    event RequestedLotteryWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);
    event WithdrawnFund(address indexed someone, uint256 amount);

    constructor(
        address _vrfCoordinatorV2,
        uint256 _entranceFee,
        bytes32 _gasLane,
        uint64 _subscriptionId,
        uint32 _callbackGasLimit,
        uint256 _interval,
        uint8 _withdrawPercentageForWinner,
        uint8 _withdrawPercentageForOwner
    ) VRFConsumerBaseV2(_vrfCoordinatorV2) ConfirmedOwner(msg.sender) {
        s_entranceFee = _entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinatorV2);
        i_gasLane = _gasLane;
        i_subscriptionId = _subscriptionId;
        i_callbackGasLimit = _callbackGasLimit;
        s_lotteryPoolState = LotteryPoolState.OPEN;
        s_lastTimeStamp = block.timestamp;
        s_interval = _interval;
        i_withdrawPercentageForWinner = _withdrawPercentageForWinner;
        i_withdrawPercentageForOwner = _withdrawPercentageForOwner;
    }

    function enterLotteryPool() external payable {
        if (msg.value < s_entranceFee) {
            revert LotteryPool__NotEnoughETHEntered();
        }
        if (s_lotteryPoolState != LotteryPoolState.OPEN) {
            revert LotteryPool__NotOpen();
        }
        s_players.push(payable(msg.sender));

        emit PlayerEnteredToLotteryPool(msg.sender);
    }

    /**
     * @dev The following should be true in order to return true:
     * 1. Our time interval should have passed
     * 2. The lottery should have atleast 1 player, and have some ETH
     * 3. Our subscription is funded with LINK
     * 4. Lottery should be in "open" state
     */
    function checkUpkeep(
        bytes memory /* checkData */
    ) public override returns (bool upKeepNeeded, bytes memory /* performData */) {
        bool isOpen = (LotteryPoolState.OPEN == s_lotteryPoolState);
        bool timePassed = (block.timestamp - s_lastTimeStamp) > s_interval;
        bool hasPlayers = s_players.length > 0;
        bool hasBalance = address(this).balance > 0;
        upKeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance);
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert LotteryPool__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_lotteryPoolState)
            );
        }

        // Request random number
        s_lotteryPoolState = LotteryPoolState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, //gasLane
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        emit RequestedLotteryWinner(requestId);
    }

    function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] memory randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_lotteryPoolState = LotteryPoolState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        emit WinnerPicked(recentWinner);
        withdrawFund(
            recentWinner,
            address(this).balance.mul(i_withdrawPercentageForWinner).div(100)
        ); // ?% => Winner
        withdrawFund(
            payable(owner()),
            address(this).balance.mul(i_withdrawPercentageForOwner).div(100)
        ); // ?% => Owner
    }

    // Withdraw Fund For Specific Account from Contract
    function withdrawFund(address payable _to, uint _amount) private {
        (bool success, ) = _to.call{value: _amount}("");
        if (!success) {
            revert LotteryPool__TransferFailed();
        }
        emit WithdrawnFund(_to, _amount);
    }

    // Update EntranceFee by Owner
    function updateEntranceFee(uint _entranceFee) external onlyOwner {
        s_entranceFee = _entranceFee;
    }

    // Update Interval by Owner
    function updateInterval(uint _interval) external onlyOwner {
        s_interval = _interval;
    }

    /* View / Pure functions */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getEntranceFee() external view returns (uint256) {
        return s_entranceFee;
    }

    function getInterval() external view returns (uint256) {
        return s_interval;
    }

    function getPlayer(uint256 index) external view returns (address) {
        return s_players[index];
    }

    function getRecentWinner() external view returns (address) {
        return s_recentWinner;
    }

    function getLotteryPoolState() external view returns (LotteryPoolState) {
        return s_lotteryPoolState;
    }

    function getNumWords() external pure returns (uint256) {
        return NUM_WORDS;
    }

    function getNumberOfPlayers() external view returns (uint256) {
        return s_players.length;
    }

    function getLatestTimeStamp() external view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getRequestConfirmations() external pure returns (uint256) {
        return REQUEST_CONFIRMATIONS;
    }

    function getWithdrawPercentageForWinner() external view returns (uint256) {
        return i_withdrawPercentageForWinner;
    }

    function getWithdrawPercentageForOwner() external view returns (uint256) {
        return i_withdrawPercentageForOwner;
    }
}
