// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RewardLogic {
    enum Currency { USDT, ETH, BTC, RIX }

    struct Reward {
        uint256 timestamp;
        Currency currency;
        uint256 amount;
        string source; // e.g. "referral", "roulette", "event"
    }

    struct Level {
        string label;
        uint8 tier; // for sorting logic
    }

    struct UserLevel {
        string currentLevel;
        string[] levelHistory;
    }

    address public admin;
    mapping(address => Reward[]) public rewardHistory;
    mapping(address => UserLevel) public userLevels;
    mapping(string => Level) public levelDefinitions;
    mapping(address => mapping(Currency => uint256)) public totalRewardsByCurrency;

    event RewardGranted(address indexed user, Currency currency, uint256 amount, string source);
    event LevelUp(address indexed user, string newLevel);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    constructor() {
        admin = msg.sender;

        // Predefined levels (L1-L7, S1-S5, V1-V2)
        _defineLevel("L1", 1);
        _defineLevel("L2", 2);
        _defineLevel("L3", 3);
        _defineLevel("L4", 4);
        _defineLevel("L5", 5);
        _defineLevel("L6", 6);
        _defineLevel("L7", 7);

        _defineLevel("S1", 10);
        _defineLevel("S2", 11);
        _defineLevel("S3", 12);
        _defineLevel("S4", 13);
        _defineLevel("S5", 14);
        _defineLevel("V1", 20);
        _defineLevel("V2", 21);
    }

    function _defineLevel(string memory label, uint8 tier) internal {
        levelDefinitions[label] = Level(label, tier);
    }

    function grantReward(
        address user,
        Currency currency,
        uint256 amount,
        string memory source
    ) external onlyAdmin {
        rewardHistory[user].push(Reward({
            timestamp: block.timestamp,
            currency: currency,
            amount: amount,
            source: source
        }));

        totalRewardsByCurrency[user][currency] += amount;

        emit RewardGranted(user, currency, amount, source);
    }

    function updateUserLevel(address user, string memory newLevel) external onlyAdmin {
        require(bytes(newLevel).length > 0, "Invalid level");
        userLevels[user].currentLevel = newLevel;
        userLevels[user].levelHistory.push(newLevel);
        emit LevelUp(user, newLevel);
    }

    function autoEvaluateLevel(address user, uint totalReferrals) external onlyAdmin {
        string memory level;

        if (totalReferrals >= 100) level = "V2";
        else if (totalReferrals >= 75) level = "V1";
        else if (totalReferrals >= 60) level = "S5";
        else if (totalReferrals >= 45) level = "S4";
        else if (totalReferrals >= 30) level = "S3";
        else if (totalReferrals >= 20) level = "S2";
        else if (totalReferrals >= 10) level = "S1";
        else if (totalReferrals >= 7) level = "L7";
        else if (totalReferrals >= 6) level = "L6";
        else if (totalReferrals >= 5) level = "L5";
        else if (totalReferrals >= 4) level = "L4";
        else if (totalReferrals >= 3) level = "L3";
        else if (totalReferrals >= 2) level = "L2";
        else level = "L1";

        updateUserLevel(user, level);
    }

    function getUserRewards(address user) external view returns (Reward[] memory) {
        return rewardHistory[user];
    }

    function getUserLevel(address user) external view returns (string memory current, string[] memory history) {
        return (userLevels[user].currentLevel, userLevels[user].levelHistory);
    }
}