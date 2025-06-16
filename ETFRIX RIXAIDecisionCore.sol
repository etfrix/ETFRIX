// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title RIXAIDecisionCore - Smart Logic Hub for ETFRIX AI Decision System
/// @notice Receives transaction signals and provides AI-based investment suggestions.

contract RIXAIDecisionCore {
    address public admin;

    struct Decision {
        uint256 timestamp;
        address user;
        uint256 inputTxId;
        string signalType; // e.g. "buy", "sell", "hold"
        string strategyUsed;
        uint256 confidence; // 0–1000 = 0.0%–100.0%
        string explanation;
    }

    struct Strategy {
        string label;
        string description;
        bool enabled;
    }

    mapping(string => Strategy) public strategies;
    string[] public availableStrategies;

    mapping(address => Decision[]) public userDecisions;
    mapping(uint256 => Decision) public txDecisionMap;

    event StrategyAdded(string label);
    event StrategyToggled(string label, bool enabled);
    event DecisionGenerated(address indexed user, uint256 txId, string strategy, string signal);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    constructor() {
        admin = msg.sender;

        _addStrategy("default", "Base line model with moving averages");
        _addStrategy("ai-v2", "Improved AI using on-chain and off-chain metrics");
        _addStrategy("trend-burst", "High-volatility trend pattern logic");
    }

    function _addStrategy(string memory label, string memory description) internal {
        strategies[label] = Strategy(label, description, true);
        availableStrategies.push(label);
        emit StrategyAdded(label);
    }

    function toggleStrategy(string memory label, bool state) public onlyAdmin {
        require(bytes(label).length > 0, "Invalid label");
        strategies[label].enabled = state;
        emit StrategyToggled(label, state);
    }

    function processTransactionSignal(
        uint256 txId,
        address user,
        string memory strategy,
        string memory signalType,
        uint256 confidence,
        string memory explanation
    ) external onlyAdmin {
        require(strategies[strategy].enabled, "Strategy not enabled");

        Decision memory decision = Decision({
            timestamp: block.timestamp,
            user: user,
            inputTxId: txId,
            signalType: signalType,
            strategyUsed: strategy,
            confidence: confidence,
            explanation: explanation
        });

        userDecisions[user].push(decision);
        txDecisionMap[txId] = decision;

        emit DecisionGenerated(user, txId, strategy, signalType);
    }

    function getUserDecisions(address user) public view returns (Decision[] memory) {
        return userDecisions[user];
    }

    function getDecisionForTx(uint256 txId) public view returns (Decision memory) {
        return txDecisionMap[txId];
    }

    function listStrategies() public view returns (string[] memory) {
        return availableStrategies;
    }

    function getStrategy(string memory label) public view returns (string memory description, bool enabled) {
        Strategy memory s = strategies[label];
        return (s.description, s.enabled);
    }
}