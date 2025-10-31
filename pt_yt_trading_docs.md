# PT/YT Trading - Complete Integration Guide

**One document with everything your frontend developer needs to integrate PT/YT token trading.**

---

## 📋 Table of Contents

1. [Quick Start (3 Steps)](#quick-start)
2. [Contract Information](#contract-information)
3. [Core Functions](#core-functions)
4. [Complete Code Examples](#complete-code-examples)
5. [React Hook Implementation](#react-hook-implementation)
6. [UI Component Example](#ui-component-example)
7. [Testing & Troubleshooting](#testing--troubleshooting)
8. [Quick Reference](#quick-reference)

---

## 🚀 Quick Start

### What You're Building

A swap interface where users can trade PT (Principal Token) and YT (Yield Token) with real-time pricing.

### 3-Step Integration

**Step 1: Get Pool Reserves** (for pricing)
**Step 2: Calculate Output** (client-side)
**Step 3: Execute Swap** (transaction)

That's it! Let's dive in.

---

## 📦 Contract Information

```
Network: Aptos Testnet
Contract Address: 0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16
Pool ID: 0 (always use 0)
Decimals: 8 (all amounts)
Trading Fee: 0.3%
AMM Type: Constant Product (x * y = k)
```

### Key Concepts

- **8 Decimals**: All blockchain amounts use 8 decimals

  - User input: `10 PT` → Blockchain: `1000000000`
  - Blockchain output: `1000000000` → User display: `10 PT`

- **0.3% Fee**: Automatically deducted from output

  - Formula: `output * 0.997`

- **Slippage Protection**: Set minimum output to prevent price changes
  - Recommended: 0.5% - 1% tolerance
  - Formula: `minOut = expectedOutput * 0.99` (1% slippage)

---

## 🔧 Core Functions

### 1. Get Pool Reserves (View Function)

**Purpose:** Fetch PT and YT reserves to calculate swap prices

**Function:** `pt_yt_amm::get_pool_reserves`

```typescript
const CONTRACT_ADDR =
  "0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16";

async function getPoolReserves() {
  const reserves = await aptos.view({
    payload: {
      function: `${CONTRACT_ADDR}::pt_yt_amm::get_pool_reserves`,
      functionArguments: [CONTRACT_ADDR, 0], // 0 is pool ID
    },
  });

  return {
    ptReserve: Number(reserves[0]), // PT in pool (8 decimals)
    ytReserve: Number(reserves[1]), // YT in pool (8 decimals)
  };
}
```

**Returns:**

- `reserves[0]` = PT reserve (e.g., 5000000000 = 50 PT)
- `reserves[1]` = YT reserve (e.g., 5000000000 = 50 YT)

**Important:** Call this every 5 seconds to keep prices updated!

---

### 2. Calculate Swap Output (Client-Side)

**Purpose:** Calculate how much output user will receive

**Formula:** Constant Product AMM (x \* y = k)

```typescript
function calculateSwapOutput(
  amountIn: number, // User input (e.g., 10)
  fromToken: "PT" | "YT",
  ptReserve: number, // From getPoolReserves()
  ytReserve: number // From getPoolReserves()
): number {
  if (ptReserve === 0 || ytReserve === 0) return 0;

  // Convert to 8 decimals
  const amountInScaled = Math.floor(amountIn * 100000000);

  // Constant product formula
  const k = ptReserve * ytReserve;

  if (fromToken === "PT") {
    // Swapping PT for YT
    const newPtReserve = ptReserve + amountInScaled;
    const newYtReserve = k / newPtReserve;
    const ytOut = (ytReserve - newYtReserve) * 0.997; // 0.3% fee
    return ytOut / 100000000; // Convert back
  } else {
    // Swapping YT for PT
    const newYtReserve = ytReserve + amountInScaled;
    const newPtReserve = k / newYtReserve;
    const ptOut = (ptReserve - newPtReserve) * 0.997; // 0.3% fee
    return ptOut / 100000000; // Convert back
  }
}
```

**Example:**

```typescript
const reserves = await getPoolReserves();
const ytOutput = calculateSwapOutput(
  10,
  "PT",
  reserves.ptReserve,
  reserves.ytReserve
);
console.log(`Swapping 10 PT will give you: ${ytOutput.toFixed(4)} YT`);
```

---

### 3. Swap PT for YT (Transaction)

**Function:** `pt_yt_amm::swap_pt_for_yt`

```typescript
import { useWallet } from "@aptos-labs/wallet-adapter-react";

async function swapPTForYT(ptAmount: number, minYtOut: number = 0) {
  const { signAndSubmitTransaction, account } = useWallet();

  const response = await signAndSubmitTransaction({
    sender: account.address,
    data: {
      function: `${CONTRACT_ADDR}::pt_yt_amm::swap_pt_for_yt`,
      functionArguments: [
        CONTRACT_ADDR, // factory_addr
        0, // pool_id
        Math.floor(ptAmount * 100000000), // pt_amount (8 decimals)
        Math.floor(minYtOut * 100000000), // min_yt_out (slippage)
      ],
    },
  });

  await aptos.waitForTransaction({ transactionHash: response.hash });
  return response;
}
```

**Parameters:**

- `CONTRACT_ADDR` - Factory address (same as contract)
- `0` - Pool ID (always 0)
- `ptAmount` - Amount of PT to swap (converted to 8 decimals)
- `minYtOut` - Minimum YT to receive (slippage protection)

---

### 4. Swap YT for PT (Transaction)

**Function:** `pt_yt_amm::swap_yt_for_pt`

```typescript
async function swapYTForPT(ytAmount: number, minPtOut: number = 0) {
  const { signAndSubmitTransaction, account } = useWallet();

  const response = await signAndSubmitTransaction({
    sender: account.address,
    data: {
      function: `${CONTRACT_ADDR}::pt_yt_amm::swap_yt_for_pt`,
      functionArguments: [
        CONTRACT_ADDR, // factory_addr
        0, // pool_id
        Math.floor(ytAmount * 100000000), // yt_amount (8 decimals)
        Math.floor(minPtOut * 100000000), // min_pt_out (slippage)
      ],
    },
  });

  await aptos.waitForTransaction({ transactionHash: response.hash });
  return response;
}
```

---

## 💻 Complete Code Examples

### Setup Aptos SDK

```typescript
import { Aptos, AptosConfig, Network } from "@aptos-labs/ts-sdk";

const config = new AptosConfig({ network: Network.TESTNET });
export const aptos = new Aptos(config);

export const CONTRACT_ADDR =
  "0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16";
export const DECIMALS = 8;

// Helper: Convert to blockchain format
export const toBlockchainAmount = (amount: number): number => {
  return Math.floor(amount * Math.pow(10, DECIMALS));
};

// Helper: Convert from blockchain format
export const fromBlockchainAmount = (amount: number): number => {
  return amount / Math.pow(10, DECIMALS);
};
```

---

## ⚛️ React Hook Implementation

### Complete useTrade Hook

```typescript
import { useState, useEffect } from "react";
import { useWallet } from "@aptos-labs/wallet-adapter-react";
import {
  aptos,
  CONTRACT_ADDR,
  toBlockchainAmount,
  fromBlockchainAmount,
} from "../utils/aptos";

export const useTrade = () => {
  const { signAndSubmitTransaction, account } = useWallet();
  const [loading, setLoading] = useState(false);
  const [reserves, setReserves] = useState({ pt: 0, yt: 0 });

  // Fetch reserves every 5 seconds
  useEffect(() => {
    const fetchReserves = async () => {
      try {
        const res = await aptos.view({
          payload: {
            function: `${CONTRACT_ADDR}::pt_yt_amm::get_pool_reserves`,
            functionArguments: [CONTRACT_ADDR, 0],
          },
        });
        setReserves({
          pt: Number(res[0]),
          yt: Number(res[1]),
        });
      } catch (error) {
        console.error("Error fetching reserves:", error);
      }
    };

    fetchReserves();
    const interval = setInterval(fetchReserves, 5000);
    return () => clearInterval(interval);
  }, []);

  // Calculate output
  const calculateOutput = (
    amountIn: number,
    fromToken: "PT" | "YT"
  ): number => {
    if (reserves.pt === 0 || reserves.yt === 0) return 0;

    const k = reserves.pt * reserves.yt;
    const amountInScaled = toBlockchainAmount(amountIn);

    if (fromToken === "PT") {
      const newPtReserve = reserves.pt + amountInScaled;
      const newYtReserve = k / newPtReserve;
      const ytOut = (reserves.yt - newYtReserve) * 0.997;
      return fromBlockchainAmount(ytOut);
    } else {
      const newYtReserve = reserves.yt + amountInScaled;
      const newPtReserve = k / newYtReserve;
      const ptOut = (reserves.pt - newPtReserve) * 0.997;
      return fromBlockchainAmount(ptOut);
    }
  };

  // Swap PT for YT
  const swapPTForYT = async (ptAmount: number, minYtOut: number = 0) => {
    if (!account) throw new Error("Wallet not connected");

    setLoading(true);
    try {
      const response = await signAndSubmitTransaction({
        sender: account.address,
        data: {
          function: `${CONTRACT_ADDR}::pt_yt_amm::swap_pt_for_yt`,
          functionArguments: [
            CONTRACT_ADDR,
            0,
            toBlockchainAmount(ptAmount),
            toBlockchainAmount(minYtOut),
          ],
        },
      });

      await aptos.waitForTransaction({ transactionHash: response.hash });
      return response;
    } finally {
      setLoading(false);
    }
  };

  // Swap YT for PT
  const swapYTForPT = async (ytAmount: number, minPtOut: number = 0) => {
    if (!account) throw new Error("Wallet not connected");

    setLoading(true);
    try {
      const response = await signAndSubmitTransaction({
        sender: account.address,
        data: {
          function: `${CONTRACT_ADDR}::pt_yt_amm::swap_yt_for_pt`,
          functionArguments: [
            CONTRACT_ADDR,
            0,
            toBlockchainAmount(ytAmount),
            toBlockchainAmount(minPtOut),
          ],
        },
      });

      await aptos.waitForTransaction({ transactionHash: response.hash });
      return response;
    } finally {
      setLoading(false);
    }
  };

  return {
    swapPTForYT,
    swapYTForPT,
    calculateOutput,
    reserves,
    loading,
  };
};
```

---

## 🎨 UI Component Example

### Complete Swap Component

```typescript
import React, { useState, useEffect } from "react";
import { useTrade } from "../hooks/useTrade";

export const SwapForm = ({
  ptBalance,
  ytBalance,
}: {
  ptBalance: number;
  ytBalance: number;
}) => {
  const [fromToken, setFromToken] = useState<"PT" | "YT">("PT");
  const [amount, setAmount] = useState("");
  const [estimatedOutput, setEstimatedOutput] = useState("0");
  const { swapPTForYT, swapYTForPT, calculateOutput, loading } = useTrade();

  const toToken = fromToken === "PT" ? "YT" : "PT";
  const balance = fromToken === "PT" ? ptBalance : ytBalance;

  // Update estimated output when amount changes
  useEffect(() => {
    if (!amount || parseFloat(amount) <= 0) {
      setEstimatedOutput("0");
      return;
    }
    const output = calculateOutput(parseFloat(amount), fromToken);
    setEstimatedOutput(output.toFixed(4));
  }, [amount, fromToken, calculateOutput]);

  const handleSwap = async () => {
    const numAmount = parseFloat(amount);
    if (!numAmount || numAmount <= 0) return;
    if (numAmount > balance) {
      alert("Insufficient balance");
      return;
    }

    try {
      const minOut = parseFloat(estimatedOutput) * 0.99; // 1% slippage

      if (fromToken === "PT") {
        await swapPTForYT(numAmount, minOut);
      } else {
        await swapYTForPT(numAmount, minOut);
      }

      alert("Swap successful!");
      setAmount("");
    } catch (error: any) {
      console.error("Swap failed:", error);
      alert("Swap failed: " + error.message);
    }
  };

  const flip = () => {
    setFromToken(fromToken === "PT" ? "YT" : "PT");
    setAmount("");
  };

  const exchangeRate =
    amount && parseFloat(amount) > 0 && parseFloat(estimatedOutput) > 0
      ? (parseFloat(estimatedOutput) / parseFloat(amount)).toFixed(4)
      : "0";

  return (
    <div className="bg-dark-card rounded-2xl p-6">
      <h2 className="text-2xl font-bold mb-6">💱 Trade Yield Tokens</h2>

      {/* Input Section */}
      <div className="mb-4">
        <label className="block text-sm text-gray-400 mb-2">You Sell</label>
        <div className="flex gap-2">
          <input
            type="number"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            placeholder="0.00"
            className="flex-1 text-2xl p-4 bg-dark-bg border-2 border-gray-700 rounded-xl"
          />
          <select
            value={fromToken}
            onChange={(e) => setFromToken(e.target.value as "PT" | "YT")}
            className="px-4 bg-dark-bg border-2 border-gray-700 rounded-xl"
          >
            <option value="PT">PT</option>
            <option value="YT">YT</option>
          </select>
        </div>
        <div className="flex justify-between mt-2 text-sm text-gray-400">
          <span>
            Balance: {balance.toFixed(4)} {fromToken}
          </span>
          <button
            onClick={() => setAmount(balance.toString())}
            className="text-blue-500 font-semibold"
          >
            MAX
          </button>
        </div>
      </div>

      {/* Flip Button */}
      <div className="text-center my-4">
        <button
          onClick={flip}
          className="bg-dark-bg border border-gray-700 p-3 rounded-lg hover:border-blue-500"
        >
          ↓↑ Flip
        </button>
      </div>

      {/* Output Section */}
      <div className="bg-dark-bg rounded-xl p-4 mb-4 border border-gray-700">
        <label className="block text-sm text-gray-400 mb-2">You Receive</label>
        <div className="text-2xl font-semibold">
          ~{estimatedOutput} {toToken}
        </div>
      </div>

      {/* Price Info */}
      <div className="bg-dark-bg rounded-xl p-4 mb-6 border border-gray-700">
        <div className="flex justify-between text-sm mb-2">
          <span className="text-gray-400">Price:</span>
          <span>
            1 {fromToken} = {exchangeRate} {toToken}
          </span>
        </div>
        <div className="flex justify-between text-sm">
          <span className="text-gray-400">Fee:</span>
          <span>0.3%</span>
        </div>
      </div>

      {/* Swap Button */}
      <button
        onClick={handleSwap}
        disabled={loading || !amount || parseFloat(amount) <= 0}
        className="w-full bg-blue-600 text-white py-4 rounded-xl font-semibold hover:bg-blue-700 disabled:bg-gray-600"
      >
        {loading ? "Swapping..." : "Swap Now"}
      </button>
    </div>
  );
};
```

---

## 🧪 Testing & Troubleshooting

### Testing Checklist

Before going live, verify:

- [ ] **Reserves fetch correctly** - Check console for reserve values
- [ ] **Output calculation updates** - Change amount and see output update
- [ ] **PT → YT swap works** - Execute a small test swap
- [ ] **YT → PT swap works** - Execute reverse swap
- [ ] **Slippage protection** - Try with 0% slippage (should fail if price moves)
- [ ] **Error handling** - Test with insufficient balance
- [ ] **Loading states** - Button shows "Swapping..." during transaction
- [ ] **Success messages** - User sees confirmation after swap

### Common Errors & Solutions

**Error: "Insufficient balance"**

- **Cause:** User doesn't have enough PT or YT
- **Solution:** Check balance before allowing swap
- **Code:** Add validation: `if (amount > balance) return;`

**Error: "Slippage exceeded"**

- **Cause:** Price moved too much during transaction
- **Solution:** Increase slippage tolerance or retry
- **Code:** Change `minOut = output * 0.99` to `output * 0.98` (2% slippage)

**Error: "Pool not found"**

- **Cause:** Wrong pool ID or contract address
- **Solution:** Verify pool ID is 0 and contract address is correct
- **Check:** `CONTRACT_ADDR` and `POOL_ID = 0`

**Error: "Transaction rejected"**

- **Cause:** User rejected in wallet
- **Solution:** Show friendly message, allow retry
- **Code:** Catch error and show: "Transaction cancelled by user"

**Reserves show as 0**

- **Cause:** Pool not initialized or wrong network
- **Solution:** Verify on testnet, check contract address
- **Debug:** Log reserves to console: `console.log(reserves)`

### Testing Flow

1. **Get test tokens:**

   - Use Aptos faucet for APT
   - Stake APT to get stAPT
   - Split stAPT to get PT and YT

2. **Test small swap:**

   ```typescript
   // Swap 1 PT for YT
   await swapPTForYT(1, 0.04); // Expect ~0.045 YT
   ```

3. **Verify on explorer:**

   - Check transaction: https://explorer.aptoslabs.com/?network=testnet
   - Verify balances updated correctly

4. **Test edge cases:**
   - Swap with 0 amount (should fail)
   - Swap more than balance (should fail)
   - Swap with very high slippage (should succeed)

---

## 📚 Quick Reference

### Function Signatures

| Function            | Purpose            | Parameters                                           | Returns                    |
| ------------------- | ------------------ | ---------------------------------------------------- | -------------------------- |
| `get_pool_reserves` | Get PT/YT reserves | `factory_addr`, `pool_id`                            | `[pt_reserve, yt_reserve]` |
| `swap_pt_for_yt`    | Swap PT → YT       | `factory_addr`, `pool_id`, `pt_amount`, `min_yt_out` | Transaction hash           |
| `swap_yt_for_pt`    | Swap YT → PT       | `factory_addr`, `pool_id`, `yt_amount`, `min_pt_out` | Transaction hash           |

### Key Values

```typescript
CONTRACT_ADDR = "0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16"
POOL_ID = 0
DECIMALS = 8
FEE = 0.3% (multiply output by 0.997)
```

### Decimal Conversion

```typescript
// User → Blockchain
const blockchainAmount = Math.floor(userAmount * 100000000);

// Blockchain → User
const userAmount = blockchainAmount / 100000000;
```

### Slippage Calculation

```typescript
// 1% slippage
const minOut = expectedOutput * 0.99;

// 0.5% slippage
const minOut = expectedOutput * 0.995;

// 2% slippage
const minOut = expectedOutput * 0.98;
```

### Price Calculation

```typescript
// Exchange rate
const rate = outputAmount / inputAmount;

// Example: 1 PT = 0.0475 YT
const rate = 0.475 / 10; // = 0.0475
```

---

## 🎯 Implementation Summary

### What You Need to Do

1. **Copy the `useTrade` hook** to your project
2. **Create a swap component** using the UI example
3. **Add to your app** in the Trade tab
4. **Test thoroughly** with small amounts first

### Files to Create

```
src/
├── hooks/
│   └── useTrade.ts          (Copy from React Hook section)
├── components/
│   └── trade/
│       └── SwapForm.tsx     (Copy from UI Component section)
└── utils/
    └── aptos.ts             (Copy from Setup section)
```

### Integration Time

- **Setup:** 10 minutes
- **Hook implementation:** 15 minutes
- **UI component:** 20 minutes
- **Testing:** 15 minutes
- **Total:** ~1 hour

---

## ✅ Final Checklist

Before deploying:

- [ ] Contract address is correct
- [ ] Pool ID is set to 0
- [ ] Decimal conversion is working (8 decimals)
- [ ] Reserves update every 5 seconds
- [ ] Output calculation is accurate
- [ ] Slippage protection is implemented
- [ ] Error handling is in place
- [ ] Loading states work
- [ ] Success/error messages show
- [ ] Tested on testnet
- [ ] UI is responsive
- [ ] Wallet connection works

---

## 🆘 Need Help?

### Resources

- **Aptos Explorer:** https://explorer.aptoslabs.com/?network=testnet
- **Aptos Docs:** https://aptos.dev/
- **Wallet Adapter:** https://github.com/aptos-labs/aptos-wallet-adapter

### Debug Steps

1. Check browser console for errors
2. Verify wallet is connected
3. Check transaction on explorer
4. Verify contract address
5. Test with small amounts first

### Contact

If you encounter issues:

- Check the contract is deployed correctly
- Verify you're on testnet
- Ensure user has test tokens
- Review error messages carefully

---

## 🚀 You're Ready!

You now have everything needed to integrate PT/YT trading:

✅ Complete function implementations  
✅ Working React hooks  
✅ UI component examples  
✅ Error handling  
✅ Testing guide  
✅ Quick reference

**Contract:** `0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16`

**Start building and happy coding!** 🎉

---

_Last Updated: 2025_  
_Network: Aptos Testnet_  
_Version: 1.0_
