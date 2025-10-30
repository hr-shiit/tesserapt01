# PT/YT Pricing Examples - Step by Step

## 🎓 Learn by Example

Let's walk through real scenarios to understand how PT/YT prices work.

---

## 📚 Example 1: Pool Creation

### Initial Setup
```
User creates pool with:
- 100 PT tokens
- 100 YT tokens
- Maturity: 6 months from now
- stAPT APY: 9.5%
```

### Initial Prices
```
PT reserve: 100
YT reserve: 100
k = 100 × 100 = 10,000

PT price = YT_reserve / PT_reserve = 100/100 = 1.0 YT per PT
YT price = PT_reserve / YT_reserve = 100/100 = 1.0 PT per YT

In SY terms (assuming PT + YT = 1 SY):
- PT = 0.5 SY
- YT = 0.5 SY
```

### Is This Fair?
```
❌ NO! This is mispriced.

Fair value for 6-month maturity at 9.5% APY:
- PT should be ~0.955 SY (95.5% of principal)
- YT should be ~0.045 SY (4.5% yield capture)

Arbitrage opportunity exists!
```

---

## 📚 Example 2: First Trade - Buying PT

### Scenario
Alice thinks yield will be lower than expected, so she wants to buy PT.

### Alice's Trade
```
Alice swaps 10 YT for PT

Before:
- PT reserve: 100
- YT reserve: 100
- k = 10,000
```

### Calculation
```
Step 1: Add Alice's YT to pool
YT reserve = 100 + 10 = 110

Step 2: Calculate new PT reserve (k must stay constant)
PT reserve = k / YT reserve = 10,000 / 110 = 90.909

Step 3: Calculate PT output
PT output = 100 - 90.909 = 9.091 PT

Step 4: Apply 0.3% trading fee
PT output after fee = 9.091 × 0.997 = 9.064 PT

Alice gets: 9.064 PT for 10 YT
Effective price: 10/9.064 = 1.103 YT per PT
```

### After Trade
```
PT reserve: 90.909
YT reserve: 110
k = 10,000

New PT price = 110/90.909 = 1.210 YT per PT ⬆️ (was 1.0)
New YT price = 90.909/110 = 0.826 PT per YT ⬇️ (was 1.0)

PT became more expensive (Alice bought it)
YT became cheaper (Alice sold it)
```

---

## 📚 Example 3: Opposite Trade - Buying YT

### Scenario
Bob thinks yield will be higher than expected, so he wants to buy YT.

### Bob's Trade
```
Bob swaps 10 PT for YT

Current state (after Alice's trade):
- PT reserve: 90.909
- YT reserve: 110
- k = 10,000
```

### Calculation
```
Step 1: Add Bob's PT to pool
PT reserve = 90.909 + 10 = 100.909

Step 2: Calculate new YT reserve
YT reserve = k / PT reserve = 10,000 / 100.909 = 99.099

Step 3: Calculate YT output
YT output = 110 - 99.099 = 10.901 YT

Step 4: Apply 0.3% fee
YT output after fee = 10.901 × 0.997 = 10.868 YT

Bob gets: 10.868 YT for 10 PT
Effective price: 10/10.868 = 0.920 PT per YT
```

### After Trade
```
PT reserve: 100.909
YT reserve: 99.099
k = 10,000

New PT price = 99.099/100.909 = 0.982 YT per PT ⬇️
New YT price = 100.909/99.099 = 1.018 PT per YT ⬆️

Prices are now closer to 1:1 again
```

---

## 📚 Example 4: Large Trade (Price Impact)

### Scenario
Charlie wants to buy a LOT of PT (50 tokens).

### Charlie's Trade
```
Charlie swaps 50 YT for PT

Current state:
- PT reserve: 100
- YT reserve: 100
- k = 10,000
```

### Calculation
```
Step 1: Add Charlie's YT
YT reserve = 100 + 50 = 150

Step 2: Calculate new PT reserve
PT reserve = 10,000 / 150 = 66.667

Step 3: Calculate PT output
PT output = 100 - 66.667 = 33.333 PT

Step 4: Apply fee
PT output after fee = 33.333 × 0.997 = 33.233 PT

Charlie gets: 33.233 PT for 50 YT
Effective price: 50/33.233 = 1.505 YT per PT

⚠️ HUGE PRICE IMPACT!
Expected 50 PT, got only 33.233 PT
Slippage: (50 - 33.233) / 50 = 33.5%
```

### After Trade
```
PT reserve: 66.667
YT reserve: 150
k = 10,000

New PT price = 150/66.667 = 2.250 YT per PT ⬆️⬆️⬆️
New YT price = 66.667/150 = 0.444 PT per YT ⬇️⬇️⬇️

PT is now VERY expensive (low liquidity)
```

### Lesson
```
Large trades have HUGE price impact in small pools!

Solution: Add more liquidity or split trade into smaller chunks.
```

---

## 📚 Example 5: Arbitrage Opportunity

### Scenario
Pool is mispriced. PT should be 0.95 SY but trading at 1.0 YT per PT.

### Setup
```
Pool state:
- PT reserve: 100
- YT reserve: 100
- PT price: 1.0 YT per PT

Fair value:
- PT should be: 0.95 SY
- YT should be: 0.05 SY

Arbitrage opportunity: PT is UNDERPRICED
```

### Arbitrageur's Strategy
```
Step 1: Buy PT from pool
- Swap YT for PT at 1.0 ratio
- Get PT at discount

Step 2: Hold PT to maturity
- PT redeems 1:1 for SY

Step 3: Profit
- Bought PT at 1.0 YT (≈0.5 SY if YT=0.5)
- Redeemed at 1.0 SY
- Profit: 1.0 - 0.5 = 0.5 SY (50%!)
```

### Market Correction
```
As arbitrageurs buy PT:
- PT price increases: 1.0 → 1.2 → 1.5 → 1.9 → 1.95
- YT price decreases: 1.0 → 0.83 → 0.67 → 0.53 → 0.51

Eventually reaches fair value:
- PT: ~1.9 YT per PT (≈0.95 SY)
- YT: ~0.53 PT per YT (≈0.05 SY)

Arbitrage opportunity eliminated!
```

---

## 📚 Example 6: Time Decay

### Scenario
Watch how prices change as maturity approaches.

### 6 Months Before Maturity
```
PT reserve: 100
YT reserve: 10
PT price: 10/100 = 0.10 YT per PT
YT price: 100/10 = 10 PT per YT

In SY terms:
- PT ≈ 0.91 SY (discounted)
- YT ≈ 0.09 SY (captures 6 months yield)
```

### 3 Months Before Maturity
```
PT reserve: 100
YT reserve: 5
PT price: 5/100 = 0.05 YT per PT
YT price: 100/5 = 20 PT per YT

In SY terms:
- PT ≈ 0.95 SY (less discount)
- YT ≈ 0.05 SY (captures 3 months yield)
```

### 1 Week Before Maturity
```
PT reserve: 100
YT reserve: 0.5
PT price: 0.5/100 = 0.005 YT per PT
YT price: 100/0.5 = 200 PT per YT

In SY terms:
- PT ≈ 0.998 SY (almost par)
- YT ≈ 0.002 SY (almost worthless)
```

### At Maturity
```
PT reserve: 100
YT reserve: 0.01
PT price: 0.01/100 = 0.0001 YT per PT
YT price: 100/0.01 = 10,000 PT per YT

In SY terms:
- PT = 1.0 SY (redeemable 1:1)
- YT = 0.0 SY (worthless)
```

---

## 📚 Example 7: Yield Rate Change

### Scenario
stAPT APY changes from 9.5% to 15%.

### Before (9.5% APY, 6 months to maturity)
```
Expected yield: 9.5% × 0.5 = 4.75%

Fair prices:
- PT: 0.955 SY
- YT: 0.045 SY

Pool state:
- PT reserve: 100
- YT reserve: 5
- PT price: 5/100 = 0.05 YT per PT
```

### After APY Increases to 15%
```
New expected yield: 15% × 0.5 = 7.5%

New fair prices:
- PT: 0.930 SY (more discount)
- YT: 0.070 SY (more valuable)

Traders rush to buy YT:
- YT demand increases
- YT price goes up
- PT price goes down

New pool state after trading:
- PT reserve: 120
- YT reserve: 3
- PT price: 3/120 = 0.025 YT per PT ⬇️
- YT price: 120/3 = 40 PT per YT ⬆️
```

---

## 🎯 Key Takeaways

### 1. Price = Reserves Ratio
```
PT price = YT_reserve / PT_reserve
YT price = PT_reserve / YT_reserve
```

### 2. Buying Increases Price
```
Buy PT → PT reserve decreases → PT price increases
Buy YT → YT reserve decreases → YT price increases
```

### 3. Large Trades = Large Impact
```
Small pool + Large trade = HUGE slippage
Large pool + Large trade = Small slippage
```

### 4. Arbitrage Keeps Prices Fair
```
If PT underpriced → Arbitrageurs buy PT → Price increases
If YT underpriced → Arbitrageurs buy YT → Price increases
```

### 5. Time Decay is Real
```
As maturity approaches:
- PT → 1.0 SY
- YT → 0.0 SY
```

### 6. Yield Expectations Matter
```
Higher expected yield → Higher YT price
Lower expected yield → Higher PT price
```

---

## 💡 Pro Tips

### For Traders
1. Check price impact before large trades
2. Split large orders into smaller chunks
3. Monitor implied APY vs actual APY
4. Buy PT when yield expectations are low
5. Buy YT when yield expectations are high

### For Liquidity Providers
1. Add liquidity at fair prices
2. More liquidity = more trading fees
3. Rebalance as prices change
4. Remove liquidity before maturity

### For Arbitrageurs
1. Monitor PT + YT ≈ 1.0 SY
2. Buy underpriced token
3. Sell overpriced token
4. Profit from price correction

---

## 🚀 Try It Yourself!

Use these commands to experiment:

```bash
# Check current prices
.\aptos move view --function-id <ADDR>::pt_yt_amm_real::get_pt_price --args address:<DEPLOYER> u64:0
.\aptos move view --function-id <ADDR>::pt_yt_amm_real::get_yt_price --args address:<DEPLOYER> u64:0

# Make a trade
.\aptos move run --function-id <ADDR>::pt_yt_amm_real::swap_pt_for_yt --args address:<DEPLOYER> u64:0 u64:100000000 u64:0

# Check new prices
.\aptos move view --function-id <ADDR>::pt_yt_amm_real::get_pt_price --args address:<DEPLOYER> u64:0
```

Watch the prices change in real-time! 📈
