// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title RewardTokenWrapperWithExpiry
 * @notice Adds expiry functionality to tokens.
 */
contract RewardTokenWrapperWithExpiry is ERC20 {
    IERC20 public rewardToken; // The token being wrapped
    address public retailer; // The retailer who owns the wrapper
    uint8 public custodyType; // Custody type (0 = custodial, 1 = non-custodial)

    string private _name; // Private variable for the token name
    string private _symbol; // Private variable for the token symbol

    struct TokenBatch {
        uint256 amount;
        uint256 expiresAt;
    }

    mapping(address => TokenBatch[]) public holdings;

    bool private initialized; // To prevent re-initialization

    /**
     * @notice Constructor for the implementation contract.
     */
    constructor() ERC20("", "") {}

    /**
     * @notice Initializes the wrapper contract.
     * @param _rewardToken The address of the token being wrapped.
     * @param _retailer The address of the retailer.
     * @param _custodyType The custody type of the token.
     * @param name_ The name of the token.
     * @param symbol_ The symbol of the token.
     */
    function initialize(
        address _rewardToken,
        address _retailer,
        uint8 _custodyType,
        string memory name_,
        string memory symbol_
    ) external {
        require(!initialized, "Already initialized");
        initialized = true;

        rewardToken = IERC20(_rewardToken);
        retailer = _retailer;
        custodyType = _custodyType;

        // Set the name and symbol
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @notice Wraps tokens with an expiry date.
     * @param to The address to wrap tokens for.
     * @param amount The amount of tokens to wrap.
     * @param expiresAt The expiry timestamp for the tokens.
     */
    function wrapWithExpiry(address to, uint256 amount, uint256 expiresAt) external {
        require(msg.sender == retailer, "Only retailer can wrap tokens");
        require(rewardToken.transferFrom(retailer, address(this), amount), "Transfer failed");

        holdings[to].push(TokenBatch({ amount: amount, expiresAt: expiresAt }));
        _mint(to, amount);
    }

    /**
     * @notice Reclaims expired tokens.
     * @param user The address of the user whose expired tokens are being reclaimed.
     */
    function reclaimExpired(address user) external {
        require(msg.sender == retailer, "Only retailer can reclaim");

        TokenBatch[] storage batches = holdings[user];
        uint256 reclaimed;

        for (uint256 i = 0; i < batches.length; i++) {
            if (batches[i].expiresAt <= block.timestamp && batches[i].amount > 0) {
                reclaimed += batches[i].amount;
                batches[i].amount = 0;
            }
        }

        if (reclaimed > 0) {
            _burn(user, reclaimed);
            rewardToken.transfer(retailer, reclaimed);
        }
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        require(getUnexpiredBalance(msg.sender) >= amount, "Insufficient unexpired balance");
        return super.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        require(getUnexpiredBalance(from) >= amount, "Insufficient unexpired balance");
        return super.transferFrom(from, to, amount);
    }

    /**
     * @notice Gets the unexpired balance of a user.
     * @param user The address of the user.
     * @return total The total unexpired balance.
     */
    function getUnexpiredBalance(address user) public view returns (uint256 total) {
        TokenBatch[] memory batches = holdings[user];
        for (uint256 i = 0; i < batches.length; i++) {
            if (batches[i].expiresAt > block.timestamp) {
                total += batches[i].amount;
            }
        }
    }

    /**
     * @notice Gets all token batches for a user.
     * @param user The address of the user.
     * @return An array of token batches.
     */
    function getBatches(address user) external view returns (TokenBatch[] memory) {
        return holdings[user];
    }

    /**
     * @notice Overrides the ERC20 name function to return the custom name.
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @notice Overrides the ERC20 symbol function to return the custom symbol.
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public pure override returns (uint8) {
        return 0;
    }
}