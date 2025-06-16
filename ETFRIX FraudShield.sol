// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title FraudShield - Behavioral Analysis & Alert System for ETFRIX
/// @notice Monitors and flags suspicious activities and provides complaint submission and audit logs.

contract FraudShield {
    address public admin;

    struct FlagRecord {
        uint256 timestamp;
        string reason;
        string context;
        address flaggedBy;
    }

    struct Complaint {
        uint256 timestamp;
        address complainer;
        string category;
        string message;
    }

    mapping(address => bool) public isFlagged;
    mapping(address => FlagRecord[]) public flagHistory;
    mapping(address => Complaint[]) public complaints;
    mapping(address => bool) public moderators;
    mapping(address => bool) public blacklisted;

    event UserFlagged(address indexed user, string reason, string context);
    event UserCleared(address indexed user);
    event ComplaintFiled(address indexed target, address indexed complainer, string category);
    event BlacklistUpdated(address indexed user, bool isBlacklisted);
    event ModeratorAdded(address indexed moderator);
    event ModeratorRemoved(address indexed moderator);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    modifier onlyModerator() {
        require(moderators[msg.sender] || msg.sender == admin, "Not authorized");
        _;
    }

    constructor() {
        admin = msg.sender;
        moderators[msg.sender] = true;
    }

    function flagUser(address user, string memory reason, string memory context) public onlyModerator {
        isFlagged[user] = true;
        flagHistory[user].push(FlagRecord({
            timestamp: block.timestamp,
            reason: reason,
            context: context,
            flaggedBy: msg.sender
        }));
        emit UserFlagged(user, reason, context);
    }

    function clearFlag(address user) public onlyModerator {
        isFlagged[user] = false;
        emit UserCleared(user);
    }

    function submitComplaint(address target, string memory category, string memory message) public {
        complaints[target].push(Complaint({
            timestamp: block.timestamp,
            complainer: msg.sender,
            category: category,
            message: message
        }));
        emit ComplaintFiled(target, msg.sender, category);
    }

    function addModerator(address mod) public onlyAdmin {
        moderators[mod] = true;
        emit ModeratorAdded(mod);
    }

    function removeModerator(address mod) public onlyAdmin {
        moderators[mod] = false;
        emit ModeratorRemoved(mod);
    }

    function blacklist(address user) public onlyAdmin {
        blacklisted[user] = true;
        emit BlacklistUpdated(user, true);
    }

    function unblacklist(address user) public onlyAdmin {
        blacklisted[user] = false;
        emit BlacklistUpdated(user, false);
    }

    function getFlagHistory(address user) public view returns (FlagRecord[] memory) {
        return flagHistory[user];
    }

    function getComplaints(address user) public view returns (Complaint[] memory) {
        return complaints[user];
    }

    function isBlacklisted(address user) public view returns (bool) {
        return blacklisted[user];
    }

    function isModerator(address mod) public view returns (bool) {
        return moderators[mod];
    }
}