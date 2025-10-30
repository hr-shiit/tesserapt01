# 🎨 Frontend Integration Guide

## Overview

This guide shows how to integrate the smart contracts with the frontend UI described in `FRONTEND_UI_BRIEF.md`.

**Contract Address:** `0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16`

---

## 📋 Contract Function Mapping

### Tab 1: Earn (Staking)

#### Stake APT → Get stAPT

**UI Function:** `StakeForm.tsx`
**Contract Function:** `oracles_and_mocks::mint_stapt`

```typescript
// Frontend call
await signAndSubmitTransaction({
  sender: account.address,
  data: {
    function: `${CONTRACT_ADDR}::oracles_and_mocks::mint_stapt`,
    functionArguments: [
      CONTRACT_ADDR, // stapt_addr
      amount * 100000000 // amount in 8 decimals
    ]
  }
});
```

**View Balance:**
```typescript
const balance = await aptos.view({
  function: `${CONTRACT_ADDR}::oracles_and_mocks::get_stapt_balance`,
  arguments: [CONTRACT_ADDR, userAddress]
});
// Returns: balance in 8 decimals
```

**Get Exchange Rate:**
```typescript
const rate = await aptos.view({
  function: `${CONTRACT_ADDR}::oracles_and_mocks::get_stapt_exchange_rate`,
  arguments: [CONTRACT_ADDR]
});
// Returns: rate in 8 decimals (e.g., 100000000 = 1.0)
```

---

### Tab 2: Split (Tokenization)

#### Step 1: Wrap stAPT → SY

**UI Function:** `SplitForm.tsx` (internal step)
**Contract Function:** `tokenization::deposit_stapt_for_sy`

```typescript
await signAndSubmitTransaction({
  sender: account.address,
  data: {
    function: `${CONTRACT_ADDR}::tokenization::deposit_stapt_for_sy`,
    functionArguments: [
      CONTRACT_ADDR, // sy_wrapper_addr
      amount * 100000000
    ]
  }
});
```

#### Step 2: Split SY → PT + YT

**UI Function:** `SplitForm.tsx`
**Contract Function:** `tokenization::split`

```typescript
// Calculate maturity timestamp
const getMaturityTimestamp = (months) => {
  const now = Math.floor(Date.now() / 1000);
  return now + (months * 30 * 24 * 60 * 60);
};

await signAndSubmitTransaction({
  sender: account.address,
  data: {
    function: `${CONTRACT_ADDR}::tokenization::split`,
    type_arguments: [`${CONTRACT_ADDR}::tokenization::SYToken`],
    functionArguments: [
      CONTRACT_ADDR, // tokenization_addr
      amount * 100000000,
      0 // maturity_idx (0 for first maturity)
    ]
  }
});
```


**View PT Balance:**
```typescript
const ptBalance = await aptos.view({
  function: `${CONTRACT_ADDR}::tokenization::get_user_pt_balance`,
  type_arguments: [`${CONTRACT_ADDR}::tokenization::SYToken`],
  arguments: [userAddress, 0] // maturity_idx
});
```

**View YT Balance:**
```typescript
const ytBalance = await aptos.view({
  function: `${CONTRACT_ADDR}::tokenization::get_user_yt_balance`,
  type_arguments: [`${CONTRACT_ADDR}::tokenization::SYToken`],
  arguments: [userAddress, 0]
});
```

---

### Tab 3: Trade (AMM)

#### Swap PT for YT

**UI Function:** `SwapForm.tsx`
**Contract Function:** `pt_yt_amm::swap_pt_for_yt`

```typescript
await signAndSubmitTransaction({
  sender: account.address,
  data: {
    function: `${CONTRACT_ADDR}::pt_yt_amm::swap_pt_for_yt`,
    functionArguments: [
      CONTRACT_ADDR, // factory_addr
      0, // pool_id
      ptAmount * 100000000,
      minYtOut * 100000000 // slippage protection
    ]
  }
});
```

#### Swap YT for PT

**UI Function:** `SwapForm.tsx`
**Contract Function:** `pt_yt_amm::swap_yt_for_pt`

```typescript
await signAndSubmitTransaction({
  sender: account.address,
  data: {
    function: `${CONTRACT_ADDR}::pt_yt_amm::swap_yt_for_pt`,
    functionArguments: [
      CONTRACT_ADDR,
      0, // pool_id
      ytAmount * 100000000,
      minPtOut * 100000000
    ]
  }
});
```

**Get Pool Reserves (for price calculation):**
```typescript
const reserves = await aptos.view({
  function: `${CONTRACT_ADDR}::pt_yt_amm::get_pool_reserves`,
  arguments: [CONTRACT_ADDR, 0]
});
// Returns: [ptReserve, ytReserve]
```

**Calculate Output Amount:**
```typescript
// For PT → YT swap
const ptReserve = Number(reserves[0]);
const ytReserve = Number(reserves[1]);
const k = ptReserve * ytReserve;

const amountIn = ptAmount * 100000000;
const newPtReserve = ptReserve + amountIn;
const newYtReserve = k / newPtReserve;
const ytOut = (ytReserve - newYtReserve) * 0.997; // 0.3% fee

return ytOut / 100000000;
```

---

## 🔧 Complete Hook Examples

### useBalances Hook

```typescript
import { useWallet } from "@aptos-labs/wallet-adapter-react";
import { useState, useEffect } from "react";
import { aptos, CONTRACT_ADDR } from "../utils/aptos";

export function useBalances() {
  const { account } = useWallet();
  const [balances, setBalances] = useState({
    apt: 0,
    stapt: 0,
    sy: 0,
    pt: 0,
    yt: 0,
  });
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (!account) return;

    const fetchBalances = async () => {
      setLoading(true);
      try {
        // APT balance
        const aptRes = await aptos.getAccountAPTAmount({
          accountAddress: account.address,
        });

        // stAPT balance
        const staptRes = await aptos.view({
          function: `${CONTRACT_ADDR}::oracles_and_mocks::get_stapt_balance`,
          arguments: [CONTRACT_ADDR, account.address],
        });

        // SY balance
        const syRes = await aptos.view({
          function: `${CONTRACT_ADDR}::tokenization::get_sy_balance`,
          arguments: [CONTRACT_ADDR, account.address],
        });

        // PT balance
        const ptRes = await aptos.view({
          function: `${CONTRACT_ADDR}::tokenization::get_user_pt_balance`,
          type_arguments: [`${CONTRACT_ADDR}::tokenization::SYToken`],
          arguments: [account.address, 0],
        });

        // YT balance
        const ytRes = await aptos.view({
          function: `${CONTRACT_ADDR}::tokenization::get_user_yt_balance`,
          type_arguments: [`${CONTRACT_ADDR}::tokenization::SYToken`],
          arguments: [account.address, 0],
        });

        setBalances({
          apt: Number(aptRes) / 100000000,
          stapt: Number(staptRes[0]) / 100000000,
          sy: Number(syRes[0]) / 100000000,
          pt: Number(ptRes[0]) / 100000000,
          yt: Number(ytRes[0]) / 100000000,
        });
      } catch (error) {
        console.error("Error fetching balances:", error);
      } finally {
        setLoading(false);
      }
    };

    fetchBalances();
    const interval = setInterval(fetchBalances, 10000);
    return () => clearInterval(interval);
  }, [account]);

  return { balances, loading };
}
```

---

### useStaking Hook

```typescript
import { useWallet } from "@aptos-labs/wallet-adapter-react";
import { useState } from "react";
import { aptos, CONTRACT_ADDR } from "../utils/aptos";
import toast from "react-hot-toast";

export function useStaking() {
  const { signAndSubmitTransaction, account } = useWallet();
  const [loading, setLoading] = useState(false);

  const stakeAPT = async (amount: number) => {
    if (!account) {
      toast.error("Please connect wallet");
      return;
    }

    setLoading(true);
    try {
      const response = await signAndSubmitTransaction({
        sender: account.address,
        data: {
          function: `${CONTRACT_ADDR}::oracles_and_mocks::mint_stapt`,
          functionArguments: [CONTRACT_ADDR, Math.floor(amount * 100000000)],
        },
      });

      await aptos.waitForTransaction({ transactionHash: response.hash });
      toast.success("Successfully staked!");
      return response;
    } catch (error) {
      console.error(error);
      toast.error("Staking failed");
      throw error;
    } finally {
      setLoading(false);
    }
  };

  const unstakeAPT = async (amount: number) => {
    if (!account) {
      toast.error("Please connect wallet");
      return;
    }

    setLoading(true);
    try {
      const response = await signAndSubmitTransaction({
        sender: account.address,
        data: {
          function: `${CONTRACT_ADDR}::oracles_and_mocks::burn_stapt`,
          functionArguments: [CONTRACT_ADDR, Math.floor(amount * 100000000)],
        },
      });

      await aptos.waitForTransaction({ transactionHash: response.hash });
      toast.success("Successfully unstaked!");
      return response;
    } catch (error) {
      console.error(error);
      toast.error("Unstaking failed");
      throw error;
    } finally {
      setLoading(false);
    }
  };

  return { stakeAPT, unstakeAPT, loading };
}
```

---

### useSplit Hook

```typescript
import { useWallet } from "@aptos-labs/wallet-adapter-react";
import { useState } from "react";
import { aptos, CONTRACT_ADDR } from "../utils/aptos";
import toast from "react-hot-toast";

export function useSplit() {
  const { signAndSubmitTransaction, account } = useWallet();
  const [loading, setLoading] = useState(false);

  const splitYield = async (amount: number, maturityMonths: number) => {
    if (!account) {
      toast.error("Please connect wallet");
      return;
    }

    setLoading(true);
    try {
      // Step 1: Wrap stAPT to SY
      const wrapResponse = await signAndSubmitTransaction({
        sender: account.address,
        data: {
          function: `${CONTRACT_ADDR}::tokenization::deposit_stapt_for_sy`,
          functionArguments: [CONTRACT_ADDR, Math.floor(amount * 100000000)],
        },
      });
      await aptos.waitForTransaction({ transactionHash: wrapResponse.hash });

      // Step 2: Split SY to PT + YT
      const splitResponse = await signAndSubmitTransaction({
        sender: account.address,
        data: {
          function: `${CONTRACT_ADDR}::tokenization::split`,
          type_arguments: [`${CONTRACT_ADDR}::tokenization::SYToken`],
          functionArguments: [
            CONTRACT_ADDR,
            Math.floor(amount * 100000000),
            0, // maturity_idx
          ],
        },
      });
      await aptos.waitForTransaction({ transactionHash: splitResponse.hash });

      toast.success("Successfully split into PT + YT!");
      return splitResponse;
    } catch (error) {
      console.error(error);
      toast.error("Split failed");
      throw error;
    } finally {
      setLoading(false);
    }
  };

  return { splitYield, loading };
}
```

---

### useTrade Hook

```typescript
import { useWallet } from "@aptos-labs/wallet-adapter-react";
import { useState, useEffect } from "react";
import { aptos, CONTRACT_ADDR } from "../utils/aptos";
import toast from "react-hot-toast";

export function useTrade() {
  const { signAndSubmitTransaction, account } = useWallet();
  const [loading, setLoading] = useState(false);
  const [reserves, setReserves] = useState({ pt: 0, yt: 0 });

  useEffect(() => {
    const fetchReserves = async () => {
      try {
        const res = await aptos.view({
          function: `${CONTRACT_ADDR}::pt_yt_amm::get_pool_reserves`,
          arguments: [CONTRACT_ADDR, 0],
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

  const calculateOutput = (
    amountIn: number,
    fromToken: "PT" | "YT"
  ): number => {
    const k = reserves.pt * reserves.yt;
    const amountInScaled = amountIn * 100000000;

    if (fromToken === "PT") {
      const newPtReserve = reserves.pt + amountInScaled;
      const newYtReserve = k / newPtReserve;
      const ytOut = (reserves.yt - newYtReserve) * 0.997;
      return ytOut / 100000000;
    } else {
      const newYtReserve = reserves.yt + amountInScaled;
      const newPtReserve = k / newYtReserve;
      const ptOut = (reserves.pt - newPtReserve) * 0.997;
      return ptOut / 100000000;
    }
  };

  const swapPTForYT = async (ptAmount: number, minYtOut: number = 0) => {
    if (!account) {
      toast.error("Please connect wallet");
      return;
    }

    setLoading(true);
    try {
      const response = await signAndSubmitTransaction({
        sender: account.address,
        data: {
          function: `${CONTRACT_ADDR}::pt_yt_amm::swap_pt_for_yt`,
          functionArguments: [
            CONTRACT_ADDR,
            0,
            Math.floor(ptAmount * 100000000),
            Math.floor(minYtOut * 100000000),
          ],
        },
      });

      await aptos.waitForTransaction({ transactionHash: response.hash });
      toast.success("Swap successful!");
      return response;
    } catch (error) {
      console.error(error);
      toast.error("Swap failed");
      throw error;
    } finally {
      setLoading(false);
    }
  };

  const swapYTForPT = async (ytAmount: number, minPtOut: number = 0) => {
    if (!account) {
      toast.error("Please connect wallet");
      return;
    }

    setLoading(true);
    try {
      const response = await signAndSubmitTransaction({
        sender: account.address,
        data: {
          function: `${CONTRACT_ADDR}::pt_yt_amm::swap_yt_for_pt`,
          functionArguments: [
            CONTRACT_ADDR,
            0,
            Math.floor(ytAmount * 100000000),
            Math.floor(minPtOut * 100000000),
          ],
        },
      });

      await aptos.waitForTransaction({ transactionHash: response.hash });
      toast.success("Swap successful!");
      return response;
    } catch (error) {
      console.error(error);
      toast.error("Swap failed");
      throw error;
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
}
```

---

## 📊 UI Component Integration

### StakeForm.tsx

```typescript
import { useState } from "react";
import { useStaking } from "../hooks/useStaking";
import { useBalances } from "../hooks/useBalances";

export function StakeForm() {
  const [amount, setAmount] = useState("");
  const { stakeAPT, loading } = useStaking();
  const { balances } = useBalances();

  const handleStake = async () => {
    if (!amount || Number(amount) <= 0) return;
    await stakeAPT(Number(amount));
    setAmount("");
  };

  return (
    <div className="bg-white rounded-2xl p-6 shadow-lg">
      <h2 className="text-2xl font-bold mb-4">💰 Earn 9.5% APY on Your APT</h2>

      <div className="mb-4">
        <label className="block text-sm text-gray-600 mb-2">You Stake</label>
        <input
          type="number"
          value={amount}
          onChange={(e) => setAmount(e.target.value)}
          placeholder="0.00"
          className="w-full text-2xl p-4 border-2 rounded-xl"
        />
        <div className="flex justify-between mt-2">
          <span className="text-sm text-gray-500">
            Balance: {balances.apt.toFixed(2)} APT
          </span>
          <button
            onClick={() => setAmount(balances.apt.toString())}
            className="text-sm text-primary font-semibold"
          >
            MAX
          </button>
        </div>
      </div>

      <div className="text-center my-4">↓</div>

      <div className="bg-gray-50 rounded-xl p-4 mb-4">
        <label className="block text-sm text-gray-600 mb-2">You Receive</label>
        <div className="text-2xl font-semibold">
          ~{amount ? Number(amount).toFixed(2) : "0.00"} stAPT
        </div>
      </div>

      <button
        onClick={handleStake}
        disabled={loading || !amount}
        className="w-full bg-primary text-white py-4 rounded-xl font-semibold"
      >
        {loading ? "Staking..." : "Stake APT"}
      </button>
    </div>
  );
}
```

---

## ✅ Integration Checklist

### Setup
- [ ] Install Aptos SDK
- [ ] Configure wallet adapter
- [ ] Set contract addresses
- [ ] Test wallet connection

### Earn Tab
- [ ] Implement stake function
- [ ] Show stAPT balance
- [ ] Display APY
- [ ] Add unstake function

### Split Tab
- [ ] Implement wrap function
- [ ] Implement split function
- [ ] Show PT/YT balances
- [ ] Add maturity selector

### Trade Tab
- [ ] Implement PT→YT swap
- [ ] Implement YT→PT swap
- [ ] Calculate output amounts
- [ ] Show pool reserves
- [ ] Add slippage protection

### Polish
- [ ] Add loading states
- [ ] Add error handling
- [ ] Add success messages
- [ ] Test on mobile
- [ ] Add tooltips

---

## 🔗 Related Documentation

- **[Master Integration Guide](./INTEGRATION_MASTER_GUIDE.md)** - Complete technical reference
- **[Oracles & Mocks](./INTEGRATION_ORACLES_AND_MOCKS.md)** - Staking functions
- **[Yield Tokenization](./INTEGRATION_YIELD_TOKENIZATION.md)** - Split functions
- **[PT/YT AMM](./INTEGRATION_PT_YT_AMM.md)** - Trading functions
- **[Frontend UI Brief](../FRONTEND_UI_BRIEF.md)** - Complete UI specifications

---

**This guide provides the exact contract calls needed for the UI described in FRONTEND_UI_BRIEF.md** ✅
