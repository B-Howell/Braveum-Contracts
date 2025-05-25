// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./RewardTokenCustodial.sol";
import "./RewardTokenNonCustodial.sol";
import "./RewardTokenWrapperWithExpiry.sol";

/**
 * @title RewardTokenFactory
 * @notice Deploys custodial and non-custodial tokens and optional wrappers for expiry functionality.
 */
interface IRewardTokenRegistry {
    function isRetailerVerified(address retailer) external view returns (bool);
    function getMaxTokensForRetailer(address retailer) external view returns (uint256);
}

interface IRewardToken {
    function custodyType() external view returns (uint8);
}

contract RewardTokenFactory {
    IRewardTokenRegistry public registry;

    address public custodialTemplate;
    address public nonCustodialTemplate;
    address public wrapperTemplate;

    /**
     * @dev Emitted when a token is deployed.
     */
    event TokenDeployed(address indexed retailer, address tokenAddress, uint8 custodyType);

    /**
     * @dev Emitted when a wrapper is deployed.
     */
    event WrapperDeployed(address indexed retailer, address wrapperAddress);

    // Mapping to track tokens deployed for each retailer
    mapping(address => address[]) public retailerTokens;

    // Mapping from token address to wrapper address
    mapping(address => address) public tokenToWrapper;

    // Array to track all deployed reward tokens
    address[] public allRewardTokens;

    // Array to track all deployed wrappers
    address[] public allWrappers;

    constructor(
        address _registry,
        address _custodialTemplate,
        address _nonCustodialTemplate,
        address _wrapperTemplate
    ) {
        registry = IRewardTokenRegistry(_registry);
        custodialTemplate = _custodialTemplate;
        nonCustodialTemplate = _nonCustodialTemplate;
        wrapperTemplate = _wrapperTemplate;
    }

    /**
     * @notice Deploys a custodial or non-custodial token for a verified retailer.
     * @param retailer The address of the retailer.
     * @param tokenValue The value of the token.
     * @param initialSupply The initial supply of the token (only for custodial tokens).
     * @param currency The currency symbol for the token.
     * @param name Name of the token.
     * @param symbol Symbol of the token.
     * @param custodyType The type of custody (0 = custodial, 1 = non-custodial).
     * @return tokenAddress The address of the deployed token.
     */
    function createToken(
        address retailer,
        uint256 tokenValue,
        uint256 initialSupply,
        string memory currency,
        string memory name,
        string memory symbol,
        uint8 custodyType
    ) external returns (address tokenAddress) {
        require(registry.isRetailerVerified(retailer), "Retailer not verified");

        // Enforce token limit per retailer
        require(
            retailerTokens[retailer].length < registry.getMaxTokensForRetailer(retailer),
            "Token limit reached"
        );

        if (custodyType == 0) {
            tokenAddress = Clones.clone(custodialTemplate);
            RewardTokenCustodial(tokenAddress).initialize(
                retailer,
                tokenValue,
                initialSupply,
                currency,
                name,
                symbol
            );
        } else if (custodyType == 1) {
            tokenAddress = Clones.clone(nonCustodialTemplate);
            RewardTokenNonCustodial(tokenAddress).initialize(
                retailer,
                tokenValue,
                currency,
                name,
                symbol
            );
        } else {
            revert("Invalid custody type");
        }

        // Track the deployed token
        retailerTokens[retailer].push(tokenAddress);
        allRewardTokens.push(tokenAddress);

        emit TokenDeployed(retailer, tokenAddress, custodyType);
        return tokenAddress;
    }

    /**
     * @notice Deploys a wrapper contract for an existing token (if not already wrapped).
     * @param retailer The retailer address.
     * @param tokenAddress The token to wrap.
     * @param name Name of the wrapped token.
     * @param symbol Symbol of the wrapped token.
     * @return wrapperAddress The address of the deployed wrapper.
     */
    function createWrapper(
        address retailer,
        address tokenAddress,
        string memory name,
        string memory symbol
    ) external returns (address wrapperAddress) {
        require(registry.isRetailerVerified(retailer), "Retailer not verified");
        require(tokenToWrapper[tokenAddress] == address(0), "Wrapper already exists for this token");

        uint8 custodyType = IRewardToken(tokenAddress).custodyType();

        wrapperAddress = Clones.clone(wrapperTemplate);
        RewardTokenWrapperWithExpiry(wrapperAddress).initialize(
            tokenAddress,
            retailer,
            custodyType,
            name,
            symbol
        );

        tokenToWrapper[tokenAddress] = wrapperAddress;
        allWrappers.push(wrapperAddress);

        emit WrapperDeployed(retailer, wrapperAddress);
        return wrapperAddress;
    }

    /**
     * @notice Retrieves all tokens deployed for a specific retailer.
     * @param retailer The address of the retailer.
     * @return An array of token addresses deployed for the retailer.
     */
    function getTokensByRetailer(address retailer) external view returns (address[] memory) {
        return retailerTokens[retailer];
    }

    function getWrapperForToken(address token) external view returns (address) {
        return tokenToWrapper[token];
    }

    function getAllRewardTokens() external view returns (address[] memory) {
        return allRewardTokens;
    }

    function getAllWrappers() external view returns (address[] memory) {
        return allWrappers;
    }
}
