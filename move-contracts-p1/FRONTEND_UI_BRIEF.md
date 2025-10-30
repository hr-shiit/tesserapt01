# Frontend UI Design Brief - Yield Tokenization Protocol

## 🎯 Project Goal

Create a **minimal, flow-based UI** for a yield tokenization protocol where users can stake APT, split yield into tradeable tokens, and trade them. The UI must be **dead simple** - users should never feel lost or overwhelmed.

---

## 📖 What You're Building (The Product)

### The Protocol in Simple Terms

This is a DeFi app on Aptos blockchain that lets users:

1. **Stake APT** and earn 9.5% APY (like a savings account)
2. **Split their yield** into two separate tokens they can trade
3. **Trade those tokens** to speculate on future yields or lock in returns

### The Three Token Types

1. **stAPT** - Staked APT that earns 9.5% APY automatically
2. **PT (Principal Token)** - Represents your original deposit, redeemable at maturity
3. **YT (Yield Token)** - Represents all future yield until maturity

### The User Journey

```
Step 1: User has APT
   ↓
Step 2: Stake APT → Get stAPT (earning 9.5% APY)
   ↓
Step 3: Split stAPT → Get PT + YT (both tradeable)
   ↓
Step 4: Trade PT/YT on the market
   ↓
Step 5: At maturity, redeem PT back to stAPT
```

### Why Would Someone Use This?

- **Yield Farmers**: Lock in current yields by selling YT
- **Risk-Averse Users**: Buy PT for guaranteed principal return
- **Speculators**: Trade PT/YT based on yield expectations
- **Liquidity Providers**: Earn 0.3% fees on all trades

---

## 🛠️ Technical Stack & Setup

### Recommended Tech Stack

```
Frontend Framework: React + TypeScript (or Next.js)
Styling: Tailwind CSS
State Management: Zustand or React Context
Wallet Integration: Aptos Wallet Adapter
API Calls: Aptos SDK (@aptos-labs/ts-sdk)
Charts (optional): Recharts or Chart.js
```

### Project Structure

```
src/
├── components/
│   ├── wallet/
│   │   ├── WalletConnect.tsx
│   │   └── WalletButton.tsx
│   ├── stake/
│   │   ├── StakeForm.tsx
│   │   ├── StakedPosition.tsx
│   │   └── UnstakeForm.tsx
│   ├── split/
│   │   ├── SplitForm.tsx
│   │   ├── TokenBalances.tsx
│   │   └── MaturitySelector.tsx
│   ├── trade/
│   │   ├── SwapForm.tsx
│   │   ├── LiquidityForm.tsx
│   │   └── PoolInfo.tsx
│   └── shared/
│       ├── Button.tsx
│       ├── Input.tsx
│       ├── Card.tsx
│       └── TokenIcon.tsx
├── hooks/
│   ├── useWallet.ts
│   ├── useStaking.ts
│   ├── useSplit.ts
│   ├── useTrade.ts
│   └── useBalances.ts
├── utils/
│   ├── aptos.ts (SDK setup)
│   ├── contracts.ts (contract addresses & ABIs)
│   └── formatting.ts (number formatting)
├── pages/
│   ├── Earn.tsx
│   ├── Split.tsx
│   └── Trade.tsx
└── App.tsx
```

### Smart Contract Integration

**Contract Address (Replace with actual):**

```typescript
const CONTRACT_ADDRESS = "0xYOUR_CONTRACT_ADDRESS_HERE";
```

**Key Functions to Call:**

1. **Staking (Earn Tab)**

```typescript
// Stake APT
await aptos.transaction.build.simple({
  sender: userAddress,
  data: {
    function: `${CONTRACT_ADDRESS}::stapt_staking::stake_apt`,
    functionArguments: [deployerAddress, amount],
  },
});

// Get stAPT balance
const balance = await aptos.view({
  function: `${CONTRACT_ADDRESS}::coin_types::get_stapt_balance`,
  functionArguments: [userAddress],
});

// Get exchange rate
const rate = await aptos.view({
  function: `${CONTRACT_ADDRESS}::stapt_staking::get_exchange_rate`,
  functionArguments: [deployerAddress],
});
```

2. **Splitting (Split Tab)**

```typescript
// Deposit stAPT for SY
await aptos.transaction.build.simple({
  sender: userAddress,
  data: {
    function: `${CONTRACT_ADDRESS}::sy_wrapper::deposit_stapt`,
    functionArguments: [deployerAddress, amount],
  },
});

// Split SY into PT + YT
await aptos.transaction.build.simple({
  sender: userAddress,
  data: {
    function: `${CONTRACT_ADDRESS}::pt_yt_tokenization::split_sy`,
    functionArguments: [deployerAddress, amount, maturityTimestamp],
  },
});

// Get PT balance
const ptBalance = await aptos.view({
  function: `${CONTRACT_ADDRESS}::coin_types::get_pt_balance`,
  functionArguments: [userAddress],
});

// Get YT balance
const ytBalance = await aptos.view({
  function: `${CONTRACT_ADDRESS}::coin_types::get_yt_balance`,
  functionArguments: [userAddress],
});
```

3. **Trading (Trade Tab)**

```typescript
// Swap PT for YT
await aptos.transaction.build.simple({
  sender: userAddress,
  data: {
    function: `${CONTRACT_ADDRESS}::pt_yt_amm_real::swap_pt_for_yt`,
    functionArguments: [deployerAddress, poolId, ptAmount, minYtOut],
  },
});

// Swap YT for PT
await aptos.transaction.build.simple({
  sender: userAddress,
  data: {
    function: `${CONTRACT_ADDRESS}::pt_yt_amm_real::swap_yt_for_pt`,
    functionArguments: [deployerAddress, poolId, ytAmount, minPtOut],
  },
});

// Get pool reserves
const reserves = await aptos.view({
  function: `${CONTRACT_ADDRESS}::pt_yt_amm_real::get_pool_reserves`,
  functionArguments: [deployerAddress, poolId],
});

// Get PT price
const ptPrice = await aptos.view({
  function: `${CONTRACT_ADDRESS}::pt_yt_amm_real::get_pt_price`,
  functionArguments: [deployerAddress, poolId],
});
```

### Installation & Setup

```bash
# Create new React app
npx create-react-app yield-protocol --template typescript
cd yield-protocol

# Install dependencies
npm install @aptos-labs/ts-sdk
npm install @aptos-labs/wallet-adapter-react
npm install tailwindcss
npm install zustand
npm install react-hot-toast  # for notifications

# Initialize Tailwind
npx tailwindcss init
```

### Environment Variables

```env
REACT_APP_NETWORK=testnet  # or mainnet
REACT_APP_CONTRACT_ADDRESS=0xYOUR_ADDRESS
REACT_APP_DEPLOYER_ADDRESS=0xDEPLOYER_ADDRESS
```

---

## 🧠 Core Philosophy

### Design Principles

1. **One action per screen** - Never show multiple complex actions at once
2. **Progressive disclosure** - Only show what's needed for the current step
3. **Clear outcomes** - Always show "You give X, you get Y"
4. **No jargon overload** - Explain complex terms simply
5. **Visual flow** - Use arrows, progress indicators, and clear CTAs
6. **Confidence building** - Show exactly what will happen before it happens

### User Mental Model

```
"I have APT" → "I want to earn yield" → "I want to trade that yield"
```

Keep it this simple.

---

## 📱 UI Structure - 3 Main Tabs

### Tab 1: Earn (Staking)

**Goal:** Get users earning yield ASAP

### Tab 2: Split (Tokenization)

**Goal:** Let users separate their yield into tradeable tokens

### Tab 3: Trade (AMM)

**Goal:** Let users trade PT and YT tokens

---

## 🎨 Detailed Screen Flows

---

## TAB 1: EARN 💰

### Screen 1.1: Stake APT (Landing Page)

**Layout:**

```
┌─────────────────────────────────────┐
│  💰 Earn 9.5% APY on Your APT       │
│                                      │
│  ┌────────────────────────────────┐ │
│  │  You Stake                      │ │
│  │  [____] APT                     │ │
│  │  Balance: 100 APT               │ │
│  └────────────────────────────────┘ │
│                                      │
│           ↓                          │
│                                      │
│  ┌────────────────────────────────┐ │
│  │  You Receive                    │ │
│  │  ~10.00 stAPT                   │ │
│  │  (Auto-compounds daily)         │ │
│  └────────────────────────────────┘ │
│                                      │
│  [    Stake APT    ] ← Big button   │
│                                      │
│  ℹ️ Your stAPT grows automatically  │
│     No action needed!               │
└─────────────────────────────────────┘
```

**Key Elements:**

- Large input field for APT amount
- Real-time calculation of stAPT received
- Clear "You give → You get" visual
- One big CTA button
- Simple explanation below

**What to Hide:**

- Exchange rates
- Technical details
- APY calculations
- Contract addresses

---

### Screen 1.2: Your Staked Position

**Layout:**

```
┌─────────────────────────────────────┐
│  Your Staked APT                    │
│                                      │
│  ┌────────────────────────────────┐ │
│  │  100.00 stAPT                   │ │
│  │  ≈ 101.23 APT                   │ │
│  │                                  │ │
│  │  📈 +1.23 APT earned             │ │
│  │     (9.5% APY)                   │ │
│  └────────────────────────────────┘ │
│                                      │
│  [  Stake More  ]  [ Unstake ]      │
│                                      │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│                                      │
│  💡 Want to trade your future yield? │
│     Try the Split tab →              │
└─────────────────────────────────────┘
```

**Key Elements:**

- Show stAPT balance prominently
- Show APT equivalent (what it's worth)
- Show earnings in green
- Gentle nudge to explore splitting

---

## TAB 2: SPLIT 🔀

### Screen 2.1: Split Your Yield (Main View)

**Layout:**

```
┌─────────────────────────────────────┐
│  🔀 Split Your Yield                │
│                                      │
│  Turn your stAPT into two tokens:   │
│                                      │
│  ┌─────────────────┐ ┌─────────────┐│
│  │  PT             │ │  YT          ││
│  │  Principal      │ │  Yield       ││
│  │                 │ │              ││
│  │  Get your money │ │  Get all the ││
│  │  back later     │ │  yield       ││
│  └─────────────────┘ └─────────────┘│
│                                      │
│  ┌────────────────────────────────┐ │
│  │  Split Amount                   │ │
│  │  [____] stAPT                   │ │
│  │  Balance: 100 stAPT             │ │
│  └────────────────────────────────┘ │
│                                      │
│  Choose maturity:                   │
│  ( ) 3 months  ( ) 6 months  (•) 1 year │
│                                      │
│           ↓                          │
│                                      │
│  ┌────────────────────────────────┐ │
│  │  You Get                        │ │
│  │  50 PT  +  50 YT                │ │
│  └────────────────────────────────┘ │
│                                      │
│  [    Split Now    ]                │
│                                      │
│  ℹ️ You can trade these separately  │
└─────────────────────────────────────┘
```

**Key Elements:**

- Simple explanation of PT vs YT
- Visual cards showing what each token does
- Maturity selector (radio buttons)
- Clear "You get both tokens" message
- No complex pricing shown here

**What to Hide:**

- Exchange rates
- Implied APY
- Market prices
- Technical formulas

---

### Screen 2.2: Your Split Tokens

**Layout:**

```
┌─────────────────────────────────────┐
│  Your Tokens                        │
│                                      │
│  ┌────────────────────────────────┐ │
│  │  PT (Principal Token)           │ │
│  │  50.00 PT                       │ │
│  │  Matures: Dec 31, 2025          │ │
│  │                                  │ │
│  │  [  Trade  ]  [  Redeem  ]      │ │
│  └────────────────────────────────┘ │
│                                      │
│  ┌────────────────────────────────┐ │
│  │  YT (Yield Token)               │ │
│  │  50.00 YT                       │ │
│  │  Earning: ~4.75 stAPT/year      │ │
│  │                                  │ │
│  │  [  Trade  ]                    │ │
│  └────────────────────────────────┘ │
│                                      │
│  💡 Trade these on the Trade tab →  │
└─────────────────────────────────────┘
```

**Key Elements:**

- Separate cards for PT and YT
- Show maturity date clearly
- Show what YT is earning
- Direct CTAs to trade

---

## TAB 3: TRADE 💱

### Screen 3.1: Trade PT/YT (Main View)

**Layout:**

```
┌─────────────────────────────────────┐
│  💱 Trade Yield Tokens              │
│                                      │
│  ┌────────────────────────────────┐ │
│  │  You Sell                       │ │
│  │  [____] PT ▼                    │ │
│  │  Balance: 50 PT                 │ │
│  └────────────────────────────────┘ │
│                                      │
│           ↓↑  [Flip]                │
│                                      │
│  ┌────────────────────────────────┐ │
│  │  You Receive                    │ │
│  │  ~2.35 YT                       │ │
│  └────────────────────────────────┘ │
│                                      │
│  Price: 1 PT = 0.047 YT             │
│  Fee: 0.3%                          │
│                                      │
│  [    Swap Now    ]                 │
│                                      │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│                                      │
│  💡 Why trade?                      │
│  • Sell PT if you need money now   │
│  • Sell YT if you think yield will │
│    be lower than expected           │
└─────────────────────────────────────┘
```

**Key Elements:**

- Classic swap interface (like Uniswap)
- Dropdown to select PT or YT
- Real-time price calculation
- Flip button to reverse direction
- Simple explanation of why you'd trade

**What to Hide:**

- Slippage settings (use sensible default)
- Advanced settings
- Pool reserves
- Implied APY (unless user clicks "Advanced")

---

### Screen 3.2: Add Liquidity (Optional - Advanced Users)

**Layout:**

```
┌─────────────────────────────────────┐
│  💧 Provide Liquidity               │
│                                      │
│  Earn 0.3% fees on all trades       │
│                                      │
│  ┌────────────────────────────────┐ │
│  │  Add PT                         │ │
│  │  [____] PT                      │ │
│  │  Balance: 50 PT                 │ │
│  └────────────────────────────────┘ │
│                                      │
│  ┌────────────────────────────────┐ │
│  │  Add YT                         │ │
│  │  [____] YT (auto-calculated)    │ │
│  │  Balance: 50 YT                 │ │
│  └────────────────────────────────┘ │
│                                      │
│  Your share: ~5% of pool            │
│                                      │
│  [  Add Liquidity  ]                │
│                                      │
│  ⚠️ Advanced: Only add liquidity if │
│     you understand impermanent loss │
└─────────────────────────────────────┘
```

**Key Elements:**

- Two input fields (PT and YT)
- Auto-calculate second amount
- Show pool share percentage
- Warning about complexity

---

## 🎨 Visual Design Guidelines

### Color Palette

```
Primary Action: #3B82F6 (Blue) - Stake, Split, Trade buttons
Success: #10B981 (Green) - Earnings, positive changes
Warning: #F59E0B (Amber) - Important info
Danger: #EF4444 (Red) - Errors, losses
Neutral: #6B7280 (Gray) - Secondary text
Background: #F9FAFB (Light gray) or #111827 (Dark mode)
```

### Typography

```
Headings: 24px, Bold, Inter or SF Pro
Body: 16px, Regular
Numbers: 20px, Semibold, Monospace font
Small text: 14px, Regular
```

### Components

**Input Fields:**

```
- Large, rounded corners (12px)
- Show balance below input
- Max button on the right
- Real-time validation
```

**Buttons:**

```
- Large (48px height)
- Full width on mobile
- Clear loading states
- Disabled state when invalid
```

**Cards:**

```
- Subtle shadow
- Rounded corners (16px)
- Padding: 24px
- Hover effect (slight lift)
```

---

## 🔄 User Flow Examples

### Flow 1: First-Time User (Stake APT)

```
1. Land on "Earn" tab
2. See big "Stake APT" interface
3. Enter amount (e.g., 10 APT)
4. See "You'll receive ~10 stAPT"
5. Click "Stake APT"
6. Wallet confirmation
7. Success! Show staked position
8. Gentle nudge: "Want to trade your yield? Try Split →"
```

**Time to first action: < 30 seconds**

---

### Flow 2: Split Yield

```
1. Click "Split" tab
2. See simple explanation: PT = principal, YT = yield
3. Enter amount of stAPT to split
4. Choose maturity (default: 6 months)
5. See "You get 50 PT + 50 YT"
6. Click "Split Now"
7. Wallet confirmation
8. Success! Show both token balances
9. Nudge: "Trade these on Trade tab →"
```

**Time to understand: < 1 minute**

---

### Flow 3: Trade PT for YT

```
1. Click "Trade" tab
2. See swap interface (familiar from other DEXs)
3. Select "PT" in top dropdown
4. Enter amount (e.g., 10 PT)
5. See calculated output: "~0.47 YT"
6. Click "Swap Now"
7. Wallet confirmation
8. Success! Show new balances
```

**Time to trade: < 20 seconds**

---

## 📊 Information Hierarchy

### Always Show (Priority 1)

- Current balance
- Amount to input
- What you'll receive
- Main action button
- Current APY/yield

### Show on Hover/Click (Priority 2)

- Exchange rates
- Fees
- Maturity dates
- Pool information

### Hide in "Advanced" (Priority 3)

- Slippage tolerance
- Transaction deadline
- Contract addresses
- Implied APY calculations
- Pool reserves

---

## 🚨 Error Handling

### Insufficient Balance

```
┌─────────────────────────────────────┐
│  ⚠️ Insufficient Balance            │
│                                      │
│  You're trying to stake 100 APT     │
│  but you only have 50 APT           │
│                                      │
│  [  Enter Valid Amount  ]           │
└─────────────────────────────────────┘
```

### Transaction Failed

```
┌─────────────────────────────────────┐
│  ❌ Transaction Failed               │
│                                      │
│  Your transaction didn't go through │
│  This usually happens when:         │
│  • You rejected it in your wallet   │
│  • Gas price was too low            │
│                                      │
│  [  Try Again  ]  [  Get Help  ]    │
└─────────────────────────────────────┘
```

### Wallet Not Connected

```
┌─────────────────────────────────────┐
│  🔌 Connect Your Wallet             │
│                                      │
│  To use this app, you need to       │
│  connect an Aptos wallet            │
│                                      │
│  [  Connect Petra  ]                │
│  [  Connect Martian  ]              │
└─────────────────────────────────────┘
```

---

## 📱 Mobile Considerations

### Mobile Layout

- Stack everything vertically
- Larger touch targets (min 44px)
- Bottom sheet for confirmations
- Sticky CTA button at bottom
- Swipe between tabs

### Mobile-First Features

- Pull to refresh balances
- Haptic feedback on actions
- Native wallet integration
- Share transaction links

---

## 🎯 Success Metrics

### User Should Be Able To:

1. ✅ Stake APT in < 30 seconds (first time)
2. ✅ Understand PT vs YT in < 1 minute
3. ✅ Complete a trade in < 20 seconds
4. ✅ Never see a screen and think "What do I do?"
5. ✅ Always know their current position

### Avoid:

- ❌ Information overload
- ❌ Multiple actions on one screen
- ❌ Unexplained jargon
- ❌ Hidden important info
- ❌ Confusing navigation

---

## 🛠️ Step-by-Step Implementation Guide

### STEP 1: Project Setup (Day 1)

**1.1 Create Project**

```bash
npx create-react-app yield-protocol --template typescript
cd yield-protocol
npm install @aptos-labs/ts-sdk @aptos-labs/wallet-adapter-react
npm install tailwindcss postcss autoprefixer
npm install zustand react-hot-toast
npx tailwindcss init -p
```

**1.2 Configure Tailwind (tailwind.config.js)**

```javascript
module.exports = {
  content: ["./src/**/*.{js,jsx,ts,tsx}"],
  theme: {
    extend: {
      colors: {
        primary: "#3B82F6",
        success: "#10B981",
        warning: "#F59E0B",
        danger: "#EF4444",
      },
    },
  },
};
```

**1.3 Create Basic File Structure**

```
src/
├── components/
├── hooks/
├── utils/
├── pages/
└── App.tsx
```

---

### STEP 2: Wallet Connection (Day 1-2)

**2.1 Create Wallet Provider (src/App.tsx)**

```typescript
import { AptosWalletAdapterProvider } from "@aptos-labs/wallet-adapter-react";
import { PetraWallet } from "petra-plugin-wallet-adapter";
import { MartianWallet } from "@martianwallet/aptos-wallet-adapter";

function App() {
  const wallets = [new PetraWallet(), new MartianWallet()];

  return (
    <AptosWalletAdapterProvider plugins={wallets} autoConnect={true}>
      <YourApp />
    </AptosWalletAdapterProvider>
  );
}
```

**2.2 Create Wallet Button (src/components/wallet/WalletButton.tsx)**

```typescript
import { useWallet } from "@aptos-labs/wallet-adapter-react";

export function WalletButton() {
  const { connect, disconnect, account, connected } = useWallet();

  if (connected && account) {
    return (
      <button onClick={disconnect}>
        {account.address.slice(0, 6)}...{account.address.slice(-4)}
      </button>
    );
  }

  return <button onClick={() => connect("Petra")}>Connect Wallet</button>;
}
```

**2.3 Test Wallet Connection**

- User should see "Connect Wallet" button
- Clicking opens Petra wallet
- After connecting, shows shortened address
- Clicking address disconnects

---

### STEP 3: Aptos SDK Setup (Day 2)

**3.1 Create Aptos Client (src/utils/aptos.ts)**

```typescript
import { Aptos, AptosConfig, Network } from "@aptos-labs/ts-sdk";

const config = new AptosConfig({ network: Network.TESTNET });
export const aptos = new Aptos(config);

export const CONTRACT_ADDRESS = process.env.REACT_APP_CONTRACT_ADDRESS || "";
export const DEPLOYER_ADDRESS = process.env.REACT_APP_DEPLOYER_ADDRESS || "";
```

**3.2 Create Balance Hook (src/hooks/useBalances.ts)**

```typescript
import { useWallet } from "@aptos-labs/wallet-adapter-react";
import { useState, useEffect } from "react";
import { aptos, CONTRACT_ADDRESS } from "../utils/aptos";

export function useBalances() {
  const { account } = useWallet();
  const [balances, setBalances] = useState({
    apt: 0,
    stapt: 0,
    pt: 0,
    yt: 0,
  });

  useEffect(() => {
    if (!account) return;

    const fetchBalances = async () => {
      // Get APT balance
      const aptBalance = await aptos.getAccountAPTAmount({
        accountAddress: account.address,
      });

      // Get stAPT balance
      const staptBalance = await aptos.view({
        payload: {
          function: `${CONTRACT_ADDRESS}::coin_types::get_stapt_balance`,
          functionArguments: [account.address],
        },
      });

      // Get PT balance
      const ptBalance = await aptos.view({
        payload: {
          function: `${CONTRACT_ADDRESS}::coin_types::get_pt_balance`,
          functionArguments: [account.address],
        },
      });

      // Get YT balance
      const ytBalance = await aptos.view({
        payload: {
          function: `${CONTRACT_ADDRESS}::coin_types::get_yt_balance`,
          functionArguments: [account.address],
        },
      });

      setBalances({
        apt: Number(aptBalance) / 100000000, // Convert from octas
        stapt: Number(staptBalance[0]) / 100000000,
        pt: Number(ptBalance[0]) / 100000000,
        yt: Number(ytBalance[0]) / 100000000,
      });
    };

    fetchBalances();
    const interval = setInterval(fetchBalances, 10000); // Update every 10s

    return () => clearInterval(interval);
  }, [account]);

  return balances;
}
```

---

### STEP 4: Build Earn Tab (Day 3-4)

**4.1 Create Stake Form (src/components/stake/StakeForm.tsx)**

```typescript
import { useState } from "react";
import { useWallet } from "@aptos-labs/wallet-adapter-react";
import { aptos, CONTRACT_ADDRESS, DEPLOYER_ADDRESS } from "../../utils/aptos";
import toast from "react-hot-toast";

export function StakeForm({ aptBalance }: { aptBalance: number }) {
  const [amount, setAmount] = useState("");
  const [loading, setLoading] = useState(false);
  const { signAndSubmitTransaction } = useWallet();

  const handleStake = async () => {
    if (!amount || Number(amount) <= 0) {
      toast.error("Enter a valid amount");
      return;
    }

    if (Number(amount) > aptBalance) {
      toast.error("Insufficient balance");
      return;
    }

    setLoading(true);

    try {
      const response = await signAndSubmitTransaction({
        sender: account.address,
        data: {
          function: `${CONTRACT_ADDRESS}::stapt_staking::stake_apt`,
          functionArguments: [DEPLOYER_ADDRESS, Number(amount) * 100000000], // Convert to octas
        },
      });

      await aptos.waitForTransaction({ transactionHash: response.hash });

      toast.success("Successfully staked!");
      setAmount("");
    } catch (error) {
      console.error(error);
      toast.error("Transaction failed");
    } finally {
      setLoading(false);
    }
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
          className="w-full text-2xl p-4 border-2 rounded-xl focus:border-primary"
        />
        <div className="flex justify-between mt-2">
          <span className="text-sm text-gray-500">
            Balance: {aptBalance.toFixed(2)} APT
          </span>
          <button
            onClick={() => setAmount(aptBalance.toString())}
            className="text-sm text-primary font-semibold"
          >
            MAX
          </button>
        </div>
      </div>

      <div className="text-center my-4">
        <span className="text-2xl">↓</span>
      </div>

      <div className="bg-gray-50 rounded-xl p-4 mb-4">
        <label className="block text-sm text-gray-600 mb-2">You Receive</label>
        <div className="text-2xl font-semibold">
          ~{amount ? Number(amount).toFixed(2) : "0.00"} stAPT
        </div>
        <div className="text-sm text-gray-500 mt-1">Auto-compounds daily</div>
      </div>

      <button
        onClick={handleStake}
        disabled={loading || !amount}
        className="w-full bg-primary text-white py-4 rounded-xl font-semibold text-lg hover:bg-blue-600 disabled:bg-gray-300 disabled:cursor-not-allowed"
      >
        {loading ? "Staking..." : "Stake APT"}
      </button>

      <div className="mt-4 text-sm text-gray-500 text-center">
        ℹ️ Your stAPT grows automatically. No action needed!
      </div>
    </div>
  );
}
```

**4.2 Create Earn Page (src/pages/Earn.tsx)**

```typescript
import { StakeForm } from "../components/stake/StakeForm";
import { useBalances } from "../hooks/useBalances";

export function Earn() {
  const balances = useBalances();

  return (
    <div className="max-w-2xl mx-auto p-4">
      <StakeForm aptBalance={balances.apt} />

      {balances.stapt > 0 && (
        <div className="mt-6 bg-white rounded-2xl p-6 shadow-lg">
          <h3 className="text-xl font-bold mb-4">Your Staked Position</h3>
          <div className="text-3xl font-bold">
            {balances.stapt.toFixed(2)} stAPT
          </div>
          <div className="text-gray-500 mt-2">
            ≈ {(balances.stapt * 1.01).toFixed(2)} APT
          </div>
          <div className="text-success mt-2">
            📈 +{(balances.stapt * 0.01).toFixed(2)} APT earned
          </div>
        </div>
      )}
    </div>
  );
}
```

---

### STEP 5: Build Split Tab (Day 5-6)

**5.1 Create Split Form (src/components/split/SplitForm.tsx)**

```typescript
import { useState } from "react";
import { useWallet } from "@aptos-labs/wallet-adapter-react";
import { aptos, CONTRACT_ADDRESS, DEPLOYER_ADDRESS } from "../../utils/aptos";
import toast from "react-hot-toast";

export function SplitForm({ staptBalance }: { staptBalance: number }) {
  const [amount, setAmount] = useState("");
  const [maturity, setMaturity] = useState("6"); // months
  const [loading, setLoading] = useState(false);
  const { signAndSubmitTransaction, account } = useWallet();

  const getMaturityTimestamp = (months: string) => {
    const now = Math.floor(Date.now() / 1000);
    const monthsInSeconds = Number(months) * 30 * 24 * 60 * 60;
    return now + monthsInSeconds;
  };

  const handleSplit = async () => {
    if (!amount || Number(amount) <= 0) {
      toast.error("Enter a valid amount");
      return;
    }

    setLoading(true);

    try {
      // Step 1: Wrap stAPT to SY
      const wrapResponse = await signAndSubmitTransaction({
        sender: account.address,
        data: {
          function: `${CONTRACT_ADDRESS}::sy_wrapper::deposit_stapt`,
          functionArguments: [DEPLOYER_ADDRESS, Number(amount) * 100000000],
        },
      });
      await aptos.waitForTransaction({ transactionHash: wrapResponse.hash });

      // Step 2: Split SY to PT + YT
      const splitResponse = await signAndSubmitTransaction({
        sender: account.address,
        data: {
          function: `${CONTRACT_ADDRESS}::pt_yt_tokenization::split_sy`,
          functionArguments: [
            DEPLOYER_ADDRESS,
            Number(amount) * 100000000,
            getMaturityTimestamp(maturity),
          ],
        },
      });
      await aptos.waitForTransaction({ transactionHash: splitResponse.hash });

      toast.success("Successfully split into PT + YT!");
      setAmount("");
    } catch (error) {
      console.error(error);
      toast.error("Transaction failed");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="bg-white rounded-2xl p-6 shadow-lg">
      <h2 className="text-2xl font-bold mb-4">🔀 Split Your Yield</h2>

      <div className="grid grid-cols-2 gap-4 mb-6">
        <div className="bg-blue-50 rounded-xl p-4">
          <div className="font-semibold mb-2">PT - Principal</div>
          <div className="text-sm text-gray-600">
            Get your money back at maturity
          </div>
        </div>
        <div className="bg-green-50 rounded-xl p-4">
          <div className="font-semibold mb-2">YT - Yield</div>
          <div className="text-sm text-gray-600">Get all the yield earned</div>
        </div>
      </div>

      <div className="mb-4">
        <label className="block text-sm text-gray-600 mb-2">Split Amount</label>
        <input
          type="number"
          value={amount}
          onChange={(e) => setAmount(e.target.value)}
          placeholder="0.00"
          className="w-full text-2xl p-4 border-2 rounded-xl focus:border-primary"
        />
        <div className="flex justify-between mt-2">
          <span className="text-sm text-gray-500">
            Balance: {staptBalance.toFixed(2)} stAPT
          </span>
          <button
            onClick={() => setAmount(staptBalance.toString())}
            className="text-sm text-primary font-semibold"
          >
            MAX
          </button>
        </div>
      </div>

      <div className="mb-4">
        <label className="block text-sm text-gray-600 mb-2">
          Choose Maturity
        </label>
        <div className="flex gap-2">
          {["3", "6", "12"].map((m) => (
            <button
              key={m}
              onClick={() => setMaturity(m)}
              className={`flex-1 py-3 rounded-xl font-semibold ${
                maturity === m
                  ? "bg-primary text-white"
                  : "bg-gray-100 text-gray-700"
              }`}
            >
              {m} months
            </button>
          ))}
        </div>
      </div>

      <div className="text-center my-4">
        <span className="text-2xl">↓</span>
      </div>

      <div className="bg-gray-50 rounded-xl p-4 mb-4">
        <label className="block text-sm text-gray-600 mb-2">You Get</label>
        <div className="text-2xl font-semibold">
          {amount ? Number(amount).toFixed(2) : "0.00"} PT +{" "}
          {amount ? Number(amount).toFixed(2) : "0.00"} YT
        </div>
      </div>

      <button
        onClick={handleSplit}
        disabled={loading || !amount}
        className="w-full bg-primary text-white py-4 rounded-xl font-semibold text-lg hover:bg-blue-600 disabled:bg-gray-300"
      >
        {loading ? "Splitting..." : "Split Now"}
      </button>

      <div className="mt-4 text-sm text-gray-500 text-center">
        ℹ️ You can trade these separately on the Trade tab
      </div>
    </div>
  );
}
```

---

### STEP 6: Build Trade Tab (Day 7-8)

**6.1 Create Swap Form (src/components/trade/SwapForm.tsx)**

```typescript
import { useState, useEffect } from "react";
import { useWallet } from "@aptos-labs/wallet-adapter-react";
import { aptos, CONTRACT_ADDRESS, DEPLOYER_ADDRESS } from "../../utils/aptos";
import toast from "react-hot-toast";

export function SwapForm({
  ptBalance,
  ytBalance,
}: {
  ptBalance: number;
  ytBalance: number;
}) {
  const [fromToken, setFromToken] = useState<"PT" | "YT">("PT");
  const [amount, setAmount] = useState("");
  const [estimatedOutput, setEstimatedOutput] = useState("0");
  const [loading, setLoading] = useState(false);
  const { signAndSubmitTransaction, account } = useWallet();

  // Calculate estimated output based on pool reserves
  useEffect(() => {
    if (!amount || Number(amount) <= 0) {
      setEstimatedOutput("0");
      return;
    }

    const fetchPrice = async () => {
      try {
        const reserves = await aptos.view({
          payload: {
            function: `${CONTRACT_ADDRESS}::pt_yt_amm_real::get_pool_reserves`,
            functionArguments: [DEPLOYER_ADDRESS, 0], // Pool ID 0
          },
        });

        const ptReserve = Number(reserves[0]);
        const ytReserve = Number(reserves[1]);
        const k = ptReserve * ytReserve;

        const amountIn = Number(amount) * 100000000;

        if (fromToken === "PT") {
          const newPtReserve = ptReserve + amountIn;
          const newYtReserve = k / newPtReserve;
          const ytOut = (ytReserve - newYtReserve) * 0.997; // 0.3% fee
          setEstimatedOutput((ytOut / 100000000).toFixed(4));
        } else {
          const newYtReserve = ytReserve + amountIn;
          const newPtReserve = k / newYtReserve;
          const ptOut = (ptReserve - newPtReserve) * 0.997;
          setEstimatedOutput((ptOut / 100000000).toFixed(4));
        }
      } catch (error) {
        console.error("Error fetching price:", error);
      }
    };

    fetchPrice();
  }, [amount, fromToken]);

  const handleSwap = async () => {
    if (!amount || Number(amount) <= 0) {
      toast.error("Enter a valid amount");
      return;
    }

    setLoading(true);

    try {
      const functionName =
        fromToken === "PT" ? "swap_pt_for_yt" : "swap_yt_for_pt";

      const response = await signAndSubmitTransaction({
        sender: account.address,
        data: {
          function: `${CONTRACT_ADDRESS}::pt_yt_amm_real::${functionName}`,
          functionArguments: [
            DEPLOYER_ADDRESS,
            0, // Pool ID
            Number(amount) * 100000000,
            0, // Min output (set to 0 for now, should add slippage protection)
          ],
        },
      });

      await aptos.waitForTransaction({ transactionHash: response.hash });

      toast.success("Swap successful!");
      setAmount("");
    } catch (error) {
      console.error(error);
      toast.error("Swap failed");
    } finally {
      setLoading(false);
    }
  };

  const flip = () => {
    setFromToken(fromToken === "PT" ? "YT" : "PT");
    setAmount("");
  };

  const toToken = fromToken === "PT" ? "YT" : "PT";
  const balance = fromToken === "PT" ? ptBalance : ytBalance;

  return (
    <div className="bg-white rounded-2xl p-6 shadow-lg">
      <h2 className="text-2xl font-bold mb-4">💱 Trade Yield Tokens</h2>

      <div className="mb-4">
        <label className="block text-sm text-gray-600 mb-2">You Sell</label>
        <div className="flex gap-2">
          <input
            type="number"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            placeholder="0.00"
            className="flex-1 text-2xl p-4 border-2 rounded-xl focus:border-primary"
          />
          <select
            value={fromToken}
            onChange={(e) => setFromToken(e.target.value as "PT" | "YT")}
            className="px-4 border-2 rounded-xl font-semibold"
          >
            <option value="PT">PT</option>
            <option value="YT">YT</option>
          </select>
        </div>
        <div className="flex justify-between mt-2">
          <span className="text-sm text-gray-500">
            Balance: {balance.toFixed(4)} {fromToken}
          </span>
          <button
            onClick={() => setAmount(balance.toString())}
            className="text-sm text-primary font-semibold"
          >
            MAX
          </button>
        </div>
      </div>

      <div className="text-center my-4">
        <button
          onClick={flip}
          className="bg-gray-100 p-2 rounded-lg hover:bg-gray-200"
        >
          ↓↑ Flip
        </button>
      </div>

      <div className="bg-gray-50 rounded-xl p-4 mb-4">
        <label className="block text-sm text-gray-600 mb-2">You Receive</label>
        <div className="text-2xl font-semibold">
          ~{estimatedOutput} {toToken}
        </div>
      </div>

      <div className="text-sm text-gray-500 mb-4">
        <div className="flex justify-between">
          <span>Price:</span>
          <span>
            1 {fromToken} ={" "}
            {estimatedOutput && amount
              ? (Number(estimatedOutput) / Number(amount)).toFixed(4)
              : "0"}{" "}
            {toToken}
          </span>
        </div>
        <div className="flex justify-between">
          <span>Fee:</span>
          <span>0.3%</span>
        </div>
      </div>

      <button
        onClick={handleSwap}
        disabled={loading || !amount}
        className="w-full bg-primary text-white py-4 rounded-xl font-semibold text-lg hover:bg-blue-600 disabled:bg-gray-300"
      >
        {loading ? "Swapping..." : "Swap Now"}
      </button>
    </div>
  );
}
```

---

### STEP 7: Main App Layout (Day 9)

**7.1 Create Main App (src/App.tsx)**

```typescript
import { useState } from "react";
import { AptosWalletAdapterProvider } from "@aptos-labs/wallet-adapter-react";
import { PetraWallet } from "petra-plugin-wallet-adapter";
import { Toaster } from "react-hot-toast";
import { WalletButton } from "./components/wallet/WalletButton";
import { Earn } from "./pages/Earn";
import { Split } from "./pages/Split";
import { Trade } from "./pages/Trade";

function YourApp() {
  const [activeTab, setActiveTab] = useState<"earn" | "split" | "trade">(
    "earn"
  );

  return (
    <div className="min-h-screen bg-gray-50">
      <Toaster position="top-right" />

      {/* Header */}
      <header className="bg-white shadow-sm">
        <div className="max-w-7xl mx-auto px-4 py-4 flex justify-between items-center">
          <h1 className="text-2xl font-bold">Yield Protocol</h1>
          <WalletButton />
        </div>
      </header>

      {/* Tabs */}
      <div className="max-w-7xl mx-auto px-4 mt-6">
        <div className="flex gap-2 border-b">
          {[
            { id: "earn", label: "💰 Earn", desc: "Stake APT" },
            { id: "split", label: "🔀 Split", desc: "Tokenize Yield" },
            { id: "trade", label: "💱 Trade", desc: "Swap PT/YT" },
          ].map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id as any)}
              className={`px-6 py-3 font-semibold border-b-2 transition-colors ${
                activeTab === tab.id
                  ? "border-primary text-primary"
                  : "border-transparent text-gray-500 hover:text-gray-700"
              }`}
            >
              <div>{tab.label}</div>
              <div className="text-xs">{tab.desc}</div>
            </button>
          ))}
        </div>
      </div>

      {/* Content */}
      <div className="max-w-7xl mx-auto px-4 py-8">
        {activeTab === "earn" && <Earn />}
        {activeTab === "split" && <Split />}
        {activeTab === "trade" && <Trade />}
      </div>
    </div>
  );
}

function App() {
  const wallets = [new PetraWallet()];

  return (
    <AptosWalletAdapterProvider plugins={wallets} autoConnect={true}>
      <YourApp />
    </AptosWalletAdapterProvider>
  );
}

export default App;
```

---

### STEP 8: Testing & Polish (Day 10)

**8.1 Test Checklist**

- [ ] Wallet connects successfully
- [ ] Balances display correctly
- [ ] Stake APT works
- [ ] Split stAPT works
- [ ] Swap PT/YT works
- [ ] Error messages show properly
- [ ] Loading states work
- [ ] Mobile responsive

**8.2 Add Loading States**

```typescript
{
  loading && (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center">
      <div className="bg-white p-6 rounded-xl">
        <div className="animate-spin h-8 w-8 border-4 border-primary border-t-transparent rounded-full"></div>
        <div className="mt-2">Processing...</div>
      </div>
    </div>
  );
}
```

**8.3 Add Error Boundaries**

```typescript
class ErrorBoundary extends React.Component {
  componentDidCatch(error, errorInfo) {
    console.error("Error:", error, errorInfo);
    toast.error("Something went wrong. Please refresh.");
  }

  render() {
    return this.props.children;
  }
}
```

---

### STEP 9: Deployment (Day 11)

**9.1 Build for Production**

```bash
npm run build
```

**9.2 Deploy to Vercel/Netlify**

```bash
# Vercel
npm install -g vercel
vercel

# Or Netlify
npm install -g netlify-cli
netlify deploy --prod
```

**9.3 Set Environment Variables**

```
REACT_APP_NETWORK=testnet
REACT_APP_CONTRACT_ADDRESS=0xYOUR_ADDRESS
REACT_APP_DEPLOYER_ADDRESS=0xDEPLOYER_ADDRESS
```

---

## 🛠️ Technical Requirements

### Wallet Integration

- Support Petra, Martian, Pontem wallets
- Auto-detect installed wallets
- Clear connection status
- Easy disconnect option

### Real-Time Updates

- Balance updates every 10 seconds
- Price updates every 5 seconds
- Transaction status polling
- Optimistic UI updates

### Performance

- Initial load < 2 seconds
- Interaction response < 100ms
- Smooth animations (60fps)
- Lazy load non-critical data

---

## 📚 Tooltips & Help Text

### Stake APT

```
💡 "Staking locks your APT and gives you stAPT tokens
    that grow in value as you earn 9.5% APY"
```

### PT Token

```
💡 "Principal Token - Redeemable for your original
    stAPT at maturity. Like a zero-coupon bond."
```

### YT Token

```
💡 "Yield Token - Captures all the yield your stAPT
    earns until maturity. Trade it if you think
    yield will change."
```

### Maturity

```
💡 "The date when your PT can be redeemed for stAPT.
    Longer maturity = more yield for YT holders."
```

### Implied APY

```
💡 "What the market thinks the yield will be, based
    on current PT/YT prices. Compare to actual APY."
```

---

## 🎨 Example Screens (ASCII Mockups)

### Dashboard View

```
┌─────────────────────────────────────────────────┐
│  [Earn] [Split] [Trade]              [Connect]  │
├─────────────────────────────────────────────────┤
│                                                  │
│  Your Portfolio                                  │
│  ┌──────────────────────────────────────────┐  │
│  │  Total Value: $340.50                    │  │
│  │                                           │  │
│  │  100 stAPT    →  $305.00                 │  │
│  │  50 PT        →  $23.75                  │  │
│  │  50 YT        →  $11.75                  │  │
│  └──────────────────────────────────────────┘  │
│                                                  │
│  Quick Actions                                   │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐        │
│  │ Stake    │ │ Split    │ │ Trade    │        │
│  │ More APT │ │ Yield    │ │ Tokens   │        │
│  └──────────┘ └──────────┘ └──────────┘        │
│                                                  │
│  Recent Activity                                 │
│  • Staked 100 APT → 100 stAPT (2 days ago)     │
│  • Split 50 stAPT → 50 PT + 50 YT (1 day ago)  │
│                                                  │
└─────────────────────────────────────────────────┘
```

---

## 🚀 Implementation Priority

### Phase 1 (MVP - Week 1-2)

- [ ] Wallet connection
- [ ] Stake APT interface
- [ ] View staked position
- [ ] Basic responsive design

### Phase 2 (Core Features - Week 3-4)

- [ ] Split interface
- [ ] View PT/YT balances
- [ ] Trade interface (swap)
- [ ] Transaction history

### Phase 3 (Polish - Week 5-6)

- [ ] Add liquidity interface
- [ ] Advanced settings
- [ ] Tooltips and help
- [ ] Mobile optimization
- [ ] Dark mode

### Phase 4 (Nice-to-Have - Week 7+)

- [ ] Portfolio dashboard
- [ ] Price charts
- [ ] Notifications
- [ ] Social sharing

---

## 🎯 Final Checklist

Before launch, ensure:

- [ ] User can stake in < 30 seconds
- [ ] All actions have clear outcomes
- [ ] No unexplained jargon
- [ ] Mobile works perfectly
- [ ] Error messages are helpful
- [ ] Loading states are clear
- [ ] Success confirmations are satisfying
- [ ] User never feels lost

---

## 📞 Questions to Ask During Development

1. "Can my mom use this without asking questions?"
2. "Is there any screen where I don't know what to do next?"
3. "Am I showing too much information at once?"
4. "Would I trust this with my money?"
5. "Does this feel faster than other DeFi apps?"

If any answer is "no", simplify more.

---

**Remember: Simple > Feature-rich. Clear > Clever. Fast > Perfect.**

Good luck! 🚀
