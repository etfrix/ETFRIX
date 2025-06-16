// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFraudShield {
    function flag(address user, string memory reason) external;
}

interface IRewardLogic {
    function recordReward(address user, uint256 txAmount) external;
}

interface IRIXAI {
    function notifyTransaction(uint256 txId, address user, uint256 amount, string memory decisionHint) external;
}

contract SecureChain {
    enum TxStatus { Pending, Approved, Rejected }
    enum TxType { Investment, Withdrawal, Exchange }
    enum Currency { USDT, ETH, BTC, RIX }

    address public admin;
    uint256 public txCounter;
    uint256 public loginCounter;

    uint256 public dailyLimit = 100000 * 1e18;

    IFraudShield public fraudShield;
    IRewardLogic public rewardLogic;
    IRIXAI public rixAI;

    struct Transaction {
        address user;
        uint256 amount;
        uint256 timestamp;
        TxType txType;
        Currency currency;
        TxStatus status;
        string metadata;
    }

    struct LoginLog {
        address user;
        uint256 timestamp;
        string deviceId;
    }

    struct DailySpending {
        uint256 dateKey;
        uint256 totalAmount;
    }

    mapping(uint256 => Transaction) public transactions;
    mapping(uint256 => LoginLog) public loginLogs;
    mapping(address => DailySpending) public dailyUsage;
    mapping(address => bool) public rixRoles;

    event TransactionRegistered(uint256 indexed txId, address indexed user, uint256 amount, TxType txType, Currency currency);
    event TransactionStatusChanged(uint256 indexed txId, TxStatus newStatus);
    event UserLoginLogged(address indexed user, uint256 timestamp, string deviceId);
    event ExternalModuleLinked(string module, address contractAddress);
    event RIXModuleAdded(address module);
    event RIXModuleRemoved(address module);
    event DailyLimitExceeded(address user, uint256 attempted, uint256 limit);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Admin only");
        _;
    }

    modifier validTxId(uint256 txId) {
        require(txId > 0 && txId <= txCounter, "Invalid transaction ID");
        _;
    }

    modifier onlyRIX() {
        require(rixRoles[msg.sender], "Unauthorized module");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function addRIXModule(address module) external onlyAdmin {
        rixRoles[module] = true;
        emit RIXModuleAdded(module);
    }

    function removeRIXModule(address module) external onlyAdmin {
        rixRoles[module] = false;
        emit RIXModuleRemoved(module);
    }

    function setFraudShield(address fraudAddress) external onlyAdmin {
        fraudShield = IFraudShield(fraudAddress);
        emit ExternalModuleLinked("FraudShield", fraudAddress);
    }

    function setRewardLogic(address rewardAddress) external onlyAdmin {
        rewardLogic = IRewardLogic(rewardAddress);
        emit ExternalModuleLinked("RewardLogic", rewardAddress);
    }

    function setRIXAI(address aiAddress) external onlyAdmin {
        rixAI = IRIXAI(aiAddress);
        emit ExternalModuleLinked("RIXAI", aiAddress);
    }

    function registerTransaction(
        address user,
        uint256 amount,
        TxType txType,
        Currency currency,
        string memory metadata
    ) external returns (uint256) {
        require(amount > 0, "Zero amount");

        uint256 today = block.timestamp / 1 days;
        DailySpending storage daily = dailyUsage[user];

        if (daily.dateKey != today) {
            daily.dateKey = today;
            daily.totalAmount = 0;
        }

        daily.totalAmount += amount;
        if (daily.totalAmount > dailyLimit) {
            if (address(fraudShield) != address(0)) {
                fraudShield.flag(user, "Exceeded daily limit");
            }
            emit DailyLimitExceeded(user, amount, dailyLimit);
        }

        txCounter++;
        transactions[txCounter] = Transaction({
            user: user,
            amount: amount,
            timestamp: block.timestamp,
            txType: txType,
            currency: currency,
            status: TxStatus.Pending,
            metadata: metadata
        });

        emit TransactionRegistered(txCounter, user, amount, txType, currency);

        _autoNotifyRIX(txCounter, user, amount);
        return txCounter;
    }

    function _autoNotifyRIX(uint256 txId, address user, uint256 amount) internal {
        if (address(rixAI) != address(0)) {
            string memory hint = amount > 1000 ether ? "high" : "normal";
            rixAI.notifyTransaction(txId, user, amount, hint);
        }
    }

    function changeTransactionStatus(uint256 txId, TxStatus newStatus, string memory reason) external onlyAdmin validTxId(txId) {
        Transaction storage txObj = transactions[txId];
        txObj.status = newStatus;
        emit TransactionStatusChanged(txId, newStatus);

        if (newStatus == TxStatus.Approved && address(rewardLogic) != address(0)) {
            rewardLogic.recordReward(txObj.user, txObj.amount);
        }

        if (newStatus == TxStatus.Rejected && address(fraudShield) != address(0)) {
            fraudShield.flag(txObj.user, reason);
        }
    }

    function logUserLogin(address user, string memory deviceId) public {
        loginCounter++;
        loginLogs[loginCounter] = LoginLog({
            user: user,
            timestamp: block.timestamp,
            deviceId: deviceId
        });
        emit UserLoginLogged(user, block.timestamp, deviceId);
    }

    function getTransactionSummary(uint256 txId) public view validTxId(txId) returns (
        address user,
        uint256 amount,
        TxType txType,
        Currency currency,
        TxStatus status,
        string memory metadata
    ) {
        Transaction storage tx = transactions[txId];
        return (tx.user, tx.amount, tx.txType, tx.currency, tx.status, tx.metadata);
    }
}