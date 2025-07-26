# RAWbank DeFi Ecosystem

## Overview
RAWbank is a comprehensive DeFi ecosystem that includes various smart contracts for token management, faucets, and token exchange functionalities. This repository contains the core smart contracts of the RAWbank ecosystem.

## Smart Contracts

### U2UFaucet.sol
A faucet contract for distributing U2U tokens to users who have zero balance.

#### Features:
- **Access Control**: Uses OpenZeppelin's AccessControl for role-based permissions
- **Reentrancy Protection**: Implements ReentrancyGuard for security
- **Manager Role**: Special privileges for contract management
- **Configurable Amount**: Adjustable distribution amount
- **Token Recovery**: Ability to recover stuck tokens

#### Key Functions:
- `Pay(address payable receiver)`: Distributes U2U tokens to eligible users
- `GetBalance(address payable receiver)`: Checks user's balance
- `Depo()`: Allows manager to deposit funds
- `UpdateAmount(uint256 newamount)`: Updates distribution amount
- `SetManager(address newmanager)`: Transfers manager role
- `StuckTokens(address token)`: Recovers stuck tokens

### Other Contracts
- **RAWBank.sol**: Main banking contract
- **RAWBrz.sol**: Bronze token contract
- **RAWGld.sol**: Gold token contract
- **RAWSlv.sol**: Silver token contract
- **RawChanger.sol**: Token exchange contract
- **eRawChanger.sol**: Enhanced token exchange contract
- **RAWSSupply.sol**: Supply management contract
- **SkaleGacha.sol**: Gacha system contract
- **sRAWFaucet.sol**: Special RAW token faucet
- **sFuelFaucet.sol**: Fuel token faucet

## Security Features
- Reentrancy protection using OpenZeppelin's ReentrancyGuard
- Role-based access control
- Safe ERC20 token handling
- Balance checks and validations
- Event emission for tracking transactions

## Dependencies
- OpenZeppelin Contracts v4.x
  - ERC20
  - AccessControl
  - SafeERC20
  - ReentrancyGuard

## Setup and Deployment
1. Install dependencies
2. Configure deployment parameters
3. Deploy contracts
4. Set up initial roles and permissions
5. Fund the faucets

## Usage

### For Users
1. Connect your wallet
2. Ensure zero U2U balance to be eligible
3. Request tokens from faucet
4. Receive configured amount of U2U

### For Managers
1. Connect with manager wallet
2. Use management functions:
   - Deposit funds
   - Update distribution amount
   - Manage roles
   - Recover stuck tokens

## Events
- `Payed(address indexed payee, uint256 indexed amount, uint256 indexed timestamp)`
  - Emitted when tokens are distributed
  - Tracks recipient, amount, and timestamp

## Security Considerations
- Only users with zero balance can receive tokens
- Contract balance is checked before distribution
- Manager role required for administrative functions
- Protected against reentrancy attacks
- Safe token transfer implementations


## Contributing
Feel free to submit issues and pull requests for improvements.

## Contact
For inquiries and support, please open an issue in the repository.

---
**Note**: This documentation is for reference purposes. Always audit smart contracts before deployment or interaction.
