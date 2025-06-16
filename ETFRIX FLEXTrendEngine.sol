// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title FLEXTrendEngine - On-chain Market Signal Provider for ETFRIX
/// @notice Stores and publishes trend signals from authorized market data sources

contract FLEXTrendEngine {
    address public admin;

    struct TrendSignal {
        uint256 timestamp;
        string asset;       // e.g., "BTC/USDT", "ETH/USDT"
        string signalType;  // e.g., "bullish", "bearish", "neutral"
        uint256 strength;   // e.g., 0–1000
        string source;      // e.g., "oracle1", "model-v3"
    }

    mapping(string => TrendSignal[]) public assetTrendHistory;
    mapping(address => bool) public signalProviders;

    event SignalSubmitted(string indexed asset, string signalType, uint256 strength, string source);
    event ProviderAuthorized(address indexed provider);
    event ProviderRevoked(address indexed provider);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Admin only");
        _;
    }

    modifier onlyProvider() {
        require(signalProviders[msg.sender], "Not authorized");
        _;
    }

    constructor() {
        admin = msg.sender;
        signalProviders[msg.sender] = true;
    }

    function authorizeProvider(address provider) external onlyAdmin {
        signalProviders[provider] = true;
        emit ProviderAuthorized(provider);
    }

    function revokeProvider(address provider) external onlyAdmin {
        signalProviders[provider] = false;
        emit ProviderRevoked(provider);
    }

    function submitTrendSignal(
        string memory asset,
        string memory signalType,
        uint256 strength,
        string memory source
    ) public onlyProvider {
        require(bytes(asset).length > 0, "Asset required");
        require(strength <= 1000, "Strength out of range");

        TrendSignal memory signal = TrendSignal({
            timestamp: block.timestamp,
            asset: asset,
            signalType: signalType,
            strength: strength,
            source: source
        });

        assetTrendHistory[asset].push(signal);
        emit SignalSubmitted(asset, signalType, strength, source);
    }

    function getLatestSignal(string memory asset) public view returns (
        string memory signalType,
        uint256 strength,
        string memory source,
        uint256 timestamp
    ) {
        TrendSignal[] storage history = assetTrendHistory[asset];
        require(history.length > 0, "No signal found");
        TrendSignal storage latest = history[history.length - 1];
        return (latest.signalType, latest.strength, latest.source, latest.timestamp);
    }

    function getSignalHistory(string memory asset) public view returns (TrendSignal[] memory) {
        return assetTrendHistory[asset];
    }

    function isProvider(address account) public view returns (bool) {
        return signalProviders[account];
    }
}