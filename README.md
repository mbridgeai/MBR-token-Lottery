# Lottery Smart Contract

A decentralized lottery system built on Ethereum using Chainlink VRF for verifiable random number generation and custom ERC-20 tokens for ticket purchases.

## Features

- Decentralized random number generation via Chainlink VRF
- Custom ERC-20 token integration for ticket purchases
- Configurable ticket prices and maximum ticket limits
- Automatic drawing system with configurable intervals
- Pausable functionality for emergency situations
- Owner-controlled admin functions
- Event emission for frontend integration

## Prerequisites

- Node.js and npm
- Hardhat or Truffle
- A Chainlink VRF subscription
- An ERC-20 token contract address

## Contract Details

### Core Functions

#### Starting a Lottery
```solidity
function startLottery(uint256 _maxTickets, uint256 _ticketPrice) public onlyOwner whenNotPaused
```
Initializes a new lottery round with specified maximum tickets and ticket price.

#### Entering the Lottery
```solidity
function enter(uint256 _ticketCount) public whenNotPaused
```
Allows users to purchase tickets using the specified ERC-20 token.

#### Drawing a Winner
```solidity
function autoDrawWinner() public
```
Triggers the random winner selection process after the draw interval has passed.

### Admin Functions

- `pauseLottery()`: Pauses the contract in emergency situations
- `unpauseLottery()`: Resumes contract operations
- `withdraw()`: Allows owner to withdraw accumulated fees
- `transferOwnership(address newOwner)`: Transfers contract ownership
- `setDrawInterval(uint256 _interval)`: Updates the automatic draw interval

### Events

- `LotteryStarted(uint256 maxTickets, uint256 ticketPrice)`
- `TicketPurchased(address indexed player, uint256 ticketCount)`
- `WinnerPicked(address indexed winner, uint256 amountWon)`
- `LotteryPaused()`
- `LotteryUnpaused()`
- `RandomnessRequested(uint256 requestId)`
- `RandomnessFulfilled(uint256 requestId, uint256 randomNumber)`

## Deployment

1. Deploy your ERC-20 token contract (if not using an existing one)
2. Set up a Chainlink VRF subscription and fund it with LINK tokens
3. Deploy the lottery contract with the following parameters:
   - VRF Coordinator address
   - VRF subscription ID
   - ERC-20 token address

```solidity
constructor(
    address _vrfCoordinator,
    uint64 _vrfSubscriptionId,
    address _customToken
)
```

## Configuration

Key configurable parameters:

- `drawInterval`: Time between automatic draws (default: 1 day)
- `requestConfirmations`: Required block confirmations for VRF (default: 3)
- `callbackGasLimit`: Gas limit for VRF callback (default: 500000)
- `numBlockConfirmations`: Blocks to wait before VRF fulfillment (default: 3)

## Security Considerations

- Uses OpenZeppelin's best practices
- Implements checks-effects-interactions pattern
- Includes emergency pause functionality
- Requires owner authentication for admin functions
- Verifies VRF coordinator for random number fulfillment
- Checks for sufficient token balances before ticket purchase

## Testing

1. Install dependencies:
```bash
npm install
```

2. Run tests:
```bash
npx hardhat test
```

## License

This project is licensed under the MIT License.
