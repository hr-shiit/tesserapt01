# PT/YT Pricing Mechanism Explained

## 🎯 How PT and YT Prices Are Determined

Your AMM uses **market-driven price discovery** through a constant product formula (x*y=k), similar to Uniswap V2.

---

## 📊 Price Calculation Formula

### PT Price (in terms of YT)
```move
PT_price = YT_reserve / PT_reserve
```

### YT Price (in terms of PT)
```move
YT_price = PT_reserve / YT_reserve
```

### Example
If pool has:
- **PT reserve**: 100 tokens
- **YT reserve**: 50 tokens

Then:
- **PT price** = 50 / 100 = **0.5 YT per PT**
- **YT price** = 100 / 50 = **2 PT per YT**

---

## 🔄 How Prices Change (Market Dynamics)

### Initial State
```
Pool created with:
- 100 PT
- 100 YT
- k = 100 × 100 = 10,000

PT price = 100/100 = 1.0 YT per PT
YT price = 100/100 = 1.0 PT per YT
```

### After Someone Buys PT (Swaps YT for PT)
```
User swaps 10 YT for PT:
- YT reserve: 100 → 110 (increased)
- PT reserve: 100 → ~91 (decreased)
- k still = 10,000

New PT price = 110/91 = 1.21 YT per PT ⬆️
New YT price = 91/110 = 0.83 PT per YT ⬇️

PT became MORE EXPENSIVE (demand increased)
YT became CHEAPER (supply increased)
```

### After Someone Buys YT (Swaps PT for YT)
```
User swaps 10 PT for YT:
- PT reserve: 100 → 110 (increased)
- YT reserve: 100 → ~91 (decreased)
- k still = 10,000

New PT price = 91/110 = 0.83 YT per PT ⬇️
New YT price = 110/91 = 1.21 PT per YT ⬆️

PT became CHEAPER (supply increased)
YT became MORE EXPENSIVE (demand increased)
```

---

## 💡 What Drives PT/YT Prices?

### 1. Time to Maturity
As maturity approaches, PT should approach 1:1 with underlying SY:

```
Far from maturity (1 year):
- PT price: ~0.90 SY (discounted)
- YT price: ~0.10 SY (captures future yield)
- PT + YT ≈ 1.0 SY

Close to maturity (1 week):
- PT price: ~0.99 SY (almost par)
- YT price: ~0.01 SY (little yield left)
- PT + YT ≈ 1.0 SY

At maturity:
- PT price: 1.0 SY (redeemable 1:1)
- YT price: 0.0 SY (worthless)
```

### 2. Expected Yield
Higher expected yield = Higher YT price:

```
If stAPT APY increases from 9.5% to 15%:
- YT becomes more valuable (more yield to capture)
- YT price increases
- PT price decreases (to maintain PT + YT ≈ 1.0)

If stAPT APY decreases from 9.5% to 5%:
- YT becomes less valuable (less yield to capture)
- YT price decreases
- PT price increases
```

### 3. Market Sentiment
Traders' expectations affect prices:

```
Bullish on yield:
- Traders buy YT → YT price ⬆️
- PT price ⬇️

Bearish on yield:
- Traders buy PT → PT price ⬆️
- YT price ⬇️

Risk-off sentiment:
- Traders prefer PT (guaranteed principal)
- PT price ⬆️, YT price ⬇️
```

---

## 🧮 Swap Pricing (How Much You Get)

### Constant Product Formula: x * y = k

When you swap, the formula ensures `k` stays constant (minus fees).

### Example: Swap 10 PT for YT

**Before swap:**
```
PT reserve: 100
YT reserve: 100
k = 10,000
```

**Calculate output:**
```
1. Add PT to pool: 100 + 10 = 110 PT
2. Solve for new YT: k / new_PT = 10,000 / 110 = 90.91 YT
3. YT output: 100 - 90.91 = 9.09 YT
4. Apply 0.3% fee: 9.09 × 0.997 = 9.06 YT
```

**After swap:**
```
PT reserve: 110
YT reserve: 90.91
k ≈ 10,000 (slightly higher due to fees)

New PT price: 90.91/110 = 0.826 YT per PT
```

---

## 📈 Implied APY Calculation

The AMM can calculate **implied APY** from PT/YT prices:

```move
// From pt_yt_amm.move (old version, but logic is same)
public fun calculate_implied_apy(pool_id: u64): u64 {
    let pt_price = get_pt_price(pool_id);
    let yt_price = get_yt_price(pool_id);
    let days_to_maturity = (maturity - now) / SECONDS_PER_DAY;
    
    // Implied APY = (YT_price / PT_price) * (365 / days_to_maturity) * 100
    (yt_price * 365 * 100) / (pt_price * days_to_maturity)
}
```

### Example Calculation

**Scenario:**
- PT price: 0.95 SY
- YT price: 0.05 SY
- Days to maturity: 180 (6 months)

**Implied APY:**
```
APY = (0.05 / 0.95) × (365 / 180) × 100
    = 0.0526 × 2.028 × 100
    = 10.67%
```

This means the market expects ~10.67% APY on the underlying stAPT.

---

## 🎯 Price Discovery in Action

### Scenario: stAPT has 9.5% APY, 6-month maturity

**Theoretical Fair Prices:**
```
Expected yield over 6 months: 9.5% × 0.5 = 4.75%

Fair PT price: 1 / (1 + 0.0475) = 0.9547 SY
Fair YT price: 0.0475 / (1 + 0.0475) = 0.0453 SY

PT + YT = 0.9547 + 0.0453 = 1.0 SY ✓
```

**Market Prices (determined by AMM):**
```
If pool has equal liquidity:
- PT reserve: 100
- YT reserve: 100
- PT price: 1.0 YT per PT
- YT price: 1.0 PT per YT

This is MISPRICED! Arbitrage opportunity!
```

**Arbitrage:**
```
1. Buy PT at 1.0 YT (should be 0.9547)
2. Hold to maturity
3. Redeem PT for 1.0 SY
4. Profit: 1.0 - 0.9547 = 0.0453 SY (4.53%)

Arbitrageurs will buy PT until price reaches fair value.
```

---

## 💰 Real-World Example

### Initial Pool Creation
```
Creator adds:
- 100 PT
- 100 YT

Initial prices:
- PT: 1.0 YT per PT
- YT: 1.0 PT per YT
```

### Day 1: Yield Farmers Buy YT
```
10 traders each buy 5 YT (50 YT total demand)

After trades:
- PT reserve: 150
- YT reserve: 67
- PT price: 67/150 = 0.45 YT per PT ⬇️
- YT price: 150/67 = 2.24 PT per YT ⬆️

YT is now expensive (high demand for yield)
```

### Day 30: Risk-Off, Traders Buy PT
```
20 traders each buy 3 PT (60 PT total demand)

After trades:
- PT reserve: 90
- YT reserve: 111
- PT price: 111/90 = 1.23 YT per PT ⬆️
- YT price: 90/111 = 0.81 PT per YT ⬇️

PT is now expensive (high demand for safety)
```

### Day 180: Approaching Maturity
```
Arbitrageurs balance the pool:
- PT reserve: 105
- YT reserve: 5
- PT price: 5/105 = 0.048 YT per PT ⬇️
- YT price: 105/5 = 21 PT per YT ⬆️

PT approaches 1:1 with SY
YT approaches 0 (no yield left)
```

---

## 🔍 Key Insights

### 1. No Oracle Needed
Prices are determined by **supply and demand**, not external oracles.

### 2. Always Balanced
PT + YT should always ≈ 1.0 SY (arbitrage ensures this).

### 3. Time Decay
PT price increases toward 1.0 as maturity approaches.

### 4. Yield Expectations
YT price reflects market's expected yield.

### 5. Liquidity Matters
More liquidity = less price impact = better prices.

---

## 📊 Price Monitoring

### Check Current Prices
```bash
# Get PT price
.\aptos move view \
  --function-id <ADDRESS>::pt_yt_amm_real::get_pt_price \
  --args address:<DEPLOYER> u64:0

# Get YT price
.\aptos move view \
  --function-id <ADDRESS>::pt_yt_amm_real::get_yt_price \
  --args address:<DEPLOYER> u64:0

# Get reserves
.\aptos move view \
  --function-id <ADDRESS>::pt_yt_amm_real::get_pool_reserves \
  --args address:<DEPLOYER> u64:0
```

---

## 🎯 Summary

**PT/YT prices are determined by:**

1. ✅ **AMM reserves** (x*y=k formula)
2. ✅ **Market demand** (traders buying/selling)
3. ✅ **Time to maturity** (PT → 1.0, YT → 0)
4. ✅ **Yield expectations** (higher APY = higher YT price)
5. ✅ **Arbitrage** (keeps PT + YT ≈ 1.0 SY)

**NOT determined by:**
- ❌ Oracles
- ❌ Admin settings
- ❌ Fixed formulas
- ❌ External price feeds

It's pure **market-driven price discovery**! 🎉
