# 🏊 Multi-Pool Staking Contract Integration Guide

## Contract: `multi_lp_staking.move`

**Module:** `yield_tokenization::multi_lp_staking`
**Address:** `0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16`

---

## 📋 Overview

This contract provides:
1. **Multiple Staking Pools** - Different risk/reward profiles
2. **Dynamic APY** - Base yield + trading fees + bonuses
3. **Auto-Routing** - Automatically stake in best yield pool
4. **Pool Metrics** - Real-time liquidity, volume, APY tracking

---

## 🚀 Initialization Functions

### 1. Initialize Staking Pools System

```bash
aptos move run \
  --function-id 'ADDR::multi_lp_staking::initialize_staking_pools'
```

**What it does:**
- Creates staking pools system
- Sets up pool tracking
- Enables pool creation

**Required:** Must be called once by owner

**Gas Cost:** ~465 units

---

## 💰 Pool Management Functions

### 2. Create Staking Pool

```bash
aptos move run \
  --function-id 'ADDR::multi_lp_staking::create_staking_pool' \
  --args string:b"NAME" string:b"SYMBOL" address:TOKEN_A address:TOKEN_B u64:BASE_APY_BPS
```

**Parameters:**
- `name`: Pool name (e.g., "stAPT-USDC_Pool")
- `symbol`: Pool symbol (e.g., "stAPT-USDC")
- `token_a_oracle`: First token oracle address
- `token_b_oracle`: Second token oracle address
- `base_apy_bps`: Base APY in basis points (e.g., 1000 = 10%)

**Example:**
```bash
# Create stAPT-USDC pool with 10% base APY
--args string:b"stAPT-USDC_Pool" string:b"stAPT-USDC" address:0x7c6a... address:0x7c6a... u64:1000
```

**What it does:**
- Creates new staking pool
- Sets base APY
- Tracks pool metrics
- Updates best yield pool

**Can be called by:** Owner

**Gas Cost:** ~50 units

---

## 🎯 User Staking Functions

### 3. Stake to Specific Pool

```bash
aptos move run \
  --function-id 'ADDR::multi_lp_staking::stake_to_pool' \
  --args address:STAKING_POOLS_ADDR u64:POOL_ID u64:AMOUNT
```

**Parameters:**
- `staking_pools_addr`: Staking pools contract address
- `pool_id`: Pool ID (0, 1, 2...)
- `amount`: Amount to stake (8 decimals)

**Example:**
```bash
# Stake 1 SY in pool 0
--args address:0x7c6a... u64:0 u64:100000000
```

**What it does:**
- Stakes tokens in specified pool
- Updates pool liquidity
- Calculates new APY
- Tracks user position

**Returns:** Updated APY

**Gas Cost:** ~30 units

---

### 4. Stake to Best Yield Pool (AUTO-ROUTING)

```bash
aptos move run \
  --function-id 'ADDR::multi_lp_staking::stake_to_best_pool' \
  --args address:STAKING_POOLS_ADDR u64:AMOUNT
```

**Parameters:**
- `staking_pools_addr`: Staking pools contract address
- `amount`: Amount to stake (8 decimals)

**Example:**
```bash
# Auto-stake 1 SY in highest APY pool
--args address:0x7c6a... u64:100000000
```

**What it does:**
- Finds pool with highest APY
- Stakes in that pool automatically
- Optimizes user returns
- Updates pool metrics

**Recommended:** Use this for maximum yields

**Gas Cost:** ~35 units

---

## 📊 View Functions

### 5. Get Best Yield Pool

```bash
aptos move view \
  --function-id 'ADDR::multi_lp_staking::get_best_yield_pool' \
  --args address:STAKING_POOLS_ADDR
```

**Returns:** Pool ID with highest APY (u64)

**Example Response:** `1` (Pool 1 has best yield)

---

### 6. Get Pool APY

```bash
aptos move view \
  --function-id 'ADDR::multi_lp_staking::get_pool_apy' \
  --args address:STAKING_POOLS_ADDR u64:POOL_ID
```

**Parameters:**
- `staking_pools_addr`: Staking pools address
- `pool_id`: Pool ID

**Returns:** Current APY in basis points (u64)

**Example Response:** `1200` (12% APY)

**APY Calculation:**
```
Current_APY = Base_APY + Fee_APY + Utilization_Bonus
Fee_APY = (daily_fees * 365 * 10000) / total_liquidity
```

---

### 7. Get Pool Info

```bash
aptos move view \
  --function-id 'ADDR::multi_lp_staking::get_pool_info' \
  --args address:STAKING_POOLS_ADDR u64:POOL_ID
```

**Returns:** `[name, current_apy, total_liquidity, volume_24h]`

**Example Response:**
```
[
  "stAPT-USDC Pool",
  1200,           // 12% APY
  1000000000,     // 10 tokens liquidity
  50000000        // 0.5 tokens 24h volume
]
```

---

### 8. Get User Total Staked

```bash
aptos move view \
  --function-id 'ADDR::multi_lp_staking::get_user_total_staked' \
  --args address:USER_ADDR
```

**Returns:** Total amount staked across all pools (u64)

---

### 9. Get User Pool Stake

```bash
aptos move view \
  --function-id 'ADDR::multi_lp_staking::get_user_pool_stake' \
  --args address:USER_ADDR u64:POOL_ID
```

**Parameters:**
- `user_addr`: User address
- `pool_id`: Pool ID

**Returns:** Amount staked in specific pool (u64)

---

### 10. Get All Pool APYs

```bash
aptos move view \
  --function-id 'ADDR::multi_lp_staking::get_all_pool_apys' \
  --args address:STAKING_POOLS_ADDR
```

**Returns:** Array of APYs for all pools

**Example Response:** `[1000, 1200, 1100]` (10%, 12%, 11%)

---

### 11. Get Total Pools

```bash
aptos move view \
  --function-id 'ADDR::multi_lp_staking::get_total_pools' \
  --args address:STAKING_POOLS_ADDR
```

**Returns:** Number of pools created (u64)

---

## 🔧 Integration Examples

### Example 1: Create Multiple Pools

```typescript
// 1. Create stAPT-USDC pool (10% APY)
await client.submitTransaction({
  function: `${CONTRACT_ADDR}::multi_lp_staking::create_staking_pool`,
  arguments: [
    "stAPT-USDC_Pool",
    "stAPT-USDC",
    STAPT_ORACLE,
    USDC_ORACLE,
    1000 // 10% base APY
  ],
  type_arguments: []
});

// 2. Create stAPT-BTC pool (12% APY)
await client.submitTransaction({
  function: `${CONTRACT_ADDR}::multi_lp_staking::create_staking_pool`,
  arguments: [
    "stAPT-BTC_Pool",
    "stAPT-BTC",
    STAPT_ORACLE,
    BTC_ORACLE,
    1200 // 12% base APY
  ],
  type_arguments: []
});

// 3. Create stAPT-ETH pool (11% APY)
await client.submitTransaction({
  function: `${CONTRACT_ADDR}::multi_lp_staking::create_staking_pool`,
  arguments: [
    "stAPT-ETH_Pool",
    "stAPT-ETH",
    STAPT_ORACLE,
    ETH_ORACLE,
    1100 // 11% base APY
  ],
  type_arguments: []
});
```

---

### Example 2: Auto-Route to Best Pool

```typescript
// 1. Check all pool APYs
const apys = await client.view({
  function: `${CONTRACT_ADDR}::multi_lp_staking::get_all_pool_apys`,
  arguments: [STAKING_POOLS_ADDR],
  type_arguments: []
});

console.log('Pool APYs:', apys[0]);

// 2. Get best pool
const bestPool = await client.view({
  function: `${CONTRACT_ADDR}::multi_lp_staking::get_best_yield_pool`,
  arguments: [STAKING_POOLS_ADDR],
  type_arguments: []
});

console.log(`Best pool: ${bestPool[0]} with ${apys[0][bestPool[0]]/100}% APY`);

// 3. Auto-stake in best pool
const stakeAmount = 100000000; // 1 token

await client.submitTransaction({
  function: `${CONTRACT_ADDR}::multi_lp_staking::stake_to_best_pool`,
  arguments: [STAKING_POOLS_ADDR, stakeAmount],
  type_arguments: []
});
```

---

### Example 3: Monitor Pool Performance

```typescript
// 1. Get pool info
const poolInfo = await client.view({
  function: `${CONTRACT_ADDR}::multi_lp_staking::get_pool_info`,
  arguments: [STAKING_POOLS_ADDR, 0],
  type_arguments: []
});

const [name, apy, liquidity, volume] = poolInfo[0];

console.log(`Pool: ${name}`);
console.log(`APY: ${apy / 100}%`);
console.log(`Liquidity: ${liquidity / 100000000} tokens`);
console.log(`24h Volume: ${volume / 100000000} tokens`);

// 2. Calculate fee APY
const dailyFees = (volume * 30) / 10000; // 0.3% fee
const feeAPY = (dailyFees * 365 * 10000) / liquidity;

console.log(`Fee APY: ${feeAPY / 100}%`);
console.log(`Base APY: ${(apy - feeAPY) / 100}%`);
```

---

### Example 4: Compare Pools

```typescript
// 1. Get all pools
const totalPools = await client.view({
  function: `${CONTRACT_ADDR}::multi_lp_staking::get_total_pools`,
  arguments: [STAKING_POOLS_ADDR],
  type_arguments: []
});

// 2. Compare each pool
for (let i = 0; i < totalPools[0]; i++) {
  const info = await client.view({
    function: `${CONTRACT_ADDR}::multi_lp_staking::get_pool_info`,
    arguments: [STAKING_POOLS_ADDR, i],
    type_arguments: []
  });
  
  const [name, apy, liquidity, volume] = info[0];
  
  console.log(`\nPool ${i}: ${name}`);
  console.log(`  APY: ${apy / 100}%`);
  console.log(`  TVL: $${(liquidity / 100000000) * 3.40}`); // Assuming $3.40 APT
  console.log(`  Volume: ${volume / 100000000} tokens`);
}
```

---

## 📈 Pool Comparison

### Default Pools

| Pool | Base APY | Risk Level | Volatility |
|------|----------|------------|------------|
| stAPT-USDC | 10% | Low | Stable |
| stAPT-BTC | 12% | High | Volatile |
| stAPT-ETH | 11% | Medium | Moderate |

### APY Components

```
Total APY = Base APY + Fee APY + Utilization Bonus

Fee APY = (Trading Fees * 365) / Total Liquidity
Utilization Bonus = Based on pool activity
```

---

## 📊 Economic Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| Base APY Range | 10-12% | Pool-specific |
| Trading Fee | 0.3% | On all swaps |
| Fee Distribution | 100% to stakers | All fees to pool |
| Decimals | 8 | Token precision |
| Min Stake | 0.01 | Minimum amount |

---

## ⚠️ Important Notes

### Pool Selection
- Higher APY = Higher risk usually
- Check pool volatility
- Consider your risk tolerance

### APY Dynamics
- APY changes with trading activity
- More volume = higher APY
- More liquidity = lower APY (dilution)

### Auto-Routing
- Always routes to highest APY
- Recalculates on each stake
- User can override manually

### Rewards
- Rewards accrue automatically
- No manual claiming needed
- Compounded into stake

---

## 🔐 Security Considerations

### Access Control
- Only owner can create pools
- Anyone can stake
- Anyone can view metrics

### Pool Risks
- Impermanent loss in volatile pools
- APY can decrease with more stakers
- Trading volume affects returns

### Smart Routing
- Auto-routing is gas-efficient
- Always picks best available pool
- Updates in real-time

---

## 🐛 Error Codes

| Code | Name | Description |
|------|------|-------------|
| 1 | E_NOT_OWNER | Caller is not owner |
| 2 | E_POOL_NOT_FOUND | Pool doesn't exist |
| 3 | E_ZERO_AMOUNT | Amount must be > 0 |
| 4 | E_INSUFFICIENT_BALANCE | Not enough tokens |
| 5 | E_POOL_ALREADY_EXISTS | Pool already created |
| 6 | E_INVALID_POOL_ID | Invalid pool ID |

---

## 🎯 Use Cases

### Conservative Investor
```
Strategy: Stake in stAPT-USDC pool
Risk: Low
APY: 10% + fees
Best for: Stable returns
```

### Aggressive Investor
```
Strategy: Stake in stAPT-BTC pool
Risk: High
APY: 12% + fees
Best for: Maximum yields
```

### Balanced Investor
```
Strategy: Use auto-routing
Risk: Dynamic
APY: Always highest available
Best for: Optimized returns
```

### Diversified Investor
```
Strategy: Split across multiple pools
Risk: Balanced
APY: Average of all pools
Best for: Risk management
```

---

## ✅ Integration Checklist

- [ ] Initialize staking pools
- [ ] Create multiple pools
- [ ] Test manual staking
- [ ] Test auto-routing
- [ ] Verify APY calculations
- [ ] Check pool metrics
- [ ] Monitor liquidity changes
- [ ] Test user positions
- [ ] Implement pool comparison
- [ ] Add error handling
- [ ] Set up APY monitoring
- [ ] Document pool risks
