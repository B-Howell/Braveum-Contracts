# Braveum Reward Token System - Smart Contract Overview

This repository contains the smart contracts that make up the Braveum on-chain reward token infrastructure. The system enables retailers to issue ERC-20 compliant reward tokens with optional expiry logic, support for custodial and non-custodial tokens, and an on-chain registry and factory architecture for deployment and management.

---

## 🧱 Contracts Overview

### 1. `RewardTokenRegistry.sol`

The central contract responsible for:

- Storing verified retailer addresses.
- Managing retailer application and approval processes.
- Limiting the number of tokens a retailer can deploy.
- Delegating token and wrapper deployment to the `RewardTokenFactory`.
- Storing the canonical list of all deployed reward tokens and wrappers.

Retailers interact with this contract to:
- Apply for verification.
- Create new reward tokens (custodial or non-custodial).
- Optionally wrap tokens with expiry logic.

Admins interact with this contract to:
- Approve retailer applications.
- Set max tokens per retailer.
- Update references to factory or implementation contracts.

---

### 2. `RewardTokenFactory.sol`

Handles the low-level deployment logic using `Clones.clone()` for:

- `RewardTokenCustodial`
- `RewardTokenNonCustodial`
- `RewardTokenWrapperWithExpiry`

This contract:
- Deploys minimal proxy clones of implementation contracts.
- Initializes them with data passed in from the registry.
- Returns the deployed address to the registry for storage.

It supports future extensibility via separate implementation addresses for each token type.

---

### 3. `RewardTokenCustodial.sol`

A minimal ERC-20 token that:
- Mints all tokens directly to the retailer on deployment.
- Allows retailer to transfer tokens to users manually.
- Does not track balances beyond standard ERC-20 behavior.

Designed for retailers who want full custody of token distribution and tracking.

---

### 4. `RewardTokenNonCustodial.sol`

An ERC-20 token with on-chain minting functionality:

- Allows retailer to mint tokens to user addresses after deployment.
- Enforces that only the creator/retailer can mint.
- Useful for systems where minting happens based on external conditions (e.g. off-chain spend).

Non-custodial tokens are flexible and more automated.

---

### 5. `RewardTokenWrapperWithExpiry.sol`

Wraps existing reward tokens and adds expiration logic:

- Can only be created by the factory.
- Wraps a specified reward token into a new token with:
  - Amount
  - Expiration timestamp
- Each wrap operation creates a unique "batch" for tracking.
- Retailer can reclaim expired batches from users.

Useful for promotions, limited-time rewards, or expiring bonuses.

---

## 🔐 Roles

- **Retailer**: Applies for approval, creates tokens, and distributes them to users.
- **Admin**: Approves retailers and configures the system.
- **Factory**: Deploys token instances based on instructions from the registry.

---

## 📈 Extensibility

This architecture is modular. To add a new token type or wrapper:

1. Deploy new implementation.
2. Update the factory to recognize and deploy the new implementation.
3. Update the registry to pass necessary config when requesting deployment.

---

## 🛠 Technologies Used

- Solidity ^0.8.20
- OpenZeppelin Contracts
- Clones (EIP-1167)
- Minimal Proxy Pattern

---

## ⚠️ Security Notes

- All deployed tokens are controlled by the retailer that created them.
- Only the admin (contract owner) can change implementation references or approve retailers.
- Expiry logic relies on block.timestamp, which can be manipulated slightly by miners.

---

