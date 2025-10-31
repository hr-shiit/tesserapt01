# TESSERAPT Integration Guide

## Quick Start

### 1. File Structure

```
tesserapt-platform/
├── tesserapt-website.html      # Main HTML file
├── wallet-connect.js           # Wallet connection system
├── price-oracle.js            # Price feed management
├── tesserapt-functions.js     # Platform functionality
├── TESSERAPT_FUNCTIONS.md     # Function documentation
├── INTEGRATION_GUIDE.md       # This file
└── assets/
    ├── logof1.png            # Main logo
    └── tesseraptdocs2.pdf    # Documentation PDF
```

### 2. Loading Order (Critical)

```html
<!-- 1. WalletConnect CDN -->
<script src="https://unpkg.com/@walletconnect/web3-provider@1.8.0/dist/umd/index.min.js"></script>
<script src="https://unpkg.com/@web3modal/html@2.7.0"></script>

<!-- 2. Wallet Manager -->
<script src="wallet-connect.js"></script>

<!-- 3. Price Oracle -->
<script src="price-oracle.js"></script>

<!-- 4. Platform Functions -->
<script src="tesserapt-functions.js"></script>
```

### 3. Initialization Sequence

```javascript
// 1. DOM Ready
document.addEventListener("DOMContentLoaded", function () {
  // 2. Initialize Wallet Manager
  walletManager = new TesseraptWalletManager();

  // 3. Initialize Price Oracle
  priceOracle = new TesseraptPriceOracle();

  // 4. Initialize Platform
  tesseraptPlatform = new TesseraptPlatform();

  console.log("🚀 TESSERAPT Platform fully initialized");
});
```

---

## API Integration

### Price Oracle Configuration

#### CoinGecko API (Primary)

```javascript
// Free tier: 50 calls/minute
// No API key required for basic usage
const COINGECKO_CONFIG = {
  baseUrl: "https://api.coingecko.com/api/v3",
  endpoints: {
    price: "/simple/price",
    history: "/coins/{id}/market_chart",
  },
  rateLimit: 50, // calls per minute
  timeout: 5000,
};
```

#### Binance API (Fallback)

```javascript
// Public API: 1200 requests/minute
// No API key required for market data
const BINANCE_CONFIG = {
  baseUrl: "https://api.binance.com/api/v3",
  endpoints: {
    ticker: "/ticker/24hr",
    klines: "/klines",
  },
  rateLimit: 1200,
  timeout: 5000,
};
```

#### CoinMarketCap API (Optional)

```javascript
// Requires API key for production
// Free tier: 333 calls/day
const CMC_CONFIG = {
  baseUrl: "https://pro-api.coinmarketcap.com/v1",
  apiKey: "YOUR_CMC_API_KEY", // Required
  endpoints: {
    quotes: "/cryptocurrency/quotes/latest",
  },
  rateLimit: 333, // calls per day (free tier)
  timeout: 5000,
};
```

---

## Wallet Integration

### Supported Wallets

1. **Petra Wallet** (Primary - Aptos native)
2. **MetaMask** (Ethereum bridge support)
3. **Martian Wallet** (Multi-chain)
4. **Pontem Wallet** (Aptos focused)
5. **Fewcha Wallet** (Aptos ecosystem)
6. **WalletConnect** (Mobile wallets)

### Connection Flow

```javascript
// 1. User clicks "CONNECT WALLET"
// 2. Modal shows: Petra + "Other Wallets"
// 3. If "Other Wallets" clicked: Show all options
// 4. User selects wallet
// 5. Connection attempt with error handling
// 6. Success: Update UI, store connection state
```

### Wallet Detection

```javascript
// Automatic detection on page load
function detectWallets() {
  const wallets = {
    petra: !!window.aptos,
    metamask: !!(window.ethereum && window.ethereum.isMetaMask),
    martian: !!window.martian,
    pontem: !!window.pontem,
    fewcha: !!window.fewcha,
  };

  return wallets;
}
```

---

## Blockchain Integration (Future)

### Aptos SDK Setup

```bash
npm install @aptos-labs/ts-sdk
```

```javascript
import { Aptos, AptosConfig, Network } from "@aptos-labs/ts-sdk";

const config = new AptosConfig({ network: Network.MAINNET });
const aptos = new Aptos(config);

// Transaction example
async function stakeTokens(amount, token) {
  const transaction = {
    function: "0x1::tesserapt::stake",
    arguments: [amount, token],
    type_arguments: [],
  };

  const signedTx = await wallet.signTransaction(transaction);
  const result = await aptos.submitTransaction(signedTx);
  return result;
}
```

### Smart Contract Integration Points

```javascript
// Staking Contract
const STAKING_CONTRACT = "0x1::tesserapt::staking";

// Lending Contract
const LENDING_CONTRACT = "0x1::tesserapt::lending";

// Token Contracts
const PT_TOKEN = "0x1::tesserapt::principal_token";
const YT_TOKEN = "0x1::tesserapt::yield_token";
```

---

## Environment Configuration

### Development Environment

```javascript
const CONFIG = {
  environment: "development",
  priceOracle: {
    updateInterval: 10000, // 10 seconds for testing
    useMockData: true,
    enableDebugLogs: true,
  },
  wallet: {
    autoConnect: false,
    testMode: true,
  },
  blockchain: {
    network: "testnet",
    rpcUrl: "https://fullnode.testnet.aptoslabs.com/v1",
  },
};
```

### Production Environment

```javascript
const CONFIG = {
  environment: "production",
  priceOracle: {
    updateInterval: 30000, // 30 seconds
    useMockData: false,
    enableDebugLogs: false,
  },
  wallet: {
    autoConnect: true,
    testMode: false,
  },
  blockchain: {
    network: "mainnet",
    rpcUrl: "https://fullnode.mainnet.aptoslabs.com/v1",
  },
};
```

---

## Testing Framework

### Unit Tests

```javascript
// Test price oracle
describe("PriceOracle", () => {
  test("should fetch APT price from CoinGecko", async () => {
    const oracle = new TesseraptPriceOracle();
    const price = await oracle.fetchFromCoingecko("APT");
    expect(price).toBeGreaterThan(0);
  });
});

// Test wallet connection
describe("WalletManager", () => {
  test("should detect Petra wallet", () => {
    window.aptos = { connect: jest.fn() };
    const manager = new TesseraptWalletManager();
    expect(manager.detectAvailableWallets()).toContain("petra");
  });
});
```

### Integration Tests

```javascript
// Test complete staking flow
describe("Staking Flow", () => {
  test("should complete stake -> PT/YT -> trade flow", async () => {
    // 1. Connect wallet
    await walletManager.connectWallet("petra");

    // 2. Stake tokens
    await tesseraptPlatform.handleStaking();

    // 3. Verify PT/YT tokens created
    expect(tesseraptPlatform.stakingData.ptTokens).toBeGreaterThan(0);

    // 4. Trade tokens
    await tesseraptPlatform.confirmTrade();
  });
});
```

### E2E Tests (Cypress)

```javascript
describe("TESSERAPT Platform", () => {
  it("should complete full user journey", () => {
    cy.visit("/");
    cy.contains("START THE JOURNEY").click();
    cy.get("#stakeAmount").type("10");
    cy.contains("STAKE NOW").click();
    cy.contains("TOKEN PORTFOLIO").should("be.visible");
  });
});
```

---

## Performance Optimization

### Price Oracle Optimization

```javascript
// Batch price requests
async function batchPriceUpdate() {
  const tokens = ["APT", "BTC", "ETH"];
  const url = `https://api.coingecko.com/api/v3/simple/price?ids=${tokens.join(
    ","
  )}&vs_currencies=usd`;

  // Single API call for multiple tokens
  const response = await fetch(url);
  return response.json();
}

// Cache management
class PriceCache {
  constructor(ttl = 30000) {
    this.cache = new Map();
    this.ttl = ttl;
  }

  set(key, value) {
    this.cache.set(key, {
      value,
      timestamp: Date.now(),
    });
  }

  get(key) {
    const item = this.cache.get(key);
    if (!item) return null;

    if (Date.now() - item.timestamp > this.ttl) {
      this.cache.delete(key);
      return null;
    }

    return item.value;
  }
}
```

### UI Optimization

```javascript
// Debounced updates
function debounce(func, wait) {
  let timeout;
  return function executedFunction(...args) {
    const later = () => {
      clearTimeout(timeout);
      func(...args);
    };
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
  };
}

// Optimized DOM updates
const updatePrice = debounce((token, price) => {
  const element = document.querySelector(`[data-token="${token}"]`);
  if (element) {
    element.textContent = `$${price.toFixed(2)}`;
  }
}, 100);
```

---

## Security Considerations

### API Security

```javascript
// Rate limiting
class RateLimiter {
  constructor(maxRequests, timeWindow) {
    this.maxRequests = maxRequests;
    this.timeWindow = timeWindow;
    this.requests = [];
  }

  canMakeRequest() {
    const now = Date.now();
    this.requests = this.requests.filter(
      (time) => now - time < this.timeWindow
    );
    return this.requests.length < this.maxRequests;
  }

  recordRequest() {
    this.requests.push(Date.now());
  }
}

// Input validation
function validateTokenAmount(amount) {
  if (typeof amount !== "number" || amount <= 0 || !isFinite(amount)) {
    throw new Error("Invalid token amount");
  }

  if (amount > 1000000) {
    throw new Error("Amount too large");
  }

  return true;
}
```

### Wallet Security

```javascript
// Transaction validation
async function validateTransaction(transaction) {
  // Check transaction structure
  if (!transaction.function || !transaction.arguments) {
    throw new Error("Invalid transaction structure");
  }

  // Verify contract address
  const allowedContracts = [
    "0x1::tesserapt::staking",
    "0x1::tesserapt::lending",
  ];

  if (
    !allowedContracts.includes(
      transaction.function.split("::")[0] +
        "::" +
        transaction.function.split("::")[1]
    )
  ) {
    throw new Error("Unauthorized contract");
  }

  return true;
}
```

---

## Monitoring & Analytics

### Error Tracking

```javascript
class ErrorTracker {
  static track(error, context = {}) {
    const errorData = {
      message: error.message,
      stack: error.stack,
      timestamp: Date.now(),
      context,
      userAgent: navigator.userAgent,
      url: window.location.href,
    };

    // Send to monitoring service
    console.error("TESSERAPT Error:", errorData);

    // In production, send to service like Sentry
    // Sentry.captureException(error, { extra: context });
  }
}
```

### Performance Monitoring

```javascript
class PerformanceMonitor {
  static measureFunction(name, func) {
    return async (...args) => {
      const start = performance.now();
      try {
        const result = await func(...args);
        const duration = performance.now() - start;
        console.log(`${name} took ${duration.toFixed(2)}ms`);
        return result;
      } catch (error) {
        const duration = performance.now() - start;
        console.error(`${name} failed after ${duration.toFixed(2)}ms:`, error);
        throw error;
      }
    };
  }
}
```

---

## Deployment Checklist

### Pre-deployment

- [ ] All APIs configured with production keys
- [ ] Price oracle tested with all data sources
- [ ] Wallet connections tested on all supported wallets
- [ ] Error handling tested for all failure scenarios
- [ ] Performance optimization applied
- [ ] Security audit completed

### Production Setup

- [ ] CDN configured for static assets
- [ ] SSL certificate installed
- [ ] Rate limiting configured
- [ ] Monitoring and alerting set up
- [ ] Backup and recovery procedures in place
- [ ] Documentation updated

### Post-deployment

- [ ] Health checks passing
- [ ] Price feeds updating correctly
- [ ] Wallet connections working
- [ ] User analytics tracking
- [ ] Error rates within acceptable limits

---

## Troubleshooting

### Common Issues

#### Price Oracle Not Updating

```javascript
// Check oracle health
const health = priceOracle.getSystemHealth();
console.log("Oracle Health:", health);

// Manual price update
await priceOracle.updateAllPrices();
```

#### Wallet Connection Fails

```javascript
// Check wallet availability
const wallets = walletManager.detectAvailableWallets();
console.log("Available Wallets:", wallets);

// Clear wallet cache
localStorage.removeItem("walletconnect");
```

#### UI Not Updating

```javascript
// Check subscriptions
console.log("Active Subscriptions:", tesseraptPlatform.priceSubscriptions);

// Force UI update
tesseraptPlatform.updateMarketDisplay("APT", priceOracle.getPriceData("APT"));
```

### Debug Mode

```javascript
// Enable debug mode
window.TESSERAPT_DEBUG = true;

// Access debug info
console.log("Platform State:", tesseraptPlatform.debugInfo());
console.log("Oracle State:", priceOracle.debugInfo());
console.log("Wallet State:", walletManager.getConnectedWallet());
```

---

## Support & Maintenance

### Regular Maintenance Tasks

1. **Weekly**: Check API rate limits and usage
2. **Monthly**: Update price source configurations
3. **Quarterly**: Security audit and dependency updates
4. **As needed**: Add new token support

### Monitoring Alerts

- Price oracle health degradation
- API rate limit approaching
- Wallet connection failure rates
- Transaction failure rates
- Performance degradation

### Contact Information

- **Technical Support**: [Insert contact details]
- **Documentation**: [Insert documentation links]
- **Issue Tracking**: [Insert GitHub/issue tracker links]
