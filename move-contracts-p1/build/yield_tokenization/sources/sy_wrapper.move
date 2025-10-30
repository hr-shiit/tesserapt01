module yield_tokenization::sy_wrapper {
    use std::signer;
    use aptos_framework::coin::{Self, Coin};
    use aptos_framework::timestamp;
    use aptos_framework::event;
    use yield_tokenization::coin_types::{Self, StAPT, SYToken};

    // Error codes
    const E_NOT_INITIALIZED: u64 = 1;
    const E_ZERO_AMOUNT: u64 = 2;
    const E_INSUFFICIENT_BALANCE: u64 = 3;

    // Constants
    const DECIMALS_MULTIPLIER: u64 = 100000000; // 10^8

    // SY Treasury
    struct SYTreasury has key {
        stapt_reserve: Coin<StAPT>,
        total_stapt_deposited: u64,
        total_sy_minted: u64,
        exchange_rate: u64, // SY per stAPT (1:1 for now)
        coin_caps_addr: address,
    }

    // Events
    #[event]
    struct DepositEvent has drop, store {
        user: address,
        stapt_amount: u64,
        sy_amount: u64,
        timestamp: u64,
    }

    #[event]
    struct RedeemEvent has drop, store {
        user: address,
        sy_amount: u64,
        stapt_amount: u64,
        timestamp: u64,
    }

    // Initialize SY wrapper
    public entry fun initialize(admin: &signer, coin_caps_addr: address) {
        let admin_addr = signer::address_of(admin);
        assert!(!exists<SYTreasury>(admin_addr), E_NOT_INITIALIZED);

        move_to(admin, SYTreasury {
            stapt_reserve: coin::zero<StAPT>(),
            total_stapt_deposited: 0,
            total_sy_minted: 0,
            exchange_rate: DECIMALS_MULTIPLIER, // 1:1
            coin_caps_addr,
        });
    }

    // Deposit stAPT and receive SY tokens
    public entry fun deposit_stapt(
        user: &signer,
        treasury_addr: address,
        stapt_amount: u64
    ) acquires SYTreasury {
        assert!(stapt_amount > 0, E_ZERO_AMOUNT);
        
        let user_addr = signer::address_of(user);
        let treasury = borrow_global_mut<SYTreasury>(treasury_addr);
        
        // Withdraw stAPT from user
        let stapt_coins = coin::withdraw<StAPT>(user, stapt_amount);
        
        // Calculate SY to mint (1:1 for now)
        let sy_amount = (stapt_amount * DECIMALS_MULTIPLIER) / treasury.exchange_rate;
        
        // Deposit stAPT to treasury
        coin::merge(&mut treasury.stapt_reserve, stapt_coins);
        treasury.total_stapt_deposited = treasury.total_stapt_deposited + stapt_amount;
        treasury.total_sy_minted = treasury.total_sy_minted + sy_amount;
        
        // Mint and deposit SY to user
        let sy_coins = coin_types::mint_sy(sy_amount, treasury.coin_caps_addr);
        coin::deposit(user_addr, sy_coins);
        
        event::emit(DepositEvent {
            user: user_addr,
            stapt_amount,
            sy_amount,
            timestamp: timestamp::now_seconds(),
        });
    }

    // Redeem SY tokens for stAPT
    public entry fun redeem_sy(
        user: &signer,
        treasury_addr: address,
        sy_amount: u64
    ) acquires SYTreasury {
        assert!(sy_amount > 0, E_ZERO_AMOUNT);
        
        let user_addr = signer::address_of(user);
        let treasury = borrow_global_mut<SYTreasury>(treasury_addr);
        
        // Calculate stAPT to return (1:1 for now)
        let stapt_amount = (sy_amount * treasury.exchange_rate) / DECIMALS_MULTIPLIER;
        
        // Check treasury has enough stAPT
        assert!(coin::value(&treasury.stapt_reserve) >= stapt_amount, E_INSUFFICIENT_BALANCE);
        
        // Withdraw SY from user and burn
        let sy_coins = coin::withdraw<SYToken>(user, sy_amount);
        coin_types::burn_sy(sy_coins, treasury.coin_caps_addr);
        
        // Extract stAPT from treasury and deposit to user
        let stapt_coins = coin::extract(&mut treasury.stapt_reserve, stapt_amount);
        coin::deposit(user_addr, stapt_coins);
        
        treasury.total_stapt_deposited = treasury.total_stapt_deposited - stapt_amount;
        treasury.total_sy_minted = treasury.total_sy_minted - sy_amount;
        
        event::emit(RedeemEvent {
            user: user_addr,
            sy_amount,
            stapt_amount,
            timestamp: timestamp::now_seconds(),
        });
    }

    // View functions
    #[view]
    public fun get_exchange_rate(treasury_addr: address): u64 acquires SYTreasury {
        borrow_global<SYTreasury>(treasury_addr).exchange_rate
    }

    #[view]
    public fun get_total_stapt_deposited(treasury_addr: address): u64 acquires SYTreasury {
        borrow_global<SYTreasury>(treasury_addr).total_stapt_deposited
    }

    #[view]
    public fun get_total_sy_minted(treasury_addr: address): u64 acquires SYTreasury {
        borrow_global<SYTreasury>(treasury_addr).total_sy_minted
    }

    #[view]
    public fun calculate_sy_to_stapt(treasury_addr: address, sy_amount: u64): u64 acquires SYTreasury {
        let treasury = borrow_global<SYTreasury>(treasury_addr);
        (sy_amount * treasury.exchange_rate) / DECIMALS_MULTIPLIER
    }

    #[view]
    public fun calculate_stapt_to_sy(treasury_addr: address, stapt_amount: u64): u64 acquires SYTreasury {
        let treasury = borrow_global<SYTreasury>(treasury_addr);
        (stapt_amount * DECIMALS_MULTIPLIER) / treasury.exchange_rate
    }
}
