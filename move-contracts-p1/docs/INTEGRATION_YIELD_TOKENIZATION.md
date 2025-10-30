# 🔄 Yield Tokenization Contract Integration Guide

## Contract: `yield_tokenization.move`

**Module:** `yield_tokenization::tokenization`
**Address:** `0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16`

---

## 📋 Overview

This contract provides:
1. **SY Wrapper** - Standardized Yield wrapper for stAPT
2. **PT/YT Splitting** - Split yield into Principal + Yield tokens
3. **Multiple Maturities** - 3M, 6M, 1Y options
4. **Redemption** - Redeem PT for SY at maturity

---

## 🚀 Initialization Functions

### 1. Initialize SY Wrapper

```bash
aptos move run \
  --function-id 'ADDR::tokenization::initialize_sy_wrapper' \
  --args address:STAPT_ADDR string:b"NAME" string:b"SYMBOL"
```

**Parameters:**
- `stapt_oracle_addr`: Address of stAPT contract
- `name`: Token name (e.g., "Standardized_Yield_stAPT")
- `symbol`: Token symbol (e.g., "SY-stAPT")

**Example:**
```bash
--args address:0x7c6a... string:b"Standardized_Yield_stAPT" string:b"SY-stAPT"
```

**What it does:**
- Creates SY wrapper for stAPT
- Sets up 1:1 conversion mechanism
- Enables yield tokenization

**Required:** Must be called once by owner

**Gas Cost:** ~500 units

---

### 2. Initialize PT/YT Tokenization

```bash
aptos move run \
  --function-id 'ADDR::tokenization::initialize' \
  --type-args 'ADDR::tokenization::SYToken' \
  --args address:SY_WRAPPER_ADDR
```

**Parameters:**
- Type arg: SYToken type
- `sy_wrapper_addr`: Address of SY wrapper

**What it does:**
- Sets up PT/YT splitting system
- Links to SY wrapper
- Prepares for maturity creation

**Required:** Must be called once by owner

**Gas Cost:** ~500 units

---

### 3. Create Maturity

```bash
aptos move run \
  --function-id 'ADDR::tokenization::create_maturity' \
  --type-args 'ADDR::tokenization::SYToken' \
  --args u64:MATURITY_TIMESTAMP string:b"NAME"
```

**Parameters:**
- Type arg: SYToken type
- `maturity`: Unix timestamp when PT matures
- `name`: Maturity name (e.g., "6_Months")

**Example:**
```bash
# Create 6-month maturity
# Current time: 1761816349
# 6 months later: 1777368349
--args u64:1777368349 string:b"6_Months"
```

**What it does:**
- Creates new maturity option
- Enables PT/YT for this timeframe
- Sets redemption date

**Can be called by:** Owner
**Frequency:** As needed for new maturities

**Gas Cost:** ~20 units

---

## 💰 User Functions

### 4. Deposit stAPT for SY

```bash
aptos move run \
  --function-id 'ADDR::tokenization::deposit_stapt_for_sy' \
  --args address:SY_WRAPPER_ADDR u64:AMOUNT
```

**Parameters:**
- `sy_wrapper_addr`: SY wrapper address
- `amount`: stAPT amount to wrap (8 decimals)

**Example:**
```bash
# Wrap 10 stAPT
--args address:0x7c6a... u64:1000000000
```

**What it does:**
- Wraps stAPT → SY (1:1)
- User receives SY tokens
- Maintains yield exposure

**Returns:** SY tokens to user

**Gas Cost:** ~22 units

---

### 5. Redeem SY for stAPT

```bash
aptos move run \
  --function-id 'ADDR::tokenization::redeem_sy_for_stapt' \
  --args address:SY_WRAPPER_ADDR u64:AMOUNT
```

**Parameters:**
- `sy_wrapper_addr`: SY wrapper address
- `amount`: SY amount to redeem (8 decimals)

**What it does:**
- Redeems SY → stAPT (1:1)
- Burns SY tokens
- Returns stAPT to user

**Gas Cost:** ~25 units

---

### 6. Split SY into PT + YT

```bash
aptos move run \
  --function-id 'ADDR::tokenization::split' \
  --type-args 'ADDR::tokenization::SYToken' \
  --args address:TOKENIZATION_ADDR u64:AMOUNT u64:MATURITY_IDX
```

**Parameters:**
- Type arg: SYToken type
- `tokenization_addr`: Tokenization contract address
- `amount`: SY amount to split (8 decimals)
- `maturity_idx`: Maturity index (0, 1, 2...)

**Example:**
```bash
# Split 5 SY into PT + YT (6-month maturity)
--args address:0x7c6a... u64:500000000 u64:0
```

**What it does:**
- Splits SY → PT + YT (1:1:1 ratio)
- User receives equal PT and YT
- Locks SY until maturity

**Returns:** PT + YT tokens to user

**Gas Cost:** ~480 units

---

### 7. Redeem PT at Maturity

```bash
aptos move run \
  --function-id 'ADDR::tokenization::redeem' \
  --type-args 'ADDR::tokenization::SYToken' \
  --args address:TOKENIZATION_ADDR u64:PT_AMOUNT u64:MATURITY_IDX
```

**Parameters:**
- Type arg: SYToken type
- `tokenization_addr`: Tokenization contract address
- `pt_amount`: PT amount to redeem (8 decimals)
- `maturity_idx`: Maturity index

**What it does:**
- Redeems PT → SY (1:1)
- Only works after maturity
- Burns PT tokens

**Returns:** SY tokens to user

**Requirement:** Current time >= maturity

**Gas Cost:** ~30 units

---

## 📊 View Functions

### 8. Get SY Balance

```bash
aptos move view \
  --function-id 'ADDR::tokenization::get_sy_balance' \
  --args address:SY_WRAPPER_ADDR address:USER_ADDR
```

**Returns:** User's SY balance (u64)

**Example Response:** `1000000000` (10 SY)

---

### 9. Get PT Balance

```bash
aptos move view \
  --function-id 'ADDR::tokenization::get_user_pt_balance' \
  --type-args 'ADDR::tokenization::SYToken' \
  --args address:USER_ADDR u64:MATURITY_IDX
```

**Parameters:**
- Type arg: SYToken type
- `user_addr`: User address
- `maturity_idx`: Maturity index

**Returns:** User's PT balance for that maturity (u64)

---

### 10. Get YT Balance

```bash
aptos move view \
  --function-id 'ADDR::tokenization::get_user_yt_balance' \
  --type-args 'ADDR::tokenization::SYToken' \
  --args address:USER_ADDR u64:MATURITY_IDX
```

**Returns:** User's YT balance for that maturity (u64)

---

### 11. Get All Maturities

```bash
aptos move view \
  --function-id 'ADDR::tokenization::get_maturities' \
  --type-args 'ADDR::tokenization::SYToken' \
  --args address:TOKENIZATION_ADDR
```

**Returns:** Array of maturity timestamps

**Example Response:** `[1777368349, 1792920349]` (6M, 1Y)

---

### 12. Get SY Total Supply

```bash
aptos move view \
  --function-id 'ADDR::tokenization::get_sy_total_supply' \
  --args address:SY_WRAPPER_ADDR
```

**Returns:** Total SY tokens in circulation (u64)

---

### 13. Get SY Exchange Rate

```bash
aptos move view \
  --function-id 'ADDR::tokenization::get_sy_exchange_rate' \
  --args address:SY_WRAPPER_ADDR
```

**Returns:** SY to stAPT exchange rate (u64, 8 decimals)

**Example Response:** `100000000` (1.0 = 1:1 ratio)

---

## 🔧 Integration Examples

### Example 1: Complete Tokenization Flow

```typescript
// 1. Wrap stAPT to SY
const wrapAmount = 1000000000; // 10 stAPT

await client.submitTransaction({
  function: `${CONTRACT_ADDR}::tokenization::deposit_stapt_for_sy`,
  arguments: [SY_WRAPPER_ADDR, wrapAmount],
  type_arguments: []
});

// 2. Split SY into PT + YT
const splitAmount = 500000000; // 5 SY
const maturityIdx = 0; // 6-month maturity

await client.submitTransaction({
  function: `${CONTRACT_ADDR}::tokenization::split`,
  arguments: [TOKENIZATION_ADDR, splitAmount, maturityIdx],
  type_arguments: [`${CONTRACT_ADDR}::tokenization::SYToken`]
});

// 3. Check balances
const ptBalance = await client.view({
  function: `${CONTRACT_ADDR}::tokenization::get_user_pt_balance`,
  arguments: [userAddress, maturityIdx],
  type_arguments: [`${CONTRACT_ADDR}::tokenization::SYToken`]
});

console.log(`PT Balance: ${ptBalance[0] / 100000000}`);
```

---

### Example 2: Redeem at Maturity

```typescript
// 1. Check if matured
const maturities = await client.view({
  function: `${CONTRACT_ADDR}::tokenization::get_maturities`,
  arguments: [TOKENIZATION_ADDR],
  type_arguments: [`${CONTRACT_ADDR}::tokenization::SYToken`]
});

const currentTime = Math.floor(Date.now() / 1000);
const maturityTime = parseInt(maturities[0][0]);

if (currentTime >= maturityTime) {
  // 2. Redeem PT for SY
  const ptAmount = 500000000; // 5 PT
  
  await client.submitTransaction({
    function: `${CONTRACT_ADDR}::tokenization::redeem`,
    arguments: [TOKENIZATION_ADDR, ptAmount, 0],
    type_arguments: [`${CONTRACT_ADDR}::tokenization::SYToken`]
  });
  
  console.log('PT redeemed for SY!');
} else {
  console.log(`Matures in ${maturityTime - currentTime} seconds`);
}
```

---

## 📈 Token Flow Diagram

```
stAPT (9.5% APY)
    ↓ [deposit_stapt_for_sy]
SY-stAPT (1:1 with stAPT)
    ↓ [split]
PT-stAPT + YT-stAPT (1:1:1 ratio)
    ↓ [redeem at maturity]
SY-stAPT (1:1 redemption)
    ↓ [redeem_sy_for_stapt]
stAPT (original + yield)
```

---

## 📊 Economic Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| SY:stAPT Ratio | 1:1 | Always equal |
| Split Ratio | 1:1:1 | 1 SY → 1 PT + 1 YT |
| Redemption | 1:1 | 1 PT → 1 SY at maturity |
| Decimals | 8 | All tokens |
| Min Amount | 0.01 | Minimum operation |

---

## ⚠️ Important Notes

### Maturity Management
- Create maturities before users can split
- Use clear naming (3_Months, 6_Months, 1_Year)
- Calculate timestamps carefully

### Token Ratios
- SY always 1:1 with stAPT
- Splitting always 1:1:1 (SY → PT + YT)
- Redemption always 1:1 (PT → SY)

### Yield Tracking
- YT holders receive all yield until maturity
- PT holders get fixed principal
- SY maintains yield exposure

---

## 🔐 Security Considerations

### Access Control
- Only owner can initialize
- Only owner can create maturities
- Users control their own tokens

### Maturity Checks
- PT redemption only after maturity
- Timestamp validation on creation
- No early redemption allowed

### Balance Tracking
- Per-user, per-maturity tracking
- Separate PT and YT balances
- Safe arithmetic operations

---

## 🐛 Error Codes

| Code | Name | Description |
|------|------|-------------|
| 1 | E_NOT_OWNER | Caller is not owner |
| 2 | E_INVALID_MATURITY | Invalid maturity timestamp |
| 3 | E_ZERO_AMOUNT | Amount must be > 0 |
| 4 | E_NOT_MATURE | PT not yet redeemable |
| 5 | E_INSUFFICIENT_BALANCE | Not enough tokens |
| 6 | E_INVALID_ORACLE | Oracle not initialized |
| 7 | E_PRICE_TOO_OLD | Price data stale |
| 8 | E_SY_NOT_INITIALIZED | SY wrapper not set up |

---

## ✅ Integration Checklist

- [ ] Initialize SY wrapper
- [ ] Initialize tokenization
- [ ] Create maturities (3M, 6M, 1Y)
- [ ] Test stAPT → SY wrapping
- [ ] Test SY → PT+YT splitting
- [ ] Verify balance tracking
- [ ] Test PT redemption
- [ ] Test SY → stAPT unwrapping
- [ ] Implement maturity checks
- [ ] Add error handling
