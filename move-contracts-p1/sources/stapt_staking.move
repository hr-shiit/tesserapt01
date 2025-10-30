module yield_tokenization::stapt_staking {
    use std::signer;
    use aptos_framework::coin::{Self, Coin};
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::timestamp;
    use aptos_framework::event;
    use yield_tokenization::coin_types::{Self, StAPT};

    // Error codes
    const E_NOT_INITIALIZED: u64 = 1;
    const E_ALREADY_INITIALIZED: u64 = 2;
    const E_ZERO_AMOUNT: u64 = 3;
    const E_INSUFFICIENT_BALANCE: u64 = 4;

    // Constants
    const DECIMALS_MULTIPLIER: u64 = 100000000; // 10^8
    const STAPT_APY_BPS: u64 = 950; // 9.5% APY
    const SECONDS_PER_YEAR: u64 = 31536000;

    // Treasury to hold APT
    struct Treasury has key {
        apt_reserve: Coin<AptosCoin>,
        total_apt_deposited: u64,
        total_stapt_minted: u64,
        exchange_rate: u64, // stAPT per APT (scaled by 10^8)
        last_compound_time: u64,
        coin_caps_addr: address,
    }

    // Events
    #[event]
    struct StakeEvent has drop, store {
        user: address,
        apt_amount: u64,
        stapt_amount: u64,
        exchange_rate: u64,
        timestamp: u64,
    }

    #[event]
    struct UnstakeEvent has drop, store {
        user: address,
        stapt_amount: u64,
        apt_amount: u64,
        exchange_rate: u64,
        timestamp: u64,
    }

    #[event]
    struct CompoundEvent has drop, store {
        old_exchange_rate: u64,
        new_exchange_rate: u64,
        yield_accrued: u64,
        timestamp: u64,
    }

    // Initialize the staking treasury
    public entry fun initialize(admin: &signer, coin_caps_addr: address) {
        let admin_addr = signer::address_of(admin);
        assert!(!exists<Treasury>(admin_addr), E_ALREADY_INITIALIZED);

        move_to(admin, Treasury {
            apt_reserve: coin::zero<AptosCoin>(),
            total_apt_deposited: 0,
            total_stapt_minted: 0,
            exchange_rate: DECIMALS_MULTIPLIER, // 1:1 initially
            last_compound_time: timestamp::now_seconds(),
            coin_caps_addr,
        });
    }

    // Stake APT and receive stAPT
    public entry fun stake_apt(
        user: &signer,
        treasury_addr: address,
        apt_amount: u64
    ) acquires Treasury {
        assert!(apt_amount > 0, E_ZERO_AMOUNT);
        
        let user_addr = signer::address_of(user);
        let treasury = borrow_global_mut<Treasury>(treasury_addr);
        
        // Compound yield before staking
        compound_yield_internal(treasury);
        
        // Withdraw APT from user
        let apt_coins = coin::withdraw<AptosCoin>(user, apt_amount);
        
        // Calculate stAPT to mint based on exchange rate
        let stapt_amount = (apt_amount * DECIMALS_MULTIPLIER) / treasury.exchange_rate;
        
        // Deposit APT to treasury
        coin::merge(&mut treasury.apt_reserve, apt_coins);
        treasury.total_apt_deposited = treasury.total_apt_deposited + apt_amount;
        treasury.total_stapt_minted = treasury.total_stapt_minted + stapt_amount;
        
        // Mint and deposit stAPT to user
        let stapt_coins = coin_types::mint_stapt(stapt_amount, treasury.coin_caps_addr);
        coin::deposit(user_addr, stapt_coins);
        
        event::emit(StakeEvent {
            user: user_addr,
            apt_amount,
            stapt_amount,
            exchange_rate: treasury.exchange_rate,
            timestamp: timestamp::now_seconds(),
        });
    }

    // Unstake stAPT and receive APT
    public entry fun unstake_apt(
        user: &signer,
        treasury_addr: address,
        stapt_amount: u64
    ) acquires Treasury {
        assert!(stapt_amount > 0, E_ZERO_AMOUNT);
        
        let user_addr = signer::address_of(user);
        let treasury = borrow_global_mut<Treasury>(treasury_addr);
        
        // Compound yield before unstaking
        compound_yield_internal(treasury);
        
        // Calculate APT to return based on exchange rate
        let apt_amount = (stapt_amount * treasury.exchange_rate) / DECIMALS_MULTIPLIER;
        
        // Check treasury has enough APT
        assert!(coin::value(&treasury.apt_reserve) >= apt_amount, E_INSUFFICIENT_BALANCE);
        
        // Withdraw stAPT from user and burn
        let stapt_coins = coin::withdraw<StAPT>(user, stapt_amount);
        coin_types::burn_stapt(stapt_coins, treasury.coin_caps_addr);
        
        // Extract APT from treasury and deposit to user
        let apt_coins = coin::extract(&mut treasury.apt_reserve, apt_amount);
        coin::deposit(user_addr, apt_coins);
        
        treasury.total_apt_deposited = treasury.total_apt_deposited - apt_amount;
        treasury.total_stapt_minted = treasury.total_stapt_minted - stapt_amount;
        
        event::emit(UnstakeEvent {
            user: user_addr,
            stapt_amount,
            apt_amount,
            exchange_rate: treasury.exchange_rate,
            timestamp: timestamp::now_seconds(),
        });
    }

    // Compound yield for all stakers
    public entry fun compound_yield(treasury_addr: address) acquires Treasury {
        let treasury = borrow_global_mut<Treasury>(treasury_addr);
        compound_yield_internal(treasury);
    }

    // Internal compound function
    fun compound_yield_internal(treasury: &mut Treasury) {
        let current_time = timestamp::now_seconds();
        let time_elapsed = current_time - treasury.last_compound_time;
        
        if (time_elapsed == 0) return;
        
        let old_rate = treasury.exchange_rate;
        
        // Calculate yield: APY * time_elapsed / seconds_per_year
        let yield_per_second = (STAPT_APY_BPS * DECIMALS_MULTIPLIER) / (10000 * SECONDS_PER_YEAR);
        let total_yield = (yield_per_second * time_elapsed) / DECIMALS_MULTIPLIER;
        
        // Update exchange rate (stAPT becomes worth more APT)
        treasury.exchange_rate = treasury.exchange_rate + 
            (treasury.exchange_rate * total_yield) / DECIMALS_MULTIPLIER;
        
        treasury.last_compound_time = current_time;
        
        event::emit(CompoundEvent {
            old_exchange_rate: old_rate,
            new_exchange_rate: treasury.exchange_rate,
            yield_accrued: total_yield,
            timestamp: current_time,
        });
    }

    // View functions
    #[view]
    public fun get_exchange_rate(treasury_addr: address): u64 acquires Treasury {
        borrow_global<Treasury>(treasury_addr).exchange_rate
    }

    #[view]
    public fun get_total_apt_deposited(treasury_addr: address): u64 acquires Treasury {
        borrow_global<Treasury>(treasury_addr).total_apt_deposited
    }

    #[view]
    public fun get_total_stapt_minted(treasury_addr: address): u64 acquires Treasury {
        borrow_global<Treasury>(treasury_addr).total_stapt_minted
    }

    #[view]
    public fun calculate_stapt_to_apt(treasury_addr: address, stapt_amount: u64): u64 acquires Treasury {
        let treasury = borrow_global<Treasury>(treasury_addr);
        (stapt_amount * treasury.exchange_rate) / DECIMALS_MULTIPLIER
    }

    #[view]
    public fun calculate_apt_to_stapt(treasury_addr: address, apt_amount: u64): u64 acquires Treasury {
        let treasury = borrow_global<Treasury>(treasury_addr);
        (apt_amount * DECIMALS_MULTIPLIER) / treasury.exchange_rate
    }

    #[view]
    public fun get_apy(): u64 {
        STAPT_APY_BPS
    }
}
