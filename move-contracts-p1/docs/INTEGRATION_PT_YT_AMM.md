# 💱 PT/YT AMM Contract Integration Guide

## Contract: `pt_yt_amm.move`

**Module:** `yield_tokenization::pt_yt_amm`
**Address:** `0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16`

---

## 📋 Overview

This contract provides:
1. **PT/YT Trading** - Constant product (x*y=k) AMM
2. **Fair Pricing** - Anti-arbitrage pool creation
3. **Liquidity Provision** - Earn 0.3% trading fees
4. **Implied APY** - Market-driven yield expectations

---

## 🚀 Initialization Functions

### 1. Initialize AMM Factory

```bash
aptos move run \
  --function-id 'ADDR::pt_yt_amm::initialize_amm_factory'
```

**What it does:**
- Creates AMM factory for PT/YT pools
- Sets up pool tracking
- Enables pool creation

**Required:** Must be called once by owner

**Gas Cost:** ~465 units

---

## 💰 Pool Creation Functions

### 2. Create Pool with Fair Pricing (RECOMMENDED)

```bash
aptos move run \
  --function-id 'ADDR::pt_yt_amm::create_and_bootstrap_pool' \
  --args address:FACTORY_ADDR u64:MATURITY u64:PT_AMOUNT u64:EXPECTED_APY_BPS
```

**Parameters:**
- `factory_addr`: AMM factory address
- `maturity`: Maturity timestamp
- `pt_amount`: PT amount to provide (8 decimals)
- `expected_apy_bps`: Expected APY in basis points (e.g., 950 = 9.5%)

**Example:**
```bash
# Create pool with 1 PT, 6-month maturity, 9.5% APY
--args address:0x7c6a... u64:1777368349 u64:100000000 u64:950
```

**What it does:**
- Creates new PT/YT pool
- Calculates fair YT amount automatically
- Prevents arbitrage on launch
- Mints LP tokens to creator

**Returns:** LP tokens to user

**Gas Cost:** ~500 units

**Fair Pricing Formula:**
```
PT_price = 1 - (APY * time_to_maturity / 1_year)
YT_price = 1 - PT_price
YT_amount = PT_amount * (YT_price / PT_price)
```

---

### 3. Create Pool with Manual Ratio (Advanced)

```bash
aptos move run \
  --function-id 'ADDR::pt_yt_amm::create_pt_yt_pool' \
  --args address:FACTORY_ADDR u64:MATURITY u64:PT_AMOUNT u64:YT_AMOUNT
```

**Parameters:**
- `factory_addr`: AMM factory address
- `maturity`: Maturity timestamp
- `initial_pt`: PT amount (8 decimals)
- `initial_yt`: YT amount (8 decimals)

**Warning:** Use with caution - can create arbitrage opportunities

**Gas Cost:** ~500 units

---

## 🔄 Trading Functions

### 4. Swap PT for YT

```bash
aptos move run \
  --function-id 'ADDR::pt_yt_amm::swap_pt_for_yt' \
  --args address:FACTORY_ADDR u64:POOL_ID u64:PT_IN u64:MIN_YT_OUT
```

**Parameters:**
- `factory_addr`: AMM factory address
- `pool_id`: Pool ID (usually 0 for first pool)
- `pt_amount_in`: PT amount to swap (8 decimals)
- `min_yt_out`: Minimum YT to receive (slippage protection)

**Example:**
```bash
# Swap 0.1 PT for YT (no slippage limit)
--args address:0x7c6a... u64:0 u64:10000000 u64:0
```

**What it does:**
- Swaps PT → YT using x*y=k formula
- Charges 0.3% trading fee
- Updates pool reserves
- Emits swap event

**Formula:**
```
YT_out = (YT_reserve * PT_in_with_fee) / (PT_reserve + PT_in_with_fee)
Fee = PT_in * 0.003
```

**Gas Cost:** ~6 units

---

### 5. Swap YT for PT

```bash
aptos move run \
  --function-id 'ADDR::pt_yt_amm::swap_yt_for_pt' \
  --args address:FACTORY_ADDR u64:POOL_ID u64:YT_IN u64:MIN_PT_OUT
```

**Parameters:**
- `factory_addr`: AMM factory address
- `pool_id`: Pool ID
- `yt_amount_in`: YT amount to swap (8 decimals)
- `min_pt_out`: Minimum PT to receive

**Example:**
```bash
# Swap 0.01 YT for PT
--args address:0x7c6a... u64:0 u64:1000000 u64:0
```

**What it does:**
- Swaps YT → PT using x*y=k formula
- Charges 0.3% trading fee
- Updates pool reserves

**Gas Cost:** ~6 units

---

## 💧 Liquidity Functions

### 6. Add Liquidity

```bash
aptos move run \
  --function-id 'ADDR::pt_yt_amm::add_liquidity_pt_yt' \
  --args address:FACTORY_ADDR u64:POOL_ID u64:PT_AMOUNT u64:YT_AMOUNT
```

**Parameters:**
- `factory_addr`: AMM factory address
- `pool_id`: Pool ID
- `pt_amount`: PT amount to add (8 decimals)
- `yt_amount`: YT amount to add (8 decimals)

**Example:**
```bash
# Add 0.5 PT + 0.5 YT liquidity
--args address:0x7c6a... u64:0 u64:50000000 u64:50000000
```

**What it does:**
- Adds PT + YT to pool
- Mints LP tokens proportionally
- User earns 0.3% of trading fees

**LP Token Formula:**
```
LP_tokens = min(
  (PT_amount * LP_supply) / PT_reserve,
  (YT_amount * LP_supply) / YT_reserve
)
```

**Gas Cost:** ~30 units

---

## 📊 View Functions

### 7. Get Pool Reserves

```bash
aptos move view \
  --function-id 'ADDR::pt_yt_amm::get_pool_reserves' \
  --args address:FACTORY_ADDR u64:POOL_ID
```

**Returns:** `[PT_reserve, YT_reserve]`

**Example Response:** `[100000000, 4915066]` (1 PT, 0.049 YT)

---

### 8. Get PT Price

```bash
aptos move view \
  --function-id 'ADDR::pt_yt_amm::get_pt_price' \
  --args address:FACTORY_ADDR u64:POOL_ID
```

**Returns:** PT price in YT (u64, 8 decimals)

**Formula:** `PT_price = YT_reserve / PT_reserve`

**Example Response:** `4915066` (0.049 YT per PT)

---

### 9. Get YT Price

```bash
aptos move view \
  --function-id 'ADDR::pt_yt_amm::get_yt_price' \
  --args address:FACTORY_ADDR u64:POOL_ID
```

**Returns:** YT price in PT (u64, 8 decimals)

**Formula:** `YT_price = PT_reserve / YT_reserve`

---

### 10. Calculate Implied APY

```bash
aptos move view \
  --function-id 'ADDR::pt_yt_amm::calculate_implied_apy' \
  --args address:FACTORY_ADDR u64:POOL_ID
```

**Returns:** Implied APY in basis points (u64)

**Formula:**
```
Implied_APY = (YT_price / PT_price) * (365 / days_to_maturity) * 100
```

**Example Response:** `950` (9.5% APY)

---

### 11. Get Pool Info

```bash
aptos move view \
  --function-id 'ADDR::pt_yt_amm::get_pool_info' \
  --args address:FACTORY_ADDR u64:POOL_ID
```

**Returns:** `[maturity, pt_reserve, yt_reserve, lp_supply, volume_24h]`

---

### 12. Get Total Pools

```bash
aptos move view \
  --function-id 'ADDR::pt_yt_amm::get_total_pools' \
  --args address:FACTORY_ADDR
```

**Returns:** Number of pools created (u64)

---

### 13. Get User LP Balance

```bash
aptos move view \
  --function-id 'ADDR::pt_yt_amm::get_user_lp_balance' \
  --args address:USER_ADDR u64:POOL_ID
```

**Returns:** User's LP token balance (u64)

---

### 14. Preview Fair YT Amount

```bash
aptos move view \
  --function-id 'ADDR::pt_yt_amm::preview_fair_yt_amount' \
  --args u64:PT_AMOUNT u64:MATURITY u64:EXPECTED_APY_BPS
```

**Parameters:**
- `pt_amount`: PT amount
- `maturity`: Maturity timestamp
- `expected_apy_bps`: Expected APY (basis points)

**Returns:** Fair YT amount for given PT

**Example:**
```bash
# Preview for 1 PT, 6 months, 9.5% APY
--args u64:100000000 u64:1777368349 u64:950
```

---

## 🔧 Integration Examples

### Example 1: Create Pool and Trade

```typescript
// 1. Create pool with fair pricing
const maturity = 1777368349; // 6 months from now
const ptAmount = 100000000; // 1 PT
const expectedAPY = 950; // 9.5%

await client.submitTransaction({
  function: `${CONTRACT_ADDR}::pt_yt_amm::create_and_bootstrap_pool`,
  arguments: [FACTORY_ADDR, maturity, ptAmount, expectedAPY],
  type_arguments: []
});

// 2. Swap PT for YT
const swapAmount = 10000000; // 0.1 PT
const minYTOut = 0; // No slippage limit

await client.submitTransaction({
  function: `${CONTRACT_ADDR}::pt_yt_amm::swap_pt_for_yt`,
  arguments: [FACTORY_ADDR, 0, swapAmount, minYTOut],
  type_arguments: []
});

// 3. Check new reserves
const reserves = await client.view({
  function: `${CONTRACT_ADDR}::pt_yt_amm::get_pool_reserves`,
  arguments: [FACTORY_ADDR, 0],
  type_arguments: []
});

console.log(`PT: ${reserves[0][0] / 100000000}, YT: ${reserves[0][1] / 100000000}`);
```

---

### Example 2: Provide Liquidity

```typescript
// 1. Check current reserves
const reserves = await client.view({
  function: `${CONTRACT_ADDR}::pt_yt_amm::get_pool_reserves`,
  arguments: [FACTORY_ADDR, 0],
  type_arguments: []
});

const ptReserve = parseInt(reserves[0][0]);
const ytReserve = parseInt(reserves[0][1]);

// 2. Calculate proportional amounts
const ptToAdd = 50000000; // 0.5 PT
const ytToAdd = (ptToAdd * ytReserve) / ptReserve;

// 3. Add liquidity
await client.submitTransaction({
  function: `${CONTRACT_ADDR}::pt_yt_amm::add_liquidity_pt_yt`,
  arguments: [FACTORY_ADDR, 0, ptToAdd, ytToAdd],
  type_arguments: []
});

// 4. Check LP balance
const lpBalance = await client.view({
  function: `${CONTRACT_ADDR}::pt_yt_amm::get_user_lp_balance`,
  arguments: [userAddress, 0],
  type_arguments: []
});

console.log(`LP Tokens: ${lpBalance[0] / 100000000}`);
```

---

### Example 3: Calculate Slippage

```typescript
// 1. Get current price
const ptPrice = await client.view({
  function: `${CONTRACT_ADDR}::pt_yt_amm::get_pt_price`,
  arguments: [FACTORY_ADDR, 0],
  type_arguments: []
});

// 2. Calculate expected output
const ptIn = 10000000; // 0.1 PT
const expectedYTOut = (ptIn * parseInt(ptPrice[0])) / 100000000;

// 3. Set slippage tolerance (1%)
const slippageTolerance = 0.01;
const minYTOut = Math.floor(expectedYTOut * (1 - slippageTolerance));

// 4. Execute swap with slippage protection
await client.submitTransaction({
  function: `${CONTRACT_ADDR}::pt_yt_amm::swap_pt_for_yt`,
  arguments: [FACTORY_ADDR, 0, ptIn, minYTOut],
  type_arguments: []
});
```

---

## 📈 Economic Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| Trading Fee | 0.3% | Fee on all swaps |
| AMM Formula | x*y=k | Constant product |
| Min Liquidity | 1,000 | Minimum LP tokens |
| Decimals | 8 | Token precision |
| Fee Distribution | 100% to LPs | All fees to liquidity providers |

---

## ⚠️ Important Notes

### Fair Pricing
- Always use `create_and_bootstrap_pool` for new pools
- Prevents arbitrage opportunities
- Protects first liquidity providers

### Trading Mechanics
- 0.3% fee on every swap
- Fees distributed to LP token holders
- Price impact increases with trade size

### Liquidity Provision
- Add proportional amounts of PT and YT
- Receive LP tokens representing pool share
- Earn fees from all trades

### Maturity Handling
- Trading disabled after maturity
- Pools become inactive
- Users should redeem PT before maturity

---

## 🔐 Security Considerations

### Access Control
- Anyone can create pools
- Anyone can trade
- Anyone can provide liquidity

### Price Manipulation
- Large trades have price impact
- Use slippage protection
- Monitor implied APY

### Liquidity Risks
- Impermanent loss possible
- Pool ratio changes with trades
- LP tokens represent pool share

---

## 🐛 Error Codes

| Code | Name | Description |
|------|------|-------------|
| 1 | E_NOT_OWNER | Caller is not owner |
| 2 | E_POOL_NOT_FOUND | Pool doesn't exist |
| 3 | E_ZERO_AMOUNT | Amount must be > 0 |
| 4 | E_INSUFFICIENT_BALANCE | Not enough tokens |
| 5 | E_INSUFFICIENT_LIQUIDITY | Pool liquidity too low |
| 6 | E_SLIPPAGE_EXCEEDED | Output below minimum |
| 7 | E_POOL_ALREADY_EXISTS | Pool for maturity exists |
| 8 | E_INVALID_MATURITY | Invalid maturity time |
| 9 | E_MATURITY_EXPIRED | Pool expired |

---

## ✅ Integration Checklist

- [ ] Initialize AMM factory
- [ ] Create pool with fair pricing
- [ ] Test PT → YT swap
- [ ] Test YT → PT swap
- [ ] Verify price updates
- [ ] Test liquidity provision
- [ ] Check LP token minting
- [ ] Calculate implied APY
- [ ] Implement slippage protection
- [ ] Monitor pool reserves
- [ ] Handle maturity expiration
- [ ] Add error handling
