# TESSERAPT - DeFi Platform on Aptos

A decentralized finance platform built on Aptos blockchain featuring staking, trading, and lending capabilities.

## Features

- **Staking**: Stake APT tokens and earn yield with real blockchain transactions
- **Trading**: Trade PT/YT tokens with live market data
- **Lending**: Borrow against your crypto assets (Coming Soon)
- **Live Data**: Real-time price feeds and blockchain data updates

## Quick Start

### 1. Install Petra Wallet
- Download from https://petra.app/
- Create or import wallet
- Switch to Aptos Testnet

### 2. Get Testnet APT
- Visit https://aptoslabs.com/testnet-faucet
- Enter your wallet address
- Receive free testnet APT

### 3. Run the Website
```bash
# Start local server
python3 -m http.server 8000

# Open browser
http://localhost:8000/tesserapt-website.html
```

### 4. Connect & Stake
- Click "Connect Wallet"
- Navigate to staking section
- Enter amount and stake
- Approve transaction in Petra wallet

## Project Structure

```
├── tesserapt-website.html      # Main website
├── tesserapt-functions.js      # Core platform logic
├── wallet-connect.js           # Wallet integration
├── aptos-client.js            # Blockchain client
├── price-oracle.js            # Price feeds
├── live-data-dashboard.js     # Real-time data
├── system-monitor.js          # System health
├── contracts/
│   ├── staking-contract.js    # Staking interface
│   └── amm-contract.js        # AMM interface
└── move-contracts-p1/         # Smart contracts
    └── sources/               # Move source files
```

## Technology Stack

- **Frontend**: HTML, CSS, JavaScript
- **Blockchain**: Aptos (Move language)
- **Wallet**: Petra Wallet
- **Price Data**: CoinGecko API
- **Network**: Aptos Testnet

## Smart Contracts

Contract Address: `0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16`

### Modules:
- `oracles_and_mocks` - Price oracles and stAPT minting
- `stapt_staking` - APT staking functionality
- `coin_types` - Token definitions (PT, YT, stAPT)
- `simple_amm` - Automated Market Maker

## Features Status

✅ **Working:**
- APT Staking with real blockchain transactions
- Petra wallet integration
- Real-time price feeds (CoinGecko)
- Live data dashboard
- System health monitoring

⏳ **Coming Soon:**
- PT/YT AMM trading (contract ready, needs liquidity)
- Lending protocol
- Cross-chain bridges

## Development

### Prerequisites
- Python 3 (for local server)
- Petra Wallet
- Aptos CLI (for contract deployment)

### Testing
```bash
# Start server
python3 -m http.server 8000

# Open test page
http://localhost:8000/test-blockchain.html
```

## Security

- No private keys stored in code
- All transactions signed through Petra wallet
- Transaction simulation before execution
- Input validation and error handling

## Support

For issues or questions:
- Check browser console for errors
- Ensure Petra wallet is on Aptos Testnet
- Verify you have testnet APT for gas fees

## License

MIT License

---

**Built with ❤️ on Aptos Blockchain**
