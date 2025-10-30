# 🧪 Testing Summary - Quick Reference

## Complete Flow in Order

### 1️⃣ DEPLOY (1 command)
```bash
.\aptos move publish --profile pendle_complete --assume-yes
```

### 2️⃣ INITIALIZE (7 commands)
```bash
# stAPT
.\aptos move run --profile pendle_complete --function-id '0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16::oracles_and_mocks::init_stapt_token' --assume-yes

# Oracle
.\aptos move run --profile pendle_complete --function-id '0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16::oracles_and_mocks::init_pyth_oracle' --assume-yes

# SY Wrapper
.\aptos move run --profile pendle_complete --function-id '0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16::tokenization::initialize_sy_wrapper' --args address:0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16 string:b"SY-stAPT" string:b"SY-stAPT" --assume-yes

# Tokenization
.\aptos move run --profile pendle_complete --function-id '0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16::tokenization::initialize' --type-args '0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16::tokenization::SYToken' --args address:0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16 --assume-yes

# Maturity (get timestamp first, add 15552000)
.\aptos move run --profile pendle_complete --function-id '0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16::tokenization::create_maturity' --type-args '0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16::tokenization::SYToken' --args u64:MATURITY_TIMESTAMP string:b"6_Months" --assume-yes

# AMM
.\aptos move run --profile pendle_complete --function-id '0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16::pt_yt_amm::initialize_amm_factory' --assume-yes

# Staking
.\aptos move run --profile pendle_complete --function-id '0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16::multi_lp_staking::initialize_staking_pools' --assume-yes
```

### 3️⃣ USER FLOW (4 commands)
```bash
# Mint stAPT
.\aptos move run --profile pendle_complete --function-id '0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16::oracles_and_mocks::mint_stapt' --args address:0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16 u64:1000000000 --assume-yes

# Wrap to SY
.\aptos move run --profile pendle_complete --function-id '0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16::tokenization::deposit_stapt_for_sy' --args address:0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16 u64:1000000000 --assume-yes

# Split to PT+YT
.\aptos move run --profile pendle_complete --function-id '0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16::tokenization::split' --type-args '0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16::tokenization::SYToken' --args address:0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16 u64:500000000 u64:0 --assume-yes

# Create Pool
.\aptos move run --profile pendle_complete --function-id '0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16::pt_yt_amm::create_and_bootstrap_pool' --args address:0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16 u64:MATURITY_TIMESTAMP u64:100000000 u64:950 --assume-yes
```

### 4️⃣ TRADING (2 commands)
```bash
# Swap PT for YT
.\aptos move run --profile pendle_complete --function-id '0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16::pt_yt_amm::swap_pt_for_yt' --args address:0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16 u64:0 u64:10000000 u64:0 --assume-yes

# Swap YT for PT
.\aptos move run --profile pendle_complete --function-id '0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16::pt_yt_amm::swap_yt_for_pt' --args address:0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16 u64:0 u64:1000000 u64:0 --assume-yes
```

---

## Quick Verification Commands

```bash
# Check stAPT balance
.\aptos move view --function-id '0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16::oracles_and_mocks::get_stapt_balance' --args address:0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16 address:0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16

# Check pool reserves
.\aptos move view --function-id '0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16::pt_yt_amm::get_pool_reserves' --args address:0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16 u64:0

# Check implied APY
.\aptos move view --function-id '0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16::pt_yt_amm::calculate_implied_apy' --args address:0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16 u64:0
```

---

## Total Commands: 14 deploy + test commands

**Time:** ~20-30 minutes
**Result:** Complete protocol tested on testnet ✅
