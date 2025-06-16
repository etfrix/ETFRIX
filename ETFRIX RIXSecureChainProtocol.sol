// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title RIXSecureChainProtocol - Core Safety Layer for ETFRIX Funds & Transfers
/// @notice Provides secure fund management, freezing mechanisms, and movement validation

contract RIXSecureChainProtocol {
    address public admin;
    mapping(address => bool) public trustedModules;
    mapping(address => bool) public frozenAccounts;
    mapping(address => uint256) public balances;

    event TrustedModuleAdded(address indexed module);
    event TrustedModuleRemoved(address indexed module);
    event AccountFrozen(address indexed user);
    event AccountUnfrozen(address indexed user);
    event FundsDeposited(address indexed user, uint256 amount);
    event FundsWithdrawn(address indexed user, uint256 amount);
    event FundsTransferred(address indexed from, address indexed to, uint256 amount);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Admin only");
        _;
    }

    modifier onlyTrusted() {
        require(trustedModules[msg.sender] || msg.sender == admin, "Not trusted");
        _;
    }

    modifier notFrozen(address user) {
        require(!frozenAccounts[user], "Account is frozen");
        _;
    }

    constructor() {
        admin = msg.sender;
        trustedModules[msg.sender] = true;
    }

    function addTrustedModule(address module) external onlyAdmin {
        trustedModules[module] = true;
        emit TrustedModuleAdded(module);
    }

    function removeTrustedModule(address module) external onlyAdmin {
        trustedModules[module] = false;
        emit TrustedModuleRemoved(module);
    }

    function freezeAccount(address user) external onlyAdmin {
        frozenAccounts[user] = true;
        emit AccountFrozen(user);
    }

    function unfreezeAccount(address user) external onlyAdmin {
        frozenAccounts[user] = false;
        emit AccountUnfrozen(user);
    }

    function deposit() external payable notFrozen(msg.sender) {
        balances[msg.sender] += msg.value;
        emit FundsDeposited(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external notFrozen(msg.sender) {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit FundsWithdrawn(msg.sender, amount);
    }

    function transferTo(address to, uint256 amount) external notFrozen(msg.sender) notFrozen(to) {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        balances[to] += amount;
        emit FundsTransferred(msg.sender, to, amount);
    }

    function trustedTransfer(address from, address to, uint256 amount) external onlyTrusted notFrozen(from) notFrozen(to) {
        require(balances[from] >= amount, "Insufficient balance");
        balances[from] -= amount;
        balances[to] += amount;
        emit FundsTransferred(from, to, amount);
    }

    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }

    function isFrozen(address user) external view returns (bool) {
        return frozenAccounts[user];
    }

    function isTrusted(address module) external view returns (bool) {
        return trustedModules[module];
    }
}