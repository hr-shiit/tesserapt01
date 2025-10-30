module yield_tokenization::oracles_and_mocks {
    use std::signer;
    use std::vector;
    use aptos_framework::timestamp;
    use aptos_framework::event;
    use std::string::{Self, String};
    
    // Pyth Network integration (using deployed contract)
    // We'll call the Pyth contract directly using the deployed address

    // Error codes
    const E_NOT_OWNER: u64 = 1;
    const E_NOT_UPDATER: u64 = 2;
    const E_ZERO_AMOUNT: u64 = 3;
    const E_PRICE_DEVIATION: u64 = 4;
    const E_CIRCUIT_BREAKER: u64 = 5;
    const E_INSUFFICIENT_BALANCE: u64 = 6;
    const E_PRICE_TOO_OLD: u64 = 7;
    
    // Constants
    const APT_USD_PRICE_FEED_ID: vector<u8> = x"c81f3d1ce4419653d08976f946f876b508ff915ebd047520f0e123a0cef53fdb"; // crypto.APT/USD on Pyth
    const STAPT_APY_BPS: u64 = 950; // 9.5% APY in basis points
    const SECONDS_PER_YEAR: u64 = 31536000; // 365 * 24 * 60 * 60
    const PRICE_STALENESS_THRESHOLD: u64 = 300; // 5 minutes in seconds
    const DECIMALS_MULTIPLIER: u64 = 100000000; // 10^8 for price scaling
    const PYTH_CONTRACT_ADDRESS: address = @0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387;

    // Production Price Oracle
    struct ProductionOracle has key {
        owner: address,
        updaters: vector<address>,
        prices: vector<u64>,        // Token prices (scaled by 10^8)
        timestamps: vector<u64>,    // Last update times
        thresholds: vector<u64>,    // Price thresholds
        threshold_reached: vector<bool>,
        circuit_breaker: bool,
    }

    // Mock Price Oracle (simplified)
    struct MockOracle has key {
        owner: address,
        prices: vector<u64>,
        thresholds: vector<u64>,
        threshold_reached: vector<bool>,
    }

    // Mock ERC20 Token
    struct MockToken has key {
        owner: address,
        name: vector<u8>,
        symbol: vector<u8>,
        decimals: u8,
        total_supply: u64,
        yield_rate_bps: u64,
        balances: vector<address>,
        amounts: vector<u64>,
    }

    // Mock USDC (6 decimals)
    struct MockUSDC has key {
        owner: address,
        total_supply: u64,
        balances: vector<address>,
        amounts: vector<u64>,
    }

    // stAPT Token - Tracks real APT prices with staking yield
    struct StAPTToken has key {
        owner: address,
        name: String,
        symbol: String,
        decimals: u8,
        total_supply: u64,
        balances: vector<address>,
        amounts: vector<u64>,
        last_apt_price: u64,           // Last fetched APT price from Pyth
        last_price_update: u64,        // Timestamp of last price update
        base_exchange_rate: u64,       // Base rate: 1 APT = X stAPT (scaled by 10^8)
        last_compound_time: u64,       // Last time yield was compounded
        accumulated_yield: u64,        // Total accumulated yield (scaled by 10^8)
    }

    // Pyth Oracle Integration
    struct PythOracle has key {
        owner: address,
        apt_price_feed_id: vector<u8>,
        last_apt_price: u64,
        last_update_time: u64,
        price_staleness_threshold: u64,
    }

    // Events
    #[event]
    struct PriceUpdateEvent has drop, store {
        token_symbol: String,
        old_price: u64,
        new_price: u64,
        timestamp: u64,
    }

    #[event]
    struct YieldCompoundEvent has drop, store {
        user: address,
        old_balance: u64,
        new_balance: u64,
        yield_earned: u64,
        timestamp: u64,
    }

    // Initialize Production Oracle
    public entry fun init_production_oracle(owner: &signer) {
        let owner_addr = signer::address_of(owner);
        let updaters = vector::empty();
        vector::push_back(&mut updaters, owner_addr);
        
        move_to(owner, ProductionOracle {
            owner: owner_addr,
            updaters,
            prices: vector::empty(),
            timestamps: vector::empty(),
            thresholds: vector::empty(),
            threshold_reached: vector::empty(),
            circuit_breaker: false,
        });
    }

    // Initialize Mock Oracle
    public entry fun init_mock_oracle(owner: &signer) {
        move_to(owner, MockOracle {
            owner: signer::address_of(owner),
            prices: vector::empty(),
            thresholds: vector::empty(),
            threshold_reached: vector::empty(),
        });
    }

    // Initialize Mock Token
    public entry fun init_mock_token(
        owner: &signer,
        name: vector<u8>,
        symbol: vector<u8>,
        decimals: u8,
        yield_rate_bps: u64
    ) {
        move_to(owner, MockToken {
            owner: signer::address_of(owner),
            name,
            symbol,
            decimals,
            total_supply: 0,
            yield_rate_bps,
            balances: vector::empty(),
            amounts: vector::empty(),
        });
    }

    // Initialize Mock USDC
    public entry fun init_mock_usdc(owner: &signer) {
        move_to(owner, MockUSDC {
            owner: signer::address_of(owner),
            total_supply: 0,
            balances: vector::empty(),
            amounts: vector::empty(),
        });
    }

    // Initialize stAPT Token
    public entry fun init_stapt_token(owner: &signer) {
        let current_time = timestamp::now_seconds();
        move_to(owner, StAPTToken {
            owner: signer::address_of(owner),
            name: string::utf8(b"Staked APT"),
            symbol: string::utf8(b"stAPT"),
            decimals: 8,
            total_supply: 0,
            balances: vector::empty(),
            amounts: vector::empty(),
            last_apt_price: 0,
            last_price_update: current_time,
            base_exchange_rate: DECIMALS_MULTIPLIER, // 1:1 initially
            last_compound_time: current_time,
            accumulated_yield: 0,
        });
    }

    // Initialize Pyth Oracle
    public entry fun init_pyth_oracle(owner: &signer) {
        move_to(owner, PythOracle {
            owner: signer::address_of(owner),
            apt_price_feed_id: APT_USD_PRICE_FEED_ID,
            last_apt_price: 0,
            last_update_time: 0,
            price_staleness_threshold: PRICE_STALENESS_THRESHOLD,
        });
    }

    // Update price in production oracle
    public entry fun update_price(
        updater: &signer,
        oracle_addr: address,
        token_idx: u64,
        new_price: u64
    ) acquires ProductionOracle {
        let oracle = borrow_global_mut<ProductionOracle>(oracle_addr);
        let updater_addr = signer::address_of(updater);
        
        assert!(is_updater(&oracle.updaters, updater_addr), E_NOT_UPDATER);
        assert!(!oracle.circuit_breaker, E_CIRCUIT_BREAKER);
        
        // Ensure vectors are large enough
        while (vector::length(&oracle.prices) <= token_idx) {
            vector::push_back(&mut oracle.prices, 0);
            vector::push_back(&mut oracle.timestamps, 0);
            vector::push_back(&mut oracle.thresholds, 0);
            vector::push_back(&mut oracle.threshold_reached, false);
        };
        
        // Basic price deviation check (simplified)
        let old_price = *vector::borrow(&oracle.prices, token_idx);
        if (old_price > 0) {
            let deviation = if (new_price > old_price) {
                ((new_price - old_price) * 10000) / old_price
            } else {
                ((old_price - new_price) * 10000) / old_price
            };
            assert!(deviation <= 1000, E_PRICE_DEVIATION); // Max 10% deviation
        };
        
        // Update price data
        *vector::borrow_mut(&mut oracle.prices, token_idx) = new_price;
        *vector::borrow_mut(&mut oracle.timestamps, token_idx) = timestamp::now_seconds();
        
        // Check threshold
        let threshold = *vector::borrow(&oracle.thresholds, token_idx);
        if (threshold > 0 && new_price >= threshold) {
            *vector::borrow_mut(&mut oracle.threshold_reached, token_idx) = true;
        };
    }

    // Set threshold in production oracle
    public entry fun set_threshold_production(
        setter: &signer,
        oracle_addr: address,
        token_idx: u64,
        threshold: u64
    ) acquires ProductionOracle {
        let oracle = borrow_global_mut<ProductionOracle>(oracle_addr);
        let setter_addr = signer::address_of(setter);
        
        assert!(is_updater(&oracle.updaters, setter_addr), E_NOT_UPDATER);
        
        // Ensure vectors are large enough
        while (vector::length(&oracle.thresholds) <= token_idx) {
            vector::push_back(&mut oracle.prices, 0);
            vector::push_back(&mut oracle.timestamps, 0);
            vector::push_back(&mut oracle.thresholds, 0);
            vector::push_back(&mut oracle.threshold_reached, false);
        };
        
        *vector::borrow_mut(&mut oracle.thresholds, token_idx) = threshold;
        *vector::borrow_mut(&mut oracle.threshold_reached, token_idx) = false;
    }

    // Update price in mock oracle
    public entry fun update_mock_price(
        owner: &signer,
        token_idx: u64,
        price: u64
    ) acquires MockOracle {
        let oracle = borrow_global_mut<MockOracle>(signer::address_of(owner));
        
        // Ensure vectors are large enough
        while (vector::length(&oracle.prices) <= token_idx) {
            vector::push_back(&mut oracle.prices, 0);
            vector::push_back(&mut oracle.thresholds, 0);
            vector::push_back(&mut oracle.threshold_reached, false);
        };
        
        *vector::borrow_mut(&mut oracle.prices, token_idx) = price;
        
        // Check threshold
        let threshold = *vector::borrow(&oracle.thresholds, token_idx);
        if (threshold > 0 && price >= threshold) {
            *vector::borrow_mut(&mut oracle.threshold_reached, token_idx) = true;
        };
    }

    // Mint mock tokens
    public entry fun mint_mock_token(
        owner: &signer,
        to: address,
        amount: u64
    ) acquires MockToken {
        let token = borrow_global_mut<MockToken>(signer::address_of(owner));
        assert!(amount > 0, E_ZERO_AMOUNT);
        
        add_balance(&mut token.balances, &mut token.amounts, to, amount);
        token.total_supply = token.total_supply + amount;
    }

    // Mint mock USDC
    public entry fun mint_mock_usdc(
        owner: &signer,
        to: address,
        amount: u64
    ) acquires MockUSDC {
        let usdc = borrow_global_mut<MockUSDC>(signer::address_of(owner));
        assert!(amount > 0, E_ZERO_AMOUNT);
        
        add_balance(&mut usdc.balances, &mut usdc.amounts, to, amount);
        usdc.total_supply = usdc.total_supply + amount;
    }

    // Activate circuit breaker
    public entry fun activate_circuit_breaker(owner: &signer) acquires ProductionOracle {
        let oracle = borrow_global_mut<ProductionOracle>(signer::address_of(owner));
        assert!(signer::address_of(owner) == oracle.owner, E_NOT_OWNER);
        oracle.circuit_breaker = true;
    }

    // Update APT price from external source (real Pyth price should be passed)
    public entry fun update_apt_price_from_pyth(
        updater: &signer,
        oracle_addr: address,
        real_apt_price: u64  // Pass the real APT price from Pyth (e.g., 340000000 for $3.40)
    ) acquires PythOracle, StAPTToken {
        let oracle = borrow_global_mut<PythOracle>(oracle_addr);
        
        let current_time = timestamp::now_seconds();
        let old_price = oracle.last_apt_price;
        
        // Update oracle with real price from Pyth
        oracle.last_apt_price = real_apt_price;
        oracle.last_update_time = current_time;
        
        // Emit price update event
        event::emit(PriceUpdateEvent {
            token_symbol: string::utf8(b"APT"),
            old_price,
            new_price: real_apt_price,
            timestamp: current_time,
        });
        
        // Update stAPT token price if it exists
        if (exists<StAPTToken>(oracle_addr)) {
            update_stapt_price_internal(oracle_addr, real_apt_price);
        };
    }

    // Helper function to get current APT price in USD (scaled by 10^8)
    // In production, this would call Pyth directly
    #[view]
    public fun get_real_apt_price_usd(): u64 {
        // Current APT price is approximately $3.40
        // This should be replaced with actual Pyth Network call
        340000000  // $3.40 in 8 decimals
    }

    // Mock price feeds for other assets (Phase 3 support)
    #[view]
    public fun get_btc_price_usd(): u64 {
        // Mock BTC price ~$43,000
        4300000000000  // $43,000 in 8 decimals
    }

    #[view]
    public fun get_eth_price_usd(): u64 {
        // Mock ETH price ~$2,600
        260000000000  // $2,600 in 8 decimals
    }

    #[view]
    public fun get_usdc_price_usd(): u64 {
        // USDC is stable at $1.00
        100000000  // $1.00 in 8 decimals
    }

    // Calculate pool APY based on trading volume and fees
    #[view]
    public fun calculate_pool_apy(
        base_apy_bps: u64,
        total_liquidity: u64,
        daily_volume: u64,
        fee_rate_bps: u64
    ): u64 {
        if (total_liquidity == 0) return base_apy_bps;
        
        // Calculate daily fees
        let daily_fees = (daily_volume * fee_rate_bps) / 10000;
        
        // Calculate APY from fees (daily fees * 365 / total liquidity)
        let fee_apy_bps = (daily_fees * 365 * 10000) / total_liquidity;
        
        // Return base APY + fee APY
        base_apy_bps + fee_apy_bps
    }

    // Mint stAPT tokens (stake APT)
    public entry fun mint_stapt(
        user: &signer,
        stapt_addr: address,
        apt_amount: u64
    ) acquires StAPTToken {
        let stapt = borrow_global_mut<StAPTToken>(stapt_addr);
        assert!(apt_amount > 0, E_ZERO_AMOUNT);
        
        // Compound yield before minting
        compound_yield_internal(stapt, signer::address_of(user));
        
        // Calculate stAPT amount based on current exchange rate
        let stapt_amount = (apt_amount * DECIMALS_MULTIPLIER) / stapt.base_exchange_rate;
        
        add_balance(&mut stapt.balances, &mut stapt.amounts, signer::address_of(user), stapt_amount);
        stapt.total_supply = stapt.total_supply + stapt_amount;
    }

    // Burn stAPT tokens (unstake to APT)
    public entry fun burn_stapt(
        user: &signer,
        stapt_addr: address,
        stapt_amount: u64
    ) acquires StAPTToken {
        let stapt = borrow_global_mut<StAPTToken>(stapt_addr);
        let user_addr = signer::address_of(user);
        
        // Compound yield before burning
        compound_yield_internal(stapt, user_addr);
        
        // Check balance
        let current_balance = get_stapt_balance_internal(&stapt.balances, &stapt.amounts, user_addr);
        assert!(current_balance >= stapt_amount, E_INSUFFICIENT_BALANCE);
        
        // Calculate APT amount to return
        let apt_amount = (stapt_amount * stapt.base_exchange_rate) / DECIMALS_MULTIPLIER;
        
        // Update balance
        subtract_balance(&mut stapt.balances, &mut stapt.amounts, user_addr, stapt_amount);
        stapt.total_supply = stapt.total_supply - stapt_amount;
        
        // Note: In a real implementation, you would transfer APT tokens here
    }

    // Compound yield for all users (can be called periodically)
    public entry fun compound_all_yield(
        caller: &signer,
        stapt_addr: address
    ) acquires StAPTToken {
        let stapt = borrow_global_mut<StAPTToken>(stapt_addr);
        let current_time = timestamp::now_seconds();
        
        // Calculate time elapsed since last compound
        let time_elapsed = current_time - stapt.last_compound_time;
        if (time_elapsed == 0) return;
        
        // Calculate yield rate per second
        let yield_per_second = (STAPT_APY_BPS * DECIMALS_MULTIPLIER) / (10000 * SECONDS_PER_YEAR);
        let total_yield = (yield_per_second * time_elapsed) / DECIMALS_MULTIPLIER;
        
        // Update exchange rate (makes stAPT worth more APT)
        stapt.base_exchange_rate = stapt.base_exchange_rate + 
            (stapt.base_exchange_rate * total_yield) / DECIMALS_MULTIPLIER;
        
        stapt.accumulated_yield = stapt.accumulated_yield + total_yield;
        stapt.last_compound_time = current_time;
    }

    // Helper functions
    fun is_updater(updaters: &vector<address>, addr: address): bool {
        let len = vector::length(updaters);
        let i = 0;
        while (i < len) {
            if (*vector::borrow(updaters, i) == addr) return true;
            i = i + 1;
        };
        false
    }

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

    fun subtract_balance(addresses: &mut vector<address>, amounts: &mut vector<u64>, user: address, amount: u64) {
        let (found, idx) = find_user_index(addresses, user);
        if (found) {
            let current = vector::borrow_mut(amounts, idx);
            *current = *current - amount;
        };
    }

    fun update_stapt_price_internal(stapt_addr: address, new_apt_price: u64) acquires StAPTToken {
        let stapt = borrow_global_mut<StAPTToken>(stapt_addr);
        let old_price = stapt.last_apt_price;
        stapt.last_apt_price = new_apt_price;
        stapt.last_price_update = timestamp::now_seconds();
        
        // Emit price update event
        event::emit(PriceUpdateEvent {
            token_symbol: stapt.symbol,
            old_price,
            new_price: new_apt_price,
            timestamp: timestamp::now_seconds(),
        });
    }

    fun compound_yield_internal(stapt: &mut StAPTToken, user_addr: address) {
        let current_time = timestamp::now_seconds();
        let time_elapsed = current_time - stapt.last_compound_time;
        
        if (time_elapsed > 0) {
            // Calculate yield rate per second
            let yield_per_second = (STAPT_APY_BPS * DECIMALS_MULTIPLIER) / (10000 * SECONDS_PER_YEAR);
            let total_yield = (yield_per_second * time_elapsed) / DECIMALS_MULTIPLIER;
            
            // Update exchange rate
            stapt.base_exchange_rate = stapt.base_exchange_rate + 
                (stapt.base_exchange_rate * total_yield) / DECIMALS_MULTIPLIER;
            
            stapt.accumulated_yield = stapt.accumulated_yield + total_yield;
            stapt.last_compound_time = current_time;
            
            // Emit compound event for user
            let old_balance = get_stapt_balance_internal(&stapt.balances, &stapt.amounts, user_addr);
            let yield_earned = (old_balance * total_yield) / DECIMALS_MULTIPLIER;
            
            event::emit(YieldCompoundEvent {
                user: user_addr,
                old_balance,
                new_balance: old_balance + yield_earned,
                yield_earned,
                timestamp: current_time,
            });
        };
    }

    fun get_stapt_balance_internal(addresses: &vector<address>, amounts: &vector<u64>, user: address): u64 {
        let (found, idx) = find_user_index(addresses, user);
        if (found) *vector::borrow(amounts, idx) else 0
    }

    // View functions
    #[view]
    public fun get_price(oracle_addr: address, token_idx: u64): u64 acquires ProductionOracle {
        let oracle = borrow_global<ProductionOracle>(oracle_addr);
        if (token_idx < vector::length(&oracle.prices)) {
            *vector::borrow(&oracle.prices, token_idx)
        } else { 0 }
    }

    #[view]
    public fun get_mock_price(oracle_addr: address, token_idx: u64): u64 acquires MockOracle {
        let oracle = borrow_global<MockOracle>(oracle_addr);
        if (token_idx < vector::length(&oracle.prices)) {
            *vector::borrow(&oracle.prices, token_idx)
        } else { 0 }
    }

    #[view]
    public fun threshold_reached(oracle_addr: address, token_idx: u64): bool acquires ProductionOracle {
        let oracle = borrow_global<ProductionOracle>(oracle_addr);
        if (token_idx < vector::length(&oracle.threshold_reached)) {
            *vector::borrow(&oracle.threshold_reached, token_idx)
        } else { false }
    }

    #[view]
    public fun get_mock_balance(token_addr: address, user: address): u64 acquires MockToken {
        let token = borrow_global<MockToken>(token_addr);
        let (found, idx) = find_user_index(&token.balances, user);
        if (found) *vector::borrow(&token.amounts, idx) else 0
    }

    #[view]
    public fun get_usdc_balance(usdc_addr: address, user: address): u64 acquires MockUSDC {
        let usdc = borrow_global<MockUSDC>(usdc_addr);
        let (found, idx) = find_user_index(&usdc.balances, user);
        if (found) *vector::borrow(&usdc.amounts, idx) else 0
    }

    // stAPT View Functions
    #[view]
    public fun get_stapt_balance(stapt_addr: address, user: address): u64 acquires StAPTToken {
        let stapt = borrow_global<StAPTToken>(stapt_addr);
        get_stapt_balance_internal(&stapt.balances, &stapt.amounts, user)
    }

    #[view]
    public fun get_stapt_exchange_rate(stapt_addr: address): u64 acquires StAPTToken {
        let stapt = borrow_global<StAPTToken>(stapt_addr);
        stapt.base_exchange_rate
    }

    #[view]
    public fun get_stapt_total_supply(stapt_addr: address): u64 acquires StAPTToken {
        let stapt = borrow_global<StAPTToken>(stapt_addr);
        stapt.total_supply
    }

    #[view]
    public fun get_stapt_apy(): u64 {
        STAPT_APY_BPS
    }

    #[view]
    public fun get_current_apt_price(oracle_addr: address): u64 acquires PythOracle {
        let oracle = borrow_global<PythOracle>(oracle_addr);
        oracle.last_apt_price
    }

    #[view]
    public fun get_apt_price_age(oracle_addr: address): u64 acquires PythOracle {
        let oracle = borrow_global<PythOracle>(oracle_addr);
        timestamp::now_seconds() - oracle.last_update_time
    }

    #[view]
    public fun is_apt_price_stale(oracle_addr: address): bool acquires PythOracle {
        let oracle = borrow_global<PythOracle>(oracle_addr);
        let age = timestamp::now_seconds() - oracle.last_update_time;
        age > oracle.price_staleness_threshold
    }

    #[view]
    public fun calculate_stapt_value_in_apt(stapt_addr: address, stapt_amount: u64): u64 acquires StAPTToken {
        let stapt = borrow_global<StAPTToken>(stapt_addr);
        (stapt_amount * stapt.base_exchange_rate) / DECIMALS_MULTIPLIER
    }

    #[view]
    public fun calculate_apt_to_stapt(stapt_addr: address, apt_amount: u64): u64 acquires StAPTToken {
        let stapt = borrow_global<StAPTToken>(stapt_addr);
        (apt_amount * DECIMALS_MULTIPLIER) / stapt.base_exchange_rate
    }

    #[view]
    public fun get_accumulated_yield(stapt_addr: address): u64 acquires StAPTToken {
        let stapt = borrow_global<StAPTToken>(stapt_addr);
        stapt.accumulated_yield
    }
}