// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title RewardTokenCustodial
 * @notice A token contract where the retailer has full custody of the tokens.
 */
contract RewardTokenCustodial is ERC20 {
    address public owner;
    address public registry;

    uint256 public tokenValue;
    string public currency;

    uint8 public constant custodyType = 0; // Custodial token type
    
    string private _name; // Private variable for the token name
    string private _symbol; // Private variable for the token symbol

    bool private initialized; // To prevent re-initialization

    /**
     * @notice Constructor for the implementation contract.
     */
    constructor() ERC20("", "") {}

    /**
     * @notice Initializes the custodial token.
     * @param _retailer The address of the retailer.
     * @param _tokenValue The value of the token.
     * @param initialSupply The initial supply of the token.
     * @param _currency The currency symbol for the token.
     * @param name_ The name of the token.
     * @param symbol_ The symbol of the token.
     */
    function initialize(
        address _retailer,
        uint256 _tokenValue,
        uint256 initialSupply,
        string memory _currency,
        string memory name_,
        string memory symbol_
    ) external {
        require(!initialized, "Already initialized");
        initialized = true;

        owner = _retailer;
        registry = msg.sender;
        tokenValue = _tokenValue;
        currency = _currency;

        // Set the name and symbol
        _name = name_;
        _symbol = symbol_;

        _mint(_retailer, initialSupply); // Mint initial supply to retailer
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

    /**
     * @notice Mints new tokens.
     * @param to The address to mint tokens to.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint256 amount) external {
        require(msg.sender == owner, "Only retailer can mint");
        _mint(to, amount);
    }
}