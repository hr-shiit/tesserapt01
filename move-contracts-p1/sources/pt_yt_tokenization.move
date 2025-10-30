module yield_tokenization::pt_yt_tokenization {
    use std::signer;
    use std::vector;
    use std::string::{Self, String};
    use aptos_framework::coin::{Self, Coin};
    use aptos_framework::timestamp;
    use aptos_framework::event;
    use yield_tokenization::coin_types::{Self, SYToken, PTToken, YTToken};

    // Error codes
    const E_NOT_INITIALIZED: u64 = 1;
    const E_ZERO_AMOUNT: u64 = 2;
    const E_INSUFFICIENT_BALANCE: u64 = 3;
    const E_INVALID_MATURITY: u64 = 4;
    const E_NOT_MATURE: u64 = 5;
    const E_MATURITY_NOT_FOUND: u64 = 6;

    // Constants
    const DECIMALS_MULTIPLIER: u64 = 100000000; // 10^8

    // Maturity info
    struct Maturity has store, copy, drop {
        maturity_timestamp: u64,
        name: String,
        total_pt_minted: u64,
        total_yt_minted: u64,
    }

    // PT/YT Treasury
    struct PTYTTreasury has key {
        sy_reserve: Coin<SYToken>,
        maturities: vector<Maturity>,
        total_sy_locked: u64,
        coin_caps_addr: address,
    }

    // Events
    #[event]
    struct SplitEvent has drop, store {
        user: address,
        sy_amount: u64,
        pt_amount: u64,
        yt_amount: u64,
        maturity: u64,
        timestamp: u64,
    }

    #[event]
    struct RedeemEvent has drop, store {
        user: address,
        pt_amount: u64,
        sy_amount: u64,
        maturity: u64,
        timestamp: u64,
    }

    #[event]
    struct MaturityCreatedEvent has drop, store {
        maturity: u64,
        name: String,
        timestamp: u64,
    }

    // Initialize PT/YT treasury
    public entry fun initialize(admin: &signer, coin_caps_addr: address) {
        let admin_addr = signer::address_of(admin);
        assert!(!exists<PTYTTreasury>(admin_addr), E_NOT_INITIALIZED);

        move_to(admin, PTYTTreasury {
            sy_reserve: coin::zero<SYToken>(),
            maturities: vector::empty(),
            total_sy_locked: 0,
            coin_caps_addr,
        });
    }

    // Create a new maturity
    public entry fun create_maturity(
        admin: &signer,
        maturity_timestamp: u64,
        name: vector<u8>
    ) acquires PTYTTreasury {
        let admin_addr = signer::address_of(admin);
        let treasury = borrow_global_mut<PTYTTreasury>(admin_addr);
        
        assert!(maturity_timestamp > timestamp::now_seconds(), E_INVALID_MATURITY);
        
        let maturity = Maturity {
            maturity_timestamp,
            name: string::utf8(name),
            total_pt_minted: 0,
            total_yt_minted: 0,
        };
        
        vector::push_back(&mut treasury.maturities, maturity);
        
        event::emit(MaturityCreatedEvent {
            maturity: maturity_timestamp,
            name: string::utf8(name),
            timestamp: timestamp::now_seconds(),
        });
    }

    // Split SY into PT and YT
    public entry fun split_sy(
        user: &signer,
        treasury_addr: address,
        sy_amount: u64,
        maturity_timestamp: u64
    ) acquires PTYTTreasury {
        assert!(sy_amount > 0, E_ZERO_AMOUNT);
        
        let user_addr = signer::address_of(user);
        let treasury = borrow_global_mut<PTYTTreasury>(treasury_addr);
        
        // Find maturity
        let (found, idx) = find_maturity(&treasury.maturities, maturity_timestamp);
        assert!(found, E_MATURITY_NOT_FOUND);
        
        // Withdraw SY from user
        let sy_coins = coin::withdraw<SYToken>(user, sy_amount);
        
        // Deposit SY to treasury
        coin::merge(&mut treasury.sy_reserve, sy_coins);
        treasury.total_sy_locked = treasury.total_sy_locked + sy_amount;
        
        // Update maturity stats
        let maturity = vector::borrow_mut(&mut treasury.maturities, idx);
        maturity.total_pt_minted = maturity.total_pt_minted + sy_amount;
        maturity.total_yt_minted = maturity.total_yt_minted + sy_amount;
        
        // Mint PT and YT (1:1 with SY)
        let pt_coins = coin_types::mint_pt(sy_amount, treasury.coin_caps_addr);
        let yt_coins = coin_types::mint_yt(sy_amount, treasury.coin_caps_addr);
        
        // Deposit to user
        coin::deposit(user_addr, pt_coins);
        coin::deposit(user_addr, yt_coins);
        
        event::emit(SplitEvent {
            user: user_addr,
            sy_amount,
            pt_amount: sy_amount,
            yt_amount: sy_amount,
            maturity: maturity_timestamp,
            timestamp: timestamp::now_seconds(),
        });
    }

    // Redeem mature PT for SY
    public entry fun redeem_pt(
        user: &signer,
        treasury_addr: address,
        pt_amount: u64,
        maturity_timestamp: u64
    ) acquires PTYTTreasury {
        assert!(pt_amount > 0, E_ZERO_AMOUNT);
        
        let user_addr = signer::address_of(user);
        let treasury = borrow_global_mut<PTYTTreasury>(treasury_addr);
        
        // Find maturity
        let (found, idx) = find_maturity(&treasury.maturities, maturity_timestamp);
        assert!(found, E_MATURITY_NOT_FOUND);
        
        let maturity = vector::borrow(&treasury.maturities, idx);
        assert!(timestamp::now_seconds() >= maturity.maturity_timestamp, E_NOT_MATURE);
        
        // Check treasury has enough SY
        assert!(coin::value(&treasury.sy_reserve) >= pt_amount, E_INSUFFICIENT_BALANCE);
        
        // Withdraw PT from user and burn
        let pt_coins = coin::withdraw<PTToken>(user, pt_amount);
        coin_types::burn_pt(pt_coins, treasury.coin_caps_addr);
        
        // Extract SY from treasury and deposit to user
        let sy_coins = coin::extract(&mut treasury.sy_reserve, pt_amount);
        coin::deposit(user_addr, sy_coins);
        
        treasury.total_sy_locked = treasury.total_sy_locked - pt_amount;
        
        event::emit(RedeemEvent {
            user: user_addr,
            pt_amount,
            sy_amount: pt_amount,
            maturity: maturity_timestamp,
            timestamp: timestamp::now_seconds(),
        });
    }

    // Combine PT and YT back to SY (before maturity)
    public entry fun combine_pt_yt(
        user: &signer,
        treasury_addr: address,
        amount: u64,
        maturity_timestamp: u64
    ) acquires PTYTTreasury {
        assert!(amount > 0, E_ZERO_AMOUNT);
        
        let user_addr = signer::address_of(user);
        let treasury = borrow_global_mut<PTYTTreasury>(treasury_addr);
        
        // Find maturity
        let (found, _idx) = find_maturity(&treasury.maturities, maturity_timestamp);
        assert!(found, E_MATURITY_NOT_FOUND);
        
        // Check treasury has enough SY
        assert!(coin::value(&treasury.sy_reserve) >= amount, E_INSUFFICIENT_BALANCE);
        
        // Withdraw and burn PT and YT
        let pt_coins = coin::withdraw<PTToken>(user, amount);
        let yt_coins = coin::withdraw<YTToken>(user, amount);
        coin_types::burn_pt(pt_coins, treasury.coin_caps_addr);
        coin_types::burn_yt(yt_coins, treasury.coin_caps_addr);
        
        // Extract SY from treasury and deposit to user
        let sy_coins = coin::extract(&mut treasury.sy_reserve, amount);
        coin::deposit(user_addr, sy_coins);
        
        treasury.total_sy_locked = treasury.total_sy_locked - amount;
    }

    // Helper functions
    fun find_maturity(maturities: &vector<Maturity>, maturity_timestamp: u64): (bool, u64) {
        let len = vector::length(maturities);
        let i = 0;
        while (i < len) {
            if (vector::borrow(maturities, i).maturity_timestamp == maturity_timestamp) {
                return (true, i)
            };
            i = i + 1;
        };
        (false, 0)
    }

    // View functions
    #[view]
    public fun get_total_sy_locked(treasury_addr: address): u64 acquires PTYTTreasury {
        borrow_global<PTYTTreasury>(treasury_addr).total_sy_locked
    }

    #[view]
    public fun get_maturity_count(treasury_addr: address): u64 acquires PTYTTreasury {
        vector::length(&borrow_global<PTYTTreasury>(treasury_addr).maturities)
    }

    #[view]
    public fun get_maturity_info(treasury_addr: address, idx: u64): (u64, String, u64, u64) acquires PTYTTreasury {
        let treasury = borrow_global<PTYTTreasury>(treasury_addr);
        let maturity = vector::borrow(&treasury.maturities, idx);
        (maturity.maturity_timestamp, maturity.name, maturity.total_pt_minted, maturity.total_yt_minted)
    }
}
