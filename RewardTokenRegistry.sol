// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title RewardTokenRegistry
 * @notice Manages the verification and application process for retailers, including per-retailer token creation limits.
 */

contract RewardTokenRegistry {
    address public immutable owner;

    // ===== Retailer List & Status =====
    address[] public retailerList; // All who ever applied
    mapping(address => bool) public verifiedRetailers; // true = verified, false = pending/not verified
    mapping(address => bool) public hasApplied; // to avoid duplicates

    // ===== Admin Config/Limits =====
    mapping(address => uint256) public maxTokensPerRetailer;
    uint256 public defaultMaxTokensPerRetailer = 1;

    // ===== Events =====
    event RetailerApprovalRequested(address indexed retailer);
    event RetailerVerified(address indexed retailer);
    event MaxTokensPerRetailerSet(address indexed retailer, uint256 limit);

    // ===== Modifiers =====
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    // ===== Constructor =====
    constructor() {
        owner = msg.sender;
    }

    // ===== Retailer Application Functions =====

    /**
     * @notice Allows a retailer to request approval for verification.
     */
    function requestApproval() external {
        require(!verifiedRetailers[msg.sender], "Already verified");
        require(!hasApplied[msg.sender], "Already applied");

        retailerList.push(msg.sender);
        hasApplied[msg.sender] = true;
        // Not verified until admin approves

        emit RetailerApprovalRequested(msg.sender);
    }

    /**
     * @notice Returns the list of all retailer addresses (pending + verified).
     */
    function getAllRetailers() external view returns (address[] memory) {
        return retailerList;
    }

    // ===== Retailer Verification Functions =====

    /**
     * @notice Verifies a retailer.
     * @param retailer The address of the retailer to verify.
     */
    function verifyRetailer(address retailer) external onlyOwner {
        require(hasApplied[retailer], "Retailer never applied");
        require(!verifiedRetailers[retailer], "Already verified");
        verifiedRetailers[retailer] = true;

        emit RetailerVerified(retailer);
    }

    /**
     * @notice Checks if a retailer is verified.
     * @param retailer The address of the retailer.
     * @return True if the retailer is verified, false otherwise.
     */
    function isRetailerVerified(address retailer) external view returns (bool) {
        return verifiedRetailers[retailer];
    }

    /**
     * @notice Returns the list of all verified retailers.
     */
    function getAllVerifiedRetailers() external view returns (address[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < retailerList.length; i++) {
            if (verifiedRetailers[retailerList[i]]) {
                count++;
            }
        }
        address[] memory verified = new address[](count);
        uint256 j = 0;
        for (uint256 i = 0; i < retailerList.length; i++) {
            if (verifiedRetailers[retailerList[i]]) {
                verified[j] = retailerList[i];
                j++;
            }
        }
        return verified;
    }

    /**
     * @notice Returns the list of all pending retailers.
     */
    function getAllPendingRetailers() external view returns (address[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < retailerList.length; i++) {
            if (!verifiedRetailers[retailerList[i]]) {
                count++;
            }
        }
        address[] memory pending = new address[](count);
        uint256 j = 0;
        for (uint256 i = 0; i < retailerList.length; i++) {
            if (!verifiedRetailers[retailerList[i]]) {
                pending[j] = retailerList[i];
                j++;
            }
        }
        return pending;
    }

    // ===== Admin/Config Functions =====

    function setMaxTokensForRetailer(address retailer, uint256 limit) external onlyOwner {
        maxTokensPerRetailer[retailer] = limit;
        emit MaxTokensPerRetailerSet(retailer, limit);
    }

    function getMaxTokensForRetailer(address retailer) public view returns (uint256) {
        uint256 custom = maxTokensPerRetailer[retailer];
        return custom > 0 ? custom : defaultMaxTokensPerRetailer;
    }
}
