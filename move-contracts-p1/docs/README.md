# 📚 Integration Documentation

Complete integration guides for the Pendle-style yield trading protocol on Aptos.

---

## 📖 Documentation Index

### 🎯 Start Here
- **[Frontend Integration Guide](./FRONTEND_INTEGRATION.md)** - 🆕 Quick start for UI developers (matches FRONTEND_UI_BRIEF.md)
- **[Master Integration Guide](./INTEGRATION_MASTER_GUIDE.md)** - Complete integration overview with code examples

### 📋 Individual Contract Guides

1. **[Oracles & Mocks](./INTEGRATION_ORACLES_AND_MOCKS.md)**
   - stAPT token with 9.5% APY
   - Price oracles (Pyth Network)
   - Mock tokens for testing
   - Yield calculations

2. **[Yield Tokenization](./INTEGRATION_YIELD_TOKENIZATION.md)**
   - SY (Standardized Yield) wrapper
   - PT/YT splitting mechanism
   - Maturity management
   - Redemption flows

3. **[PT/YT AMM](./INTEGRATION_PT_YT_AMM.md)**
   - Constant product AMM (x*y=k)
   - Fair pricing mechanism
   - Trading functions
   - Liquidity provision

4. **[Multi-Pool Staking](./INTEGRATION_MULTI_LP_STAKING.md)**
   - Multiple staking pools
   - Auto-routing to best yields
   - Dynamic APY calculations
   - Pool metrics

---

## 🚀 Quick Start

### For Developers

```typescript
// 1. Install dependencies
npm install aptos

// 2. Import protocol
import { AptosClient } from "aptos";

const client = new AptosClient("https://fullnode.testnet.aptoslabs.com");
const CONTRACT = "0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16";

// 3. Start integrating!
// See INTEGRATION_MASTER_GUIDE.md for complete examples
```

### For Users

1. **Stake APT** → Get stAPT (9.5% APY)
2. **Wrap stAPT** → Get SY tokens
3. **Split SY** → Get PT + YT tokens
4. **Trade PT/YT** → Optimize your yield strategy

---

## 📊 Contract Overview

| Contract | Purpose | Key Features |
|----------|---------|--------------|
| **oracles_and_mocks** | Yield generation | stAPT, price feeds, 9.5% APY |
| **yield_tokenization** | Token splitting | SY wrapper, PT/YT creation |
| **pt_yt_amm** | Trading | AMM, fair pricing, 0.3% fees |
| **multi_lp_staking** | Yield optimization | Multiple pools, auto-routing |

---

## 🔄 Complete User Flow

```
APT (Native Token)
  ↓ [Stake]
stAPT (9.5% APY auto-compounding)
  ↓ [Wrap]
SY-stAPT (Standardized Yield)
  ↓ [Split]
PT-stAPT + YT-stAPT (Principal + Yield)
  ↓ [Trade/Stake]
Optimized Yield Strategies
```

---

## 💡 Integration Patterns

### Pattern 1: Fixed-Rate Strategy
```typescript
// Lock in guaranteed returns
stake() → wrap() → split() → sellYT() → holdPT()
// Result: Fixed APY, zero risk
```

### Pattern 2: Yield Speculation
```typescript
// Bet on higher yields
stake() → wrap() → split() → buyYT() → profit()
// Result: High risk/reward
```

### Pattern 3: Liquidity Mining
```typescript
// Earn trading fees
stake() → wrap() → split() → provideLiquidity()
// Result: 0.3% fees + base yield
```

### Pattern 4: Yield Optimization
```typescript
// Auto-route to best pools
stake() → wrap() → stakeInBestPool()
// Result: Always highest APY
```

---

## 📈 Key Metrics

### Economic Parameters
- **stAPT APY:** 9.5% (950 basis points)
- **Trading Fee:** 0.3% (30 basis points)
- **Pool APYs:** 10-12% base + bonuses
- **Decimals:** 8 (all tokens)
- **Min Amount:** 0.01 tokens

### Contract Info
- **Network:** Aptos Testnet
- **Address:** `0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16`
- **Status:** ✅ Fully deployed and tested
- **Gas Costs:** ~500 units (initialization), ~6-30 units (operations)

---

## 🔧 Function Categories

### Initialization (Owner Only)
- `init_stapt_token()` - Create stAPT
- `init_pyth_oracle()` - Setup price feeds
- `initialize_sy_wrapper()` - Create SY wrapper
- `initialize()` - Setup tokenization
- `create_maturity()` - Add maturity options
- `initialize_amm_factory()` - Create AMM
- `initialize_staking_pools()` - Setup staking

### User Operations
- `mint_stapt()` - Stake APT
- `deposit_stapt_for_sy()` - Wrap to SY
- `split()` - Create PT + YT
- `swap_pt_for_yt()` - Trade PT → YT
- `swap_yt_for_pt()` - Trade YT → PT
- `add_liquidity_pt_yt()` - Provide liquidity
- `stake_to_best_pool()` - Auto-stake

### View Functions
- `get_stapt_balance()` - Check stAPT
- `get_sy_balance()` - Check SY
- `get_user_pt_balance()` - Check PT
- `get_user_yt_balance()` - Check YT
- `get_pool_reserves()` - Pool liquidity
- `calculate_implied_apy()` - Market APY
- `get_best_yield_pool()` - Highest APY pool

---

## ⚠️ Important Notes

### Before Integration
1. Read the Master Integration Guide
2. Understand the token flow
3. Test on testnet first
4. Implement error handling
5. Add slippage protection

### Security Considerations
- Validate all inputs
- Check maturity timestamps
- Monitor price staleness
- Handle errors gracefully
- Use slippage limits

### Best Practices
- Batch view calls for efficiency
- Cache frequently used data
- Monitor gas costs
- Test edge cases
- Document your integration

---

## 🐛 Common Issues

### Issue: Transaction Fails
**Solution:** Check error codes in contract guides

### Issue: Slippage Too High
**Solution:** Increase slippage tolerance or reduce trade size

### Issue: Pool Not Found
**Solution:** Verify pool exists and maturity hasn't expired

### Issue: Insufficient Balance
**Solution:** Check user has enough tokens

---

## 📞 Support

### Documentation
- Master Guide: Complete integration examples
- Contract Guides: Detailed function documentation
- Code Examples: TypeScript integration patterns

### Resources
- **Testnet Explorer:** [View Contract](https://explorer.aptoslabs.com/account/0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16?network=testnet)
- **Aptos Docs:** [docs.aptos.dev](https://aptos.dev)
- **Move Language:** [move-language.github.io](https://move-language.github.io)

---

## ✅ Integration Checklist

### Setup Phase
- [ ] Read Master Integration Guide
- [ ] Review individual contract guides
- [ ] Setup Aptos client
- [ ] Configure contract addresses
- [ ] Test connection

### Development Phase
- [ ] Implement staking flow
- [ ] Implement wrapping flow
- [ ] Implement splitting flow
- [ ] Implement trading interface
- [ ] Add liquidity features
- [ ] Implement view functions

### Testing Phase
- [ ] Test all user flows
- [ ] Test error handling
- [ ] Test slippage protection
- [ ] Test edge cases
- [ ] Performance testing

### Production Phase
- [ ] Security audit
- [ ] Gas optimization
- [ ] Monitoring setup
- [ ] Documentation
- [ ] Launch! 🚀

---

## 🎉 Ready to Build!

Start with the **[Master Integration Guide](./INTEGRATION_MASTER_GUIDE.md)** for a complete overview, then dive into individual contract guides for detailed documentation.

**Happy Integrating!** 🚀
