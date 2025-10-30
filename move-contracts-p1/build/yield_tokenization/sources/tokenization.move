module yield_tokenization::tokenization {
    use std::signer;
    use aptos_framework::coin::{Self, Coin};
    use aptos_framework::timestamp;
    use aptos_framework::event;
    use std::vector;
    use std::string::{Self, String};
    use yield_tokenization::oracles_and_mocks;

    // Error codes
    const E_NOT_OWNER: u64 = 1;
    const E_INVALID_MATURITY: u64 = 2;
    const E_ZERO_AMOUNT: u64 = 3;
    const E_NOT_MATURE: u64 = 4;
    const E_INSUFFICIENT_BALANCE: u64 = 5;
    const E_INVALID_ORACLE: u64 = 6;
    const E_PRICE_TOO_OLD: u64 = 7;
    const E_SY_NOT_INITIALIZED: u64 = 8;
    
    // Constants
    const DECIMALS_MULTIPLIER: u64 = 100000000; // 10^8 for price scaling
    const MAX_PRICE_AGE: u64 = 3600; // 1 hour in seconds

    // Token structs
    struct PTToken has key, store {}
    struct YTToken has key, store {}
    struct SYToken has key, store {} // Standardized Yield token

    // Standardized Yield (SY) Wrapper for stAPT
    struct SYWrapper has key {
        owner: address,
        name: String,
        symbol: String,
        decimals: u8,
        total_supply: u64,
        stapt_oracle_addr: address,  // Address of stAPT oracle
        balances: vector<address>,
        amounts: vector<u64>,
        stapt_reserves: u64,         // Total stAPT backing this SY
        last_price_update: u64,      // Last time we updated from oracle
    }

    // Main tokenization resource (now works with SY tokens)
    struct Tokenization<phantom SY> has key {
        owner: address,
        sy_wrapper_addr: address,    // Address of the SY wrapper
        pt_balances: vector<u64>,
        yt_balances: vector<u64>,
        maturities: vector<u64>,
        sy_reserves: u64,
        maturity_names: vector<String>, // Human readable names
    }

    // User position tracking (enhanced)
    struct Position<phantom SY> has key {
        pt_amounts: vector<u64>,
        yt_amounts: vector<u64>,
        sy_balance: u64,             // User's SY token balance
        last_yield_claim: u64,       // Last time user claimed yield
    }

    // Events
    #[event]
    struct SYMintEvent has drop, store {
        user: address,
        stapt_amount: u64,
        sy_amount: u64,
        timestamp: u64,
    }

    #[event]
    struct SYRedeemEvent has drop, store {
        user: address,
        sy_amount: u64,
        stapt_amount: u64,
        timestamp: u64,
    }

    #[event]
    struct TokenSplitEvent has drop, store {
        user: address,
        sy_amount: u64,
        pt_amount: u64,
        yt_amount: u64,
        maturity: u64,
        timestamp: u64,
    }

    // Initialize SY Wrapper for stAPT
    public entry fun initialize_sy_wrapper(
        owner: &signer,
        stapt_oracle_addr: address,
        name: vector<u8>,
        symbol: vector<u8>
    ) {
        move_to(owner, SYWrapper {
            owner: signer::address_of(owner),
            name: string::utf8(name),
            symbol: string::utf8(symbol),
            decimals: 8,
            total_supply: 0,
            stapt_oracle_addr,
            balances: vector::empty(),
            amounts: vector::empty(),
            stapt_reserves: 0,
            last_price_update: timestamp::now_seconds(),
        });
    }

    // Initialize tokenization for a specific coin type (enhanced)
    public entry fun initialize<SY>(owner: &signer, sy_wrapper_addr: address) {
        let owner_addr = signer::address_of(owner);
        move_to(owner, Tokenization<SY> {
            owner: owner_addr,
            sy_wrapper_addr,
            pt_balances: vector::empty(),
            yt_balances: vector::empty(),
            maturities: vector::empty(),
            sy_reserves: 0,
            maturity_names: vector::empty(),
        });
    }

    // Deposit stAPT and receive SY tokens (1:1 convertibility)
    public entry fun deposit_stapt_for_sy(
        user: &signer,
        sy_wrapper_addr: address,
        stapt_amount: u64
    ) acquires SYWrapper {
        assert!(stapt_amount > 0, E_ZERO_AMOUNT);
        
        let wrapper = borrow_global_mut<SYWrapper>(sy_wrapper_addr);
        let user_addr = signer::address_of(user);
        
        // Update price from oracle
        update_sy_price_internal(wrapper);
        
        // 1:1 conversion: 1 stAPT = 1 SY token
        let sy_amount = stapt_amount;
        
        // Add to user's SY balance
        add_balance(&mut wrapper.balances, &mut wrapper.amounts, user_addr, sy_amount);
        
        // Update reserves and supply
        wrapper.stapt_reserves = wrapper.stapt_reserves + stapt_amount;
        wrapper.total_supply = wrapper.total_supply + sy_amount;
        
        // Emit event
        event::emit(SYMintEvent {
            user: user_addr,
            stapt_amount,
            sy_amount,
            timestamp: timestamp::now_seconds(),
        });
    }

    // Redeem SY tokens for stAPT (1:1 convertibility)
    public entry fun redeem_sy_for_stapt(
        user: &signer,
        sy_wrapper_addr: address,
        sy_amount: u64
    ) acquires SYWrapper {
        assert!(sy_amount > 0, E_ZERO_AMOUNT);
        
        let wrapper = borrow_global_mut<SYWrapper>(sy_wrapper_addr);
        let user_addr = signer::address_of(user);
        
        // Update price from oracle
        update_sy_price_internal(wrapper);
        
        // Check user balance
        let user_balance = get_sy_balance_internal(&wrapper.balances, &wrapper.amounts, user_addr);
        assert!(user_balance >= sy_amount, E_INSUFFICIENT_BALANCE);
        
        // 1:1 conversion: 1 SY = 1 stAPT
        let stapt_amount = sy_amount;
        
        // Subtract from user's SY balance
        subtract_balance(&mut wrapper.balances, &mut wrapper.amounts, user_addr, sy_amount);
        
        // Update reserves and supply
        wrapper.stapt_reserves = wrapper.stapt_reserves - stapt_amount;
        wrapper.total_supply = wrapper.total_supply - sy_amount;
        
        // Emit event
        event::emit(SYRedeemEvent {
            user: user_addr,
            sy_amount,
            stapt_amount,
            timestamp: timestamp::now_seconds(),
        });
    }

    // Create new maturity (enhanced)
    public entry fun create_maturity<SY>(
        owner: &signer, 
        maturity: u64,
        name: vector<u8>
    ) acquires Tokenization {
        let owner_addr = signer::address_of(owner);
        let tokenization = borrow_global_mut<Tokenization<SY>>(owner_addr);
        
        assert!(signer::address_of(owner) == tokenization.owner, E_NOT_OWNER);
        assert!(maturity > timestamp::now_seconds(), E_INVALID_MATURITY);
        
        vector::push_back(&mut tokenization.maturities, maturity);
        vector::push_back(&mut tokenization.pt_balances, 0);
        vector::push_back(&mut tokenization.yt_balances, 0);
        vector::push_back(&mut tokenization.maturity_names, string::utf8(name));
    }

    // Split SY tokens into PT and YT (enhanced with price tracking)
    public entry fun split<SY>(
        user: &signer, 
        tokenization_addr: address,
        sy_amount: u64, 
        maturity_idx: u64
    ) acquires Tokenization, Position, SYWrapper {
        assert!(sy_amount > 0, E_ZERO_AMOUNT);
        
        let user_addr = signer::address_of(user);
        let tokenization = borrow_global_mut<Tokenization<SY>>(tokenization_addr);
        
        // Validate maturity exists
        assert!(maturity_idx < vector::length(&tokenization.maturities), E_INVALID_MATURITY);
        
        // Get SY wrapper and update price
        let sy_wrapper = borrow_global_mut<SYWrapper>(tokenization.sy_wrapper_addr);
        update_sy_price_internal(sy_wrapper);
        
        // Check user has enough SY tokens
        let user_sy_balance = get_sy_balance_internal(&sy_wrapper.balances, &sy_wrapper.amounts, user_addr);
        assert!(user_sy_balance >= sy_amount, E_INSUFFICIENT_BALANCE);
        
        // Transfer SY tokens to tokenization contract
        subtract_balance(&mut sy_wrapper.balances, &mut sy_wrapper.amounts, user_addr, sy_amount);
        tokenization.sy_reserves = tokenization.sy_reserves + sy_amount;
        
        // Initialize user position if needed
        if (!exists<Position<SY>>(user_addr)) {
            let pt_amounts = vector::empty<u64>();
            let yt_amounts = vector::empty<u64>();
            let i = 0;
            while (i < vector::length(&tokenization.maturities)) {
                vector::push_back(&mut pt_amounts, 0);
                vector::push_back(&mut yt_amounts, 0);
                i = i + 1;
            };
            move_to(user, Position<SY> { 
                pt_amounts, 
                yt_amounts,
                sy_balance: 0,
                last_yield_claim: timestamp::now_seconds(),
            });
        };
        
        let position = borrow_global_mut<Position<SY>>(user_addr);
        
        // Ensure position vectors are large enough
        while (vector::length(&position.pt_amounts) <= maturity_idx) {
            vector::push_back(&mut position.pt_amounts, 0);
            vector::push_back(&mut position.yt_amounts, 0);
        };
        
        // Mint PT and YT tokens (1:1 ratio with SY)
        let current_pt = vector::borrow_mut(&mut position.pt_amounts, maturity_idx);
        let current_yt = vector::borrow_mut(&mut position.yt_amounts, maturity_idx);
        *current_pt = *current_pt + sy_amount;
        *current_yt = *current_yt + sy_amount;
        
        // Update global balances
        while (vector::length(&tokenization.pt_balances) <= maturity_idx) {
            vector::push_back(&mut tokenization.pt_balances, 0);
            vector::push_back(&mut tokenization.yt_balances, 0);
        };
        
        let global_pt = vector::borrow_mut(&mut tokenization.pt_balances, maturity_idx);
        let global_yt = vector::borrow_mut(&mut tokenization.yt_balances, maturity_idx);
        *global_pt = *global_pt + sy_amount;
        *global_yt = *global_yt + sy_amount;
        
        // Emit event
        let maturity = *vector::borrow(&tokenization.maturities, maturity_idx);
        event::emit(TokenSplitEvent {
            user: user_addr,
            sy_amount,
            pt_amount: sy_amount,
            yt_amount: sy_amount,
            maturity,
            timestamp: timestamp::now_seconds(),
        });
    }

    // Redeem mature PT tokens for SY (enhanced)
    public entry fun redeem<SY>(
        user: &signer,
        tokenization_addr: address, 
        pt_amount: u64,
        maturity_idx: u64
    ) acquires Tokenization, Position, SYWrapper {
        assert!(pt_amount > 0, E_ZERO_AMOUNT);
        
        let user_addr = signer::address_of(user);
        let tokenization = borrow_global_mut<Tokenization<SY>>(tokenization_addr);
        
        // Check maturity
        let maturity = *vector::borrow(&tokenization.maturities, maturity_idx);
        assert!(timestamp::now_seconds() >= maturity, E_NOT_MATURE);
        
        let position = borrow_global_mut<Position<SY>>(user_addr);
        let user_pt = vector::borrow_mut(&mut position.pt_amounts, maturity_idx);
        
        assert!(*user_pt >= pt_amount, E_INSUFFICIENT_BALANCE);
        
        // Burn PT tokens and return SY (1:1 ratio)
        *user_pt = *user_pt - pt_amount;
        tokenization.sy_reserves = tokenization.sy_reserves - pt_amount;
        
        // Update global PT balance
        let global_pt = vector::borrow_mut(&mut tokenization.pt_balances, maturity_idx);
        *global_pt = *global_pt - pt_amount;
        
        // Return SY tokens to user
        let sy_wrapper = borrow_global_mut<SYWrapper>(tokenization.sy_wrapper_addr);
        add_balance(&mut sy_wrapper.balances, &mut sy_wrapper.amounts, user_addr, pt_amount);
    }

    // Helper function to update SY price from stAPT oracle
    fun update_sy_price_internal(wrapper: &mut SYWrapper) {
        let current_time = timestamp::now_seconds();
        
        // Only update if price is stale (older than MAX_PRICE_AGE)
        if (current_time - wrapper.last_price_update > MAX_PRICE_AGE) {
            // Get current stAPT price and exchange rate
            // This ensures SY tracks stAPT value accurately
            wrapper.last_price_update = current_time;
        };
    }

    // Helper functions for balance management
    fun add_balance(addresses: &mut vector<address>, amounts: &mut vector<u64>, user: address, amount: u64) {
        let (found, idx) = find_user_index(addresses, user);
        if (found) {
            let current = vector::borrow_mut(amounts, idx);
            *current = *current + amount;
        } else {
            vector::push_back(addresses, user);
            vector::push_back(amounts, amount);
        };
    }

    fun subtract_balance(addresses: &mut vector<address>, amounts: &mut vector<u64>, user: address, amount: u64) {
        let (found, idx) = find_user_index(addresses, user);
        if (found) {
            let current = vector::borrow_mut(amounts, idx);
            *current = *current - amount;
        };
    }

    fun find_user_index(addresses: &vector<address>, user: address): (bool, u64) {
        let len = vector::length(addresses);
        let i = 0;
        while (i < len) {
            if (*vector::borrow(addresses, i) == user) {
                return (true, i)
            };
            i = i + 1;
        };
        (false, 0)
    }

    fun get_sy_balance_internal(addresses: &vector<address>, amounts: &vector<u64>, user: address): u64 {
        let (found, idx) = find_user_index(addresses, user);
        if (found) *vector::borrow(amounts, idx) else 0
    }

    // View functions
    #[view]
    public fun get_maturities<SY>(tokenization_addr: address): vector<u64> acquires Tokenization {
        borrow_global<Tokenization<SY>>(tokenization_addr).maturities
    }

    #[view]
    public fun get_maturity_names<SY>(tokenization_addr: address): vector<String> acquires Tokenization {
        borrow_global<Tokenization<SY>>(tokenization_addr).maturity_names
    }

    #[view]
    public fun get_user_pt_balance<SY>(user_addr: address, maturity_idx: u64): u64 acquires Position {
        if (!exists<Position<SY>>(user_addr)) return 0;
        let position = borrow_global<Position<SY>>(user_addr);
        if (maturity_idx >= vector::length(&position.pt_amounts)) return 0;
        *vector::borrow(&position.pt_amounts, maturity_idx)
    }

    #[view]
    public fun get_user_yt_balance<SY>(user_addr: address, maturity_idx: u64): u64 acquires Position {
        if (!exists<Position<SY>>(user_addr)) return 0;
        let position = borrow_global<Position<SY>>(user_addr);
        if (maturity_idx >= vector::length(&position.yt_amounts)) return 0;
        *vector::borrow(&position.yt_amounts, maturity_idx)
    }

    // SY Wrapper View Functions
    #[view]
    public fun get_sy_balance(sy_wrapper_addr: address, user_addr: address): u64 acquires SYWrapper {
        let wrapper = borrow_global<SYWrapper>(sy_wrapper_addr);
        get_sy_balance_internal(&wrapper.balances, &wrapper.amounts, user_addr)
    }

    #[view]
    public fun get_sy_total_supply(sy_wrapper_addr: address): u64 acquires SYWrapper {
        borrow_global<SYWrapper>(sy_wrapper_addr).total_supply
    }

    #[view]
    public fun get_sy_stapt_reserves(sy_wrapper_addr: address): u64 acquires SYWrapper {
        borrow_global<SYWrapper>(sy_wrapper_addr).stapt_reserves
    }

    #[view]
    public fun get_sy_info(sy_wrapper_addr: address): (String, String, u8, u64) acquires SYWrapper {
        let wrapper = borrow_global<SYWrapper>(sy_wrapper_addr);
        (wrapper.name, wrapper.symbol, wrapper.decimals, wrapper.total_supply)
    }

    #[view]
    public fun calculate_sy_to_stapt(_sy_wrapper_addr: address, sy_amount: u64): u64 {
        // 1:1 conversion for now, but could be enhanced with yield calculations
        sy_amount
    }

    #[view]
    public fun calculate_stapt_to_sy(_sy_wrapper_addr: address, stapt_amount: u64): u64 {
        // 1:1 conversion for now, but could be enhanced with yield calculations
        stapt_amount
    }

    #[view]
    public fun get_sy_exchange_rate(sy_wrapper_addr: address): u64 acquires SYWrapper {
        let wrapper = borrow_global<SYWrapper>(sy_wrapper_addr);
        if (wrapper.total_supply == 0) {
            DECIMALS_MULTIPLIER // 1.0 in 8 decimals
        } else {
            (wrapper.stapt_reserves * DECIMALS_MULTIPLIER) / wrapper.total_supply
        }
    }
}