# Deployment & Testing Checklist

## ✅ COMPILATION STATUS
```bash
✅ All modules compile successfully
✅ No errors, only warnings (unused imports)
✅ All dependencies resolved
✅ Address configured: 0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16
```

---

## 🚀 DEPLOYMENT SEQUENCE

### Step 1: Compile & Publish
```bash
# Compile to verify
aptos move compile

# Publish to testnet
aptos move publish --named-addresses yield_tokenization=0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16
```

### Step 2: Initialize Core Modules (Protocol Owner)
```bash
# 1. Initialize stAPT token
aptos move run \
  --function-id '0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16::oracles_and_mocks::init_stapt_token'

# 2. Initialize Pyth oracle
aptos move run \
  --function-id '0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16::oracles_and_mocks::init_pyth_oracle'

# 3. Initialize SY Wrapper
aptos move run \
  --function-id '0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16::tokenization::initialize_sy_wrapper' \
  --args \
    address:0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16 \
    string:b"Standardized Yield stAPT" \
    string:b"SY-stAPT"

# 4. Initialize PT/YT Tokenization
aptos move run \
  --function-id '0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16::tokenization::initialize' \
  --type-args '0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16::tokenization::SYToken' \
  --args address:0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16

# 5. Initialize AMM Factory
aptos move run \
  --function-id '0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16::pt_yt_amm::initialize_amm_factory'

# 6. Initialize Multi-Pool Staking
aptos move run \
  --function-id '0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16::multi_lp_staking::initialize_staking_pools'
```

### Step 3: Create Maturities (Protocol Owner)
```bash
# Calculate maturity timestamps
# 3 months: current_timestamp + (90 * 24 * 60 * 60) = current + 7776000
# 6 months: current_timestamp + (180 * 24 * 60 * 60) = current + 15552000
# 1 year: current_timestamp + (365 * 24 * 60 * 60) = current + 31536000

# Create 3-month maturity
aptos move run \
  --function-id '0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16::tokenization::create_maturity' \
  --type-args '0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16::tokenization::SYToken' \
  --args \
    u64:MATURITY_3M_TIMESTAMP \
    string:b"3 Months"

# Create 6-month maturity
aptos move run \
  --function-id '0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16::tokenization::create_maturity' \
  --type-args '0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16::tokenization::SYToken' \
  --args \
    u64:MATURITY_6M_TIMESTAMP \
    string:b"6 Months"

# Create 1-year maturity
aptos move run \
  --function-id '0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16::tokenization::create_maturity' \
  --type-args '0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16::tokenization::SYToken' \
  --args \
    u64:MATURITY_1Y_TIMESTAMP \
    string:b"1 Year"
```

### Step 4: Create Staking Pools (Protocol Owner)
```bash
# Create stAPT-USDC pool (10% APY)
aptos move run \
  --function-id '0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16::multi_lp_staking::create_staking_pool' \
  --args \
    string:b"stAPT-USDC Pool" \
    string:b"stAPT-USDC" \
    address:0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16 \
    address:0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16 \
    u64:1000

# Create stAPT-BTC pool (12% APY)
aptos move run \
  --function-id '0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16::multi_lp_staking::create_staking_pool' \
  --args \
    string:b"stAPT-BTC Pool" \
    string:b"stAPT-BTC" \
    address:0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16 \
    address:0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16 \
    u64:1200

# Create stAPT-ETH pool (11% APY)
aptos move run \
  --function-id '0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16::multi_lp_staking::create_staking_pool' \
  --args \
    string:b"stAPT-ETH Pool" \
    string:b"stAPT-ETH" \
    address:0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16 \
    address:0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16 \
    u64:1100
```

---

## 🧪 USER TESTING SEQUENCE

### Test 1: Mint stAPT
```bash
aptos move run \
  --function-id '0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16::oracles_and_mocks::mint_stapt' \
  --args \
    address:0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16 \
    u64:1000000000

# Expected: User receives 10 stAPT (8 decimals)
```

### Test 2: Wrap stAPT to SY
```bash
aptos move run \
  --function-id '0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16::tokenization::deposit_stapt_for_sy' \
  --args \
    address:0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16 \
    u64:1000000000

# Expected: User receives 10 SY tokens (1:1 conversion)
```

### Test 3: Split SY into PT + YT
```bash
aptos move run \
  --function-id '0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16::tokenization::split' \
  --type-args '0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16::tokenization::SYToken' \
  --args \
    address:0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16 \
    u64:500000000 \
    u64:0

# Expected: User receives 5 PT + 5 YT for 6-month maturity
```

### Test 4: Create PT/YT Trading Pool
```bash
aptos move run \
  --function-id '0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16::pt_yt_amm::create_and_bootstrap_pool' \
  --args \
    address:0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16 \
    u64:MATURITY_6M_TIMESTAMP \
    u64:100000000 \
    u64:950

# Expected: Pool created with 1 PT + fair YT amount
# User receives LP tokens
```

### Test 5: Swap PT for YT
```bash
aptos move run \
  --function-id '0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16::pt_yt_amm::swap_pt_for_yt' \
  --args \
    address:0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16 \
    u64:0 \
    u64:10000000 \
    u64:0

# Expected: User swaps 0.1 PT for YT
# Trading fees collected (0.3%)
```

### Test 6: Swap YT for PT
```bash
aptos move run \
  --function-id '0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16::pt_yt_amm::swap_yt_for_pt' \
  --args \
    address:0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16 \
    u64:0 \
    u64:10000000 \
    u64:0

# Expected: User swaps 0.1 YT for PT
# Trading fees collected (0.3%)
```

### Test 7: Add Liquidity
```bash
aptos move run \
  --function-id '0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16::pt_yt_amm::add_liquidity_pt_yt' \
  --args \
    address:0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16 \
    u64:0 \
    u64:50000000 \
    u64:50000000

# Expected: User adds 0.5 PT + 0.5 YT
# User receives LP tokens proportional to pool share
```

### Test 8: Stake in Multi-Pool
```bash
aptos move run \
  --function-id '0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16::multi_lp_staking::stake_to_best_pool' \
  --args \
    address:0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16 \
    u64:100000000

# Expected: User stakes 1 SY in highest APY pool
# System auto-routes to best pool
```

---

## 📊 VIEW FUNCTIONS TO VERIFY

### Check stAPT Balance
```bash
aptos move view \
  --function-id '0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16::oracles_and_mocks::get_stapt_balance' \
  --args \
    address:0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16 \
    address:USER_ADDRESS
```

### Check SY Balance
```bash
aptos move view \
  --function-id '0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16::tokenization::get_sy_balance' \
  --args \
    address:0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16 \
    address:USER_ADDRESS
```

### Check PT Balance
```bash
aptos move view \
  --function-id '0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16::tokenization::get_user_pt_balance' \
  --type-args '0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16::tokenization::SYToken' \
  --args \
    address:USER_ADDRESS \
    u64:0
```

### Check YT Balance
```bash
aptos move view \
  --function-id '0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16::tokenization::get_user_yt_balance' \
  --type-args '0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16::tokenization::SYToken' \
  --args \
    address:USER_ADDRESS \
    u64:0
```

### Check Pool Reserves
```bash
aptos move view \
  --function-id '0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16::pt_yt_amm::get_pool_reserves' \
  --args \
    address:0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16 \
    u64:0
```

### Check PT Price
```bash
aptos move view \
  --function-id '0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16::pt_yt_amm::get_pt_price' \
  --args \
    address:0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16 \
    u64:0
```

### Check Implied APY
```bash
aptos move view \
  --function-id '0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16::pt_yt_amm::calculate_implied_apy' \
  --args \
    address:0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16 \
    u64:0
```

### Check Best Yield Pool
```bash
aptos move view \
  --function-id '0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16::multi_lp_staking::get_best_yield_pool' \
  --args \
    address:0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16
```

---

## ✅ SUCCESS CRITERIA

### Deployment Success:
- ✅ All modules published without errors
- ✅ All initialization functions execute successfully
- ✅ Maturities created (3M, 6M, 1Y)
- ✅ Staking pools created (3 pools)
- ✅ AMM factory initialized

### User Flow Success:
- ✅ Users can mint stAPT
- ✅ Users can wrap stAPT to SY
- ✅ Users can split SY into PT + YT
- ✅ Users can create PT/YT pools
- ✅ Users can trade PT ↔ YT
- ✅ Users can add liquidity
- ✅ Users can stake in multi-pools

### Trading Success:
- ✅ PT/YT swaps execute without errors
- ✅ Prices update correctly after trades
- ✅ Trading fees collected (0.3%)
- ✅ LP tokens minted correctly
- ✅ Implied APY calculated accurately

---

## 🚨 TROUBLESHOOTING

### If Compilation Fails:
```bash
# Check Move.toml address
cat Move.toml | grep yield_tokenization

# Should show:
# yield_tokenization = "0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16"
```

### If Initialization Fails:
```bash
# Check if already initialized
aptos move view --function-id 'ADDR::oracles_and_mocks::get_stapt_total_supply' --args address:ADDR

# If returns error, not initialized yet
# If returns 0, already initialized
```

### If Trading Fails:
```bash
# Check pool exists
aptos move view --function-id 'ADDR::pt_yt_amm::get_total_pools' --args address:ADDR

# Check pool has liquidity
aptos move view --function-id 'ADDR::pt_yt_amm::get_pool_reserves' --args address:ADDR u64:0

# Check maturity not expired
# Current time must be < maturity timestamp
```

---

## 📈 EXPECTED RESULTS

### After Deployment:
- Contract address: `0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16`
- Gas cost: ~0.05 APT
- Time: ~5 minutes

### After First User:
- Pool created with fair pricing
- Initial liquidity: User's PT + calculated YT
- LP tokens minted: sqrt(PT * YT)
- Trading enabled immediately

### After 10 Users:
- Multiple pools active
- Healthy liquidity across maturities
- Trading volume increasing
- Implied APY stabilizing

### After 1 Month:
- Established trading patterns
- LP fees accumulating
- Users earning yields
- System running smoothly

---

## ✅ FINAL CHECKLIST

- [x] Code compiles successfully
- [x] All modules compatible
- [x] Deployment sequence documented
- [x] Testing sequence documented
- [x] View functions documented
- [x] Troubleshooting guide included
- [x] Success criteria defined
- [x] Expected results documented

**System is ready for deployment and testing!** 🚀
