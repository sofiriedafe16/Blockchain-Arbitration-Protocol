# ⚖️ Blockchain Arbitration Protocol

A decentralized dispute resolution system built on Stacks blockchain that uses staked arbitrators to resolve smart contract disputes through democratic voting.

## 🌟 Features

- 🏛️ **Decentralized Arbitration**: Community-driven dispute resolution
- 💰 **Stake-based Selection**: Arbitrators must stake tokens to participate
- 🗳️ **Democratic Voting**: Multiple arbitrators vote on each dispute
- 🔒 **Secure Escrow**: Funds held safely during dispute resolution
- 📊 **Reputation System**: Track arbitrator performance over time
- ⏰ **Time-bound Voting**: Automatic resolution after voting period

## 🚀 Getting Started

### Prerequisites
- Clarinet CLI installed
- Stacks wallet with STX tokens

### Installation

```bash
clarinet new arbitration-project
cd arbitration-project
```

Copy the contract code into `contracts/Blockchain-Arbitration-Protocol.clar`

## 📖 Usage

### 1. Deposit Funds 💳
```clarity
(contract-call? .Blockchain-Arbitration-Protocol deposit u1000000)
```

### 2. Register as Arbitrator 👨‍⚖️
```clarity
(contract-call? .Blockchain-Arbitration-Protocol register-arbitrator)
```
*Requires minimum stake of 1,000,000 microSTX*

### 3. Create a Dispute 📋
```clarity
(contract-call? .Blockchain-Arbitration-Protocol create-dispute 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 u500000 "Payment dispute for services")
```

### 4. Start Arbitration Process ⚡
```clarity
(contract-call? .Blockchain-Arbitration-Protocol start-arbitration u1)
```

### 5. Vote on Dispute 🗳️
```clarity
(contract-call? .Blockchain-Arbitration-Protocol vote-on-dispute u1 true)
```
*`true` votes for plaintiff, `false` votes for defendant*

### 6. Resolve Dispute ✅
```clarity
(contract-call? .Blockchain-Arbitration-Protocol resolve-dispute u1)
```

## 🔍 Read-Only Functions

- `get-dispute`: View dispute details
- `get-arbitrator`: View arbitrator information  
- `get-user-balance`: Check user's contract balance
- `get-contract-balance`: View total contract balance

## ⚙️ Configuration

| Parameter | Value | Description |
|-----------|-------|-------------|
| `MIN_ARBITRATOR_STAKE` | 1,000,000 μSTX | Minimum stake to become arbitrator |
| `DISPUTE_FEE` | 100,000 μSTX | Fee to create a dispute |
| `VOTING_PERIOD` | 144 blocks | Time limit for voting (~24 hours) |
| `MIN_ARBITRATORS` | 3 | Minimum arbitrators needed for resolution |

## 🛡️ Security Features

- ✅ Stake-based arbitrator selection prevents spam
- ✅ Time-locked voting prevents manipulation
- ✅ Escrow system protects dispute funds
- ✅ One vote per arbitrator per dispute
- ✅ Automatic fund distribution after resolution

## 🧪 Testing

```bash
clarinet test
```

## 📝 Contract Functions

### Public Functions
- `deposit` - Add funds to contract balance
- `withdraw` - Remove funds from contract balance  
- `register-arbitrator` - Become an arbitrator by staking
- `create-dispute` - Start a new dispute case
- `start-arbitration` - Begin the voting process
- `vote-on-dispute` - Cast vote as arbitrator
- `resolve-dispute` - Finalize dispute resolution

### Read-Only Functions
- `get-dispute` - Retrieve dispute information
- `get-arbitrator` - Get arbitrator details
- `get-user-balance` - Check user balance
- `get-contract-balance` - View contract's STX balance

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📄 License

This project is licensed under the MIT License.

---

*Built with ❤️ on Stacks blockchain*
```

