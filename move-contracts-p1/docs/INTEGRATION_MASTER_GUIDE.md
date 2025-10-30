# 🚀 Master Integration Guide - Complete Protocol

## Overview

This guide provides a complete integration path for the Pendle-style yield trading protocol on Aptos.

**Contract Address:** `0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16`

---

## 📚 Documentation Structure

### Individual Contract Guides

1. **[Oracles & Mocks](./INTEGRATION_ORACLES_AND_MOCKS.md)**
   - stAPT token (9.5% APY)
   - Price oracles
   - Mock tokens

2. **[Yield Tokenization](./INTEGRATION_YIELD_TOKENIZATION.md)**
   - SY wrapper
   - PT/YT splitting
   - Maturity management

3. **[PT/YT AMM](./INTEGRATION_PT_YT_AMM.md)**
   - Trading pools
   - Fair pricing
   - Liquidity provision

4. **[Multi-Pool Staking](./INTEGRATION_MULTI_LP_STAKING.md)**
   - Multiple pools
   - Auto-routing
   - Dynamic APY

---

## 🎯 Quick Start Integration

### Step 1: Setup (One-Time)

```typescript
import { AptosClient, AptosAccount } from "aptos";

const client = new AptosClient("https://fullnode.testnet.aptoslabs.com");
const CONTRACT_ADDR = "0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16";

// Initialize all modules (owner only)
async function initializeProtocol() {
  // 1. Initialize stAPT
  await submitTx("oracles_and_mocks::init_stapt_token");
  
  // 2. Initialize oracle
  await submitTx("oracles_and_mocks::init_pyth_oracle");
  
  // 3. Initialize SY wrapper
  await submitTx("tokenization::initialize_sy_wrapper", [
    CONTRACT_ADDR,
    "Standardized_Yield_stAPT",
    "SY-stAPT"
  ]);
  
  // 4. Initialize tokenization
  await submitTx("tokenization::initialize", [], [
    `${CONTRACT_ADDR}::tokenization::SYToken`
  ]);
  
  // 5. Create maturities
  const sixMonths = Math.floor(Date.now() / 1000) + 15552000;
  await submitTx("tokenization::create_maturity", [
    sixMonths,
    "6_Months"
  ], [`${CONTRACT_ADDR}::tokenization::SYToken`]);
  
  // 6. Initialize AMM
  await submitTx("pt_yt_amm::initialize_amm_factory");
  
  // 7. Initialize staking
  await submitTx("multi_lp_staking::initialize_staking_pools");
}
```

---

### Step 2: User Flow Implementation

```typescript
class PendleProtocol {
  constructor(client, contractAddr) {
    this.client = client;
    this.addr = contractAddr;
  }
  
  // 1. Stake APT → Get stAPT
  async stakeAPT(amount) {
    return await this.submitTx("oracles_and_mocks::mint_stapt", [
      this.addr,
      amount
    ]);
  }
  
  // 2. Wrap stAPT → Get SY
  async wrapToSY(amount) {
    return await this.submitTx("tokenization::deposit_stapt_for_sy", [
      this.addr,
      amount
    ]);
  }
  
  // 3. Split SY → Get PT + YT
  async splitSY(amount, maturityIdx) {
    return await this.submitTx("tokenization::split", [
      this.addr,
      amount,
      maturityIdx
    ], [`${this.addr}::tokenization::SYToken`]);
  }
  
  // 4. Create trading pool
  async createPool(maturity, ptAmount, expectedAPY) {
    return await this.submitTx("pt_yt_amm::create_and_bootstrap_pool", [
      this.addr,
      maturity,
      ptAmount,
      expectedAPY
    ]);
  }
  
  // 5. Trade PT for YT
  async swapPTForYT(poolId, ptAmount, minYTOut) {
    return await this.submitTx("pt_yt_amm::swap_pt_for_yt", [
      this.addr,
      poolId,
      ptAmount,
      minYTOut
    ]);
  }
  
  // 6. Trade YT for PT
  async swapYTForPT(poolId, ytAmount, minPTOut) {
    return await this.submitTx("pt_yt_amm::swap_yt_for_pt", [
      this.addr,
      poolId,
      ytAmount,
      minPTOut
    ]);
  }
  
  // Helper: Submit transaction
  async submitTx(functionName, args = [], typeArgs = []) {
    const payload = {
      function: `${this.addr}::${functionName}`,
      arguments: args,
      type_arguments: typeArgs
    };
    
    return await this.client.generateSignSubmitTransaction(
      this.account,
      payload
    );
  }
}
```

---

### Step 3: View Functions

```typescript
class PendleViews {
  constructor(client, contractAddr) {
    this.client = client;
    this.addr = contractAddr;
  }
  
  // Get stAPT balance
  async getStAPTBalance(userAddr) {
    return await this.view("oracles_and_mocks::get_stapt_balance", [
      this.addr,
      userAddr
    ]);
  }
  
  // Get SY balance
  async getSYBalance(userAddr) {
    return await this.view("tokenization::get_sy_balance", [
      this.addr,
      userAddr
    ]);
  }
  
  // Get PT balance
  async getPTBalance(userAddr, maturityIdx) {
    return await this.view("tokenization::get_user_pt_balance", [
      userAddr,
      maturityIdx
    ], [`${this.addr}::tokenization::SYToken`]);
  }
  
  // Get YT balance
  async getYTBalance(userAddr, maturityIdx) {
    return await this.view("tokenization::get_user_yt_balance", [
      userAddr,
      maturityIdx
    ], [`${this.addr}::tokenization::SYToken`]);
  }
  
  // Get pool reserves
  async getPoolReserves(poolId) {
    return await this.view("pt_yt_amm::get_pool_reserves", [
      this.addr,
      poolId
    ]);
  }
  
  // Get implied APY
  async getImpliedAPY(poolId) {
    return await this.view("pt_yt_amm::calculate_implied_apy", [
      this.addr,
      poolId
    ]);
  }
  
  // Get best staking pool
  async getBestStakingPool() {
    return await this.view("multi_lp_staking::get_best_yield_pool", [
      this.addr
    ]);
  }
  
  // Helper: View function
  async view(functionName, args = [], typeArgs = []) {
    return await this.client.view({
      function: `${this.addr}::${functionName}`,
      arguments: args,
      type_arguments: typeArgs
    });
  }
}
```

---

## 🔄 Complete User Journey

### Journey 1: Fixed-Rate Strategy

```typescript
async function fixedRateStrategy(protocol, views, userAddr) {
  // 1. Stake 100 APT
  const stakeAmount = 10000000000; // 100 APT
  await protocol.stakeAPT(stakeAmount);
  console.log("✅ Staked 100 APT");
  
  // 2. Wrap to SY
  await protocol.wrapToSY(stakeAmount);
  console.log("✅ Wrapped to 100 SY");
  
  // 3. Split to PT + YT
  const splitAmount = 5000000000; // 50 SY
  await protocol.splitSY(splitAmount, 0);
  console.log("✅ Split to 50 PT + 50 YT");
  
  // 4. Sell YT for more PT (lock in fixed rate)
  const ytBalance = await views.getYTBalance(userAddr, 0);
  await protocol.swapYTForPT(0, ytBalance[0], 0);
  console.log("✅ Sold YT for PT - Fixed rate locked!");
  
  // 5. Check final PT balance
  const finalPT = await views.getPTBalance(userAddr, 0);
  console.log(`Final PT: ${finalPT[0] / 100000000}`);
  console.log(`Guaranteed return at maturity!`);
}
```

---

### Journey 2: Yield Speculation

```typescript
async function yieldSpeculation(protocol, views, userAddr) {
  // 1. Get tokens
  await protocol.stakeAPT(10000000000);
  await protocol.wrapToSY(10000000000);
  await protocol.splitSY(5000000000, 0);
  
  // 2. Sell PT to buy more YT
  const ptBalance = await views.getPTBalance(userAddr, 0);
  const halfPT = Math.floor(ptBalance[0] / 2);
  
  await protocol.swapPTForYT(0, halfPT, 0);
  console.log("✅ Bought more YT - Betting on high yield!");
  
  // 3. Check position
  const finalPT = await views.getPTBalance(userAddr, 0);
  const finalYT = await views.getYTBalance(userAddr, 0);
  
  console.log(`PT: ${finalPT[0] / 100000000}`);
  console.log(`YT: ${finalYT[0] / 100000000}`);
  console.log(`If yield > expected: Profit!`);
}
```

---

### Journey 3: Liquidity Provider

```typescript
async function liquidityProvider(protocol, views, userAddr) {
  // 1. Get tokens
  await protocol.stakeAPT(10000000000);
  await protocol.wrapToSY(10000000000);
  await protocol.splitSY(5000000000, 0);
  
  // 2. Create pool (if first user)
  const maturity = Math.floor(Date.now() / 1000) + 15552000;
  await protocol.createPool(maturity, 100000000, 950);
  console.log("✅ Created pool with fair pricing");
  
  // 3. Add more liquidity
  await protocol.submitTx("pt_yt_amm::add_liquidity_pt_yt", [
    protocol.addr,
    0,
    50000000,
    50000000
  ]);
  console.log("✅ Added liquidity - Earning 0.3% fees!");
  
  // 4. Check LP balance
  const lpBalance = await views.view("pt_yt_amm::get_user_lp_balance", [
    userAddr,
    0
  ]);
  console.log(`LP Tokens: ${lpBalance[0] / 100000000}`);
}
```

---

## 📊 Integration Patterns

### Pattern 1: Price Monitoring

```typescript
async function monitorPrices(views) {
  setInterval(async () => {
    // Get PT price
    const ptPrice = await views.view("pt_yt_amm::get_pt_price", [
      views.addr,
      0
    ]);
    
    // Get YT price
    const ytPrice = await views.view("pt_yt_amm::get_yt_price", [
      views.addr,
      0
    ]);
    
    // Get implied APY
    const impliedAPY = await views.getImpliedAPY(0);
    
    console.log(`PT Price: ${ptPrice[0] / 100000000} YT`);
    console.log(`YT Price: ${ytPrice[0] / 100000000} PT`);
    console.log(`Implied APY: ${impliedAPY[0] / 100}%`);
  }, 60000); // Every minute
}
```

---

### Pattern 2: Auto-Rebalancing

```typescript
async function autoRebalance(protocol, views, userAddr) {
  // Check best staking pool every hour
  setInterval(async () => {
    const bestPool = await views.getBestStakingPool();
    const currentPool = await getCurrentPool(userAddr);
    
    if (bestPool[0] !== currentPool) {
      // Unstake from current pool
      await unstakeFromPool(currentPool);
      
      // Stake in best pool
      await protocol.submitTx("multi_lp_staking::stake_to_best_pool", [
        protocol.addr,
        amount
      ]);
      
      console.log(`Rebalanced to pool ${bestPool[0]}`);
    }
  }, 3600000); // Every hour
}
```

---

### Pattern 3: Yield Tracking

```typescript
async function trackYield(views, userAddr) {
  const initialStAPT = await views.getStAPTBalance(userAddr);
  const initialRate = await views.view("oracles_and_mocks::get_stapt_exchange_rate", [
    views.addr
  ]);
  
  setInterval(async () => {
    const currentStAPT = await views.getStAPTBalance(userAddr);
    const currentRate = await views.view("oracles_and_mocks::get_stapt_exchange_rate", [
      views.addr
    ]);
    
    const aptValue = (currentStAPT[0] * currentRate[0]) / 100000000;
    const initialAPTValue = (initialStAPT[0] * initialRate[0]) / 100000000;
    
    const yieldEarned = aptValue - initialAPTValue;
    const yieldPercent = (yieldEarned / initialAPTValue) * 100;
    
    console.log(`Yield Earned: ${yieldEarned / 100000000} APT (${yieldPercent.toFixed(2)}%)`);
  }, 86400000); // Daily
}
```

---

## 🔐 Security Best Practices

### 1. Input Validation

```typescript
function validateAmount(amount) {
  if (amount <= 0) throw new Error("Amount must be positive");
  if (amount < 1000000) throw new Error("Amount too small (min 0.01)");
  return true;
}

function validateMaturity(maturity) {
  const now = Math.floor(Date.now() / 1000);
  if (maturity <= now) throw new Error("Maturity must be in future");
  if (maturity > now + 31536000) throw new Error("Maturity too far (max 1 year)");
  return true;
}
```

---

### 2. Slippage Protection

```typescript
async function swapWithSlippage(protocol, views, ptAmount, slippageBps) {
  // Get current price
  const ptPrice = await views.view("pt_yt_amm::get_pt_price", [
    views.addr,
    0
  ]);
  
  // Calculate expected output
  const expectedYT = (ptAmount * ptPrice[0]) / 100000000;
  
  // Apply slippage tolerance
  const minYTOut = Math.floor(expectedYT * (10000 - slippageBps) / 10000);
  
  // Execute swap
  return await protocol.swapPTForYT(0, ptAmount, minYTOut);
}
```

---

### 3. Error Handling

```typescript
async function safeTransaction(txFunction) {
  try {
    const result = await txFunction();
    console.log("✅ Transaction successful:", result);
    return result;
  } catch (error) {
    if (error.message.includes("E_INSUFFICIENT_BALANCE")) {
      console.error("❌ Insufficient balance");
    } else if (error.message.includes("E_SLIPPAGE_EXCEEDED")) {
      console.error("❌ Slippage exceeded - try again");
    } else if (error.message.includes("E_MATURITY_EXPIRED")) {
      console.error("❌ Pool expired");
    } else {
      console.error("❌ Transaction failed:", error.message);
    }
    throw error;
  }
}
```

---

## 📈 Performance Optimization

### 1. Batch View Calls

```typescript
async function batchGetBalances(views, userAddr) {
  const [stAPT, sy, pt, yt] = await Promise.all([
    views.getStAPTBalance(userAddr),
    views.getSYBalance(userAddr),
    views.getPTBalance(userAddr, 0),
    views.getYTBalance(userAddr, 0)
  ]);
  
  return {
    stAPT: stAPT[0] / 100000000,
    sy: sy[0] / 100000000,
    pt: pt[0] / 100000000,
    yt: yt[0] / 100000000
  };
}
```

---

### 2. Cache Frequently Used Data

```typescript
class CachedViews {
  constructor(views, cacheDuration = 60000) {
    this.views = views;
    this.cache = new Map();
    this.cacheDuration = cacheDuration;
  }
  
  async getCached(key, fetchFn) {
    const cached = this.cache.get(key);
    const now = Date.now();
    
    if (cached && now - cached.timestamp < this.cacheDuration) {
      return cached.data;
    }
    
    const data = await fetchFn();
    this.cache.set(key, { data, timestamp: now });
    return data;
  }
  
  async getPoolReserves(poolId) {
    return await this.getCached(`reserves_${poolId}`, () =>
      this.views.getPoolReserves(poolId)
    );
  }
}
```

---

## ✅ Integration Checklist

### Protocol Setup
- [ ] Deploy all contracts
- [ ] Initialize all modules
- [ ] Create maturities
- [ ] Create staking pools
- [ ] Test all functions

### User Interface
- [ ] Implement staking flow
- [ ] Implement wrapping flow
- [ ] Implement splitting flow
- [ ] Implement trading interface
- [ ] Add liquidity interface

### Monitoring
- [ ] Price monitoring
- [ ] APY tracking
- [ ] Pool metrics
- [ ] User positions
- [ ] Transaction history

### Security
- [ ] Input validation
- [ ] Slippage protection
- [ ] Error handling
- [ ] Access control
- [ ] Audit integration

---

## 📞 Support Resources

- **Documentation:** See individual contract guides
- **Contract Address:** `0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16`
- **Testnet Explorer:** [View on Explorer](https://explorer.aptoslabs.com/account/0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16?network=testnet)
- **Network:** Aptos Testnet

---

## 🎉 Ready to Integrate!

You now have everything needed to integrate the complete Pendle-style protocol. Start with the individual contract guides for detailed function documentation, then use this master guide for end-to-end flows.

**Happy Building!** 🚀
