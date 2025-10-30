# 🔮 Oracles & Mocks Contract Integration Guide

## Contract: `oracles_and_mocks.move`

**Module:** `yield_tokenization::oracles_and_mocks`
**Address:** `0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16`

---

## 📋 Overview

This contract provides:
1. **stAPT Token** - Auto-compounding staked APT with 9.5% APY
2. **Price Oracles** - Real-time price feeds from Pyth Network
3. **Mock Tokens** - Testing tokens (USDC, BTC, ETH)
4. **APY Calculations** - Dynamic yield calculations

---

## 🚀 Initialization Functions

### 1. Initialize stAPT Token

```bash
aptos move run \
  --function-id 'ADDR::oracles_and_mocks::init_stapt_token'
```

**What it does:**
- Creates stAPT token with 9.5% APY
- Sets up auto-compounding mechanism
- Initializes exchange rate at 1:1

**Required:** Must be called once by contract owner

**Gas Cost:** ~500 units

---

### 2. Initialize Pyth Oracle

```bash
aptos move run \
  --function-id 'ADDR::oracles_and_mocks::init_pyth_oracle'
```

**What it does:**
- Sets up connection to Pyth Network
- Configures APT price feed
- Sets staleness threshold (5 minutes)

**Required:** Must be called once by contract owner

**Gas Cost:** ~500 units

---

## 💰 User Functions

### 3. Mint stAPT (Stake APT)

```bash
aptos move run \
  --function-id 'ADDR::oracles_and_mocks::mint_stapt' \
  --args address:STAPT_ADDR u64:AMOUNT
```

**Parameters:**
- `stapt_addr`: Address where stAPT is initialized
- `amount`: Amount to stake (in 8 decimals)

**Example:**
```bash
# Stake 10 APT
--args address:0x7c6a... u64:1000000000
```

**What it does:**
- User stakes APT
- Receives stAPT tokens
- Starts earning 9.5% APY automatically

**Returns:** stAPT tokens to user

**Gas Cost:** ~20 units

---

### 4. Burn stAPT (Unstake to APT)

```bash
aptos move run \
  --function-id 'ADDR::oracles_and_mocks::burn_stapt' \
  --args address:STAPT_ADDR u64:AMOUNT
```

**Parameters:**
- `stapt_addr`: Address where stAPT is initialized
- `amount`: Amount to unstake (in 8 decimals)

**What it does:**
- Burns stAPT tokens
- Returns APT to user
- Includes accumulated yield

**Gas Cost:** ~25 units

---

### 5. Compound Yield

```bash
aptos move run \
  --function-id 'ADDR::oracles_and_mocks::compound_all_yield' \
  --args address:STAPT_ADDR
```

**What it does:**
- Compounds yield for all users
- Updates exchange rate
- Increases stAPT value

**Can be called by:** Anyone
**Frequency:** Recommended daily

**Gas Cost:** ~30 units

---

## 📊 View Functions

### 6. Get stAPT Balance

```bash
aptos move view \
  --function-id 'ADDR::oracles_and_mocks::get_stapt_balance' \
  --args address:STAPT_ADDR address:USER_ADDR
```

**Returns:** User's stAPT balance (u64)

**Example Response:** `1000000000` (10 stAPT)

---

### 7. Get stAPT Exchange Rate

```bash
aptos move view \
  --function-id 'ADDR::oracles_and_mocks::get_stapt_exchange_rate' \
  --args address:STAPT_ADDR
```

**Returns:** Current exchange rate (u64, 8 decimals)

**Example Response:** `100000000` (1.0 = 1:1 ratio)

**Note:** Rate increases over time due to compounding

---

### 8. Get stAPT APY

```bash
aptos move view \
  --function-id 'ADDR::oracles_and_mocks::get_stapt_apy'
```

**Returns:** APY in basis points (u64)

**Response:** `950` (9.5% APY)

---

### 9. Get APT Price

```bash
aptos move view \
  --function-id 'ADDR::oracles_and_mocks::get_real_apt_price_usd'
```

**Returns:** APT price in USD (u64, 8 decimals)

**Example Response:** `340000000` ($3.40)

---

### 10. Calculate stAPT Value in APT

```bash
aptos move view \
  --function-id 'ADDR::oracles_and_mocks::calculate_stapt_value_in_apt' \
  --args address:STAPT_ADDR u64:STAPT_AMOUNT
```

**Parameters:**
- `stapt_addr`: stAPT contract address
- `stapt_amount`: Amount of stAPT

**Returns:** Equivalent APT value (u64)

**Example:**
```bash
# Input: 1000000000 stAPT (10 stAPT)
# Output: 1050000000 APT (10.5 APT after yield)
```

---

## 🔧 Integration Examples

### Example 1: Stake APT Flow

```typescript
// 1. User stakes 100 APT
const stakeAmount = 10000000000; // 100 APT in 8 decimals

await client.submitTransaction({
  function: `${CONTRACT_ADDR}::oracles_and_mocks::mint_stapt`,
  arguments: [STAPT_ADDR, stakeAmount],
  type_arguments: []
});

// 2. Check balance
const balance = await client.view({
  function: `${CONTRACT_ADDR}::oracles_and_mocks::get_stapt_balance`,
  arguments: [STAPT_ADDR, userAddress],
  type_arguments: []
});

console.log(`Received ${balance[0] / 100000000} stAPT`);
```

---

### Example 2: Check Yield Earned

```typescript
// 1. Get current exchange rate
const rate = await client.view({
  function: `${CONTRACT_ADDR}::oracles_and_mocks::get_stapt_exchange_rate`,
  arguments: [STAPT_ADDR],
  type_arguments: []
});

// 2. Calculate value
const staptBalance = 1000000000; // 10 stAPT
const aptValue = (staptBalance * rate[0]) / 100000000;

console.log(`10 stAPT = ${aptValue / 100000000} APT`);
```

---

## 📈 Economic Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| Base APY | 9.5% | Annual yield rate |
| Compounding | Continuous | Auto-compounds |
| Decimals | 8 | Token precision |
| Initial Rate | 1:1 | Starting exchange rate |
| Min Stake | 0.01 APT | Minimum stake amount |

---

## ⚠️ Important Notes

### Yield Calculation
- Yield compounds automatically
- Exchange rate increases over time
- 1 stAPT becomes worth more APT

### Price Staleness
- Prices older than 5 minutes are stale
- Check `is_apt_price_stale()` before using
- Update prices regularly

### Gas Optimization
- Batch compound operations
- Compound before large transactions
- Use view functions for reads

---

## 🔐 Security Considerations

### Access Control
- Only owner can initialize
- Anyone can mint/burn their own tokens
- Anyone can trigger compounding

### Price Oracle
- Uses Pyth Network for real prices
- Fallback to mock prices in testing
- Staleness checks prevent old data

### Reentrancy
- No external calls during minting
- State updates before transfers
- Safe from reentrancy attacks

---

## 🐛 Error Codes

| Code | Name | Description |
|------|------|-------------|
| 1 | E_NOT_OWNER | Caller is not contract owner |
| 2 | E_NOT_UPDATER | Caller cannot update prices |
| 3 | E_ZERO_AMOUNT | Amount must be > 0 |
| 4 | E_PRICE_DEVIATION | Price change too large |
| 5 | E_CIRCUIT_BREAKER | Emergency stop activated |
| 6 | E_INSUFFICIENT_BALANCE | Not enough tokens |
| 7 | E_PRICE_TOO_OLD | Price data is stale |

---

## 📞 Support & Resources

- **Contract Address:** `0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16`
- **Testnet Explorer:** [View on Explorer](https://explorer.aptoslabs.com/account/0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16?network=testnet)
- **APY:** 9.5% (950 basis points)
- **Decimals:** 8

---

## ✅ Integration Checklist

- [ ] Initialize stAPT token
- [ ] Initialize Pyth oracle
- [ ] Test minting stAPT
- [ ] Verify balance updates
- [ ] Check exchange rate
- [ ] Test burning stAPT
- [ ] Monitor yield accumulation
- [ ] Set up price updates
- [ ] Implement error handling
- [ ] Add staleness checks
