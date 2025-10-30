module yield_tokenization::pt_yt_amm {
    use std::signer;
    use std::vector;
    use std::string::{Self, String};
    use aptos_framework::timestamp;
    use aptos_framework::event;
    use aptos_framework::math64;

    // Error codes
    const E_NOT_OWNER: u64 = 1;
    const E_POOL_NOT_FOUND: u64 = 2;
    const E_ZERO_AMOUNT: u64 = 3;
    const E_INSUFFICIENT_BALANCE: u64 = 4;
    const E_INSUFFICIENT_LIQUIDITY: u64 = 5;
    const E_SLIPPAGE_EXCEEDED: u64 = 6;
    const E_POOL_ALREADY_EXISTS: u64 = 7;
    const E_INVALID_MATURITY: u64 = 8;
    const E_MATURITY_EXPIRED: u64 = 9;

    // Constants
    const DECIMALS_MULTIPLIER: u64 = 100000000; // 10^8
    const MIN_LIQUIDITY: u64 = 1000; // Minimum liquidity for new pools
    const TRADING_FEE_BPS: u64 = 30; // 0.3% trading fee
    const SECONDS_PER_DAY: u64 = 86400;
    const SECONDS_PER_YEAR: u64 = 31536000;

    // PT/YT Trading Pool using x*y=k constant product formula
    struct PTYTPool has store {
        pool_id: u64,
        maturity: u64,
        pt_reserve: u64,          // PT token reserves
        yt_reserve: u64,          // YT token reserves
        lp_token_supply: u64,     // Total LP tokens issued
        last_price_update: u64,   // Last time prices were updated
        total_volume_24h: u64,    // 24h trading volume
        fees_collected: u64,      // Total fees collected
        lp_providers: vector<address>, // LP token holders
        lp_balances: vector<u64>,      // LP token balances
    }

    // AMM Factory
    struct AMMFactory has key {
        owner: address,
        pools: vector<PTYTPool>,
        next_pool_id: u64,
        total_pools: u64,
        total_volume_all_time: u64,
    }

    // User LP Position
    struct LPPosition has key {
        total_lp_tokens: u64,
        pool_positions: vector<u64>,    // Pool IDs
        lp_amounts: vector<u64>,        // LP token amounts per pool
        rewards_earned: u64,            // Total rewards earned
        last_reward_claim: u64,         // Last reward claim time
    }

    // Events
    #[event]
    struct PoolCreatedEvent has drop, store {
        pool_id: u64,
        maturity: u64,
        initial_pt: u64,
        initial_yt: u64,
        timestamp: u64,
    }

    #[event]
    struct SwapEvent has drop, store {
        user: address,
        pool_id: u64,
        token_in: String,  // "PT" or "YT"
        amount_in: u64,
        amount_out: u64,
        new_pt_price: u64,
        new_yt_price: u64,
        timestamp: u64,
    }

    #[event]
    struct LiquidityEvent has drop, store {
        user: address,
        pool_id: u64,
        action: String,    // "ADD" or "REMOVE"
        pt_amount: u64,
        yt_amount: u64,
        lp_tokens: u64,
        timestamp: u64,
    }

    // Initialize AMM Factory (no initial liquidity needed from protocol)
    public entry fun initialize_amm_factory(owner: &signer) {
        move_to(owner, AMMFactory {
            owner: signer::address_of(owner),
            pools: vector::empty(),
            next_pool_id: 0,
            total_pools: 0,
            total_volume_all_time: 0,
        });
    }

    // Create empty pool template - Users add liquidity later
    public entry fun create_empty_pool(
        creator: &signer,
        factory_addr: address,
        maturity: u64,
        expected_apy_bps: u64
    ) acquires AMMFactory {
        assert!(maturity > timestamp::now_seconds(), E_INVALID_MATURITY);
        
        let factory = borrow_global_mut<AMMFactory>(factory_addr);
        
        // Check if pool already exists for this maturity
        assert!(!pool_exists_for_maturity(&factory.pools, maturity), E_POOL_ALREADY_EXISTS);
        
        let pool_id = factory.next_pool_id;
        
        // Create empty pool (no reserves yet)
        let pool = PTYTPool {
            pool_id,
            maturity,
            pt_reserve: 0,
            yt_reserve: 0,
            lp_token_supply: 0,
            last_price_update: timestamp::now_seconds(),
            total_volume_24h: 0,
            fees_collected: 0,
            lp_providers: vector::empty(),
            lp_balances: vector::empty(),
        };
        
        vector::push_back(&mut factory.pools, pool);
        factory.next_pool_id = factory.next_pool_id + 1;
        factory.total_pools = factory.total_pools + 1;
        
        event::emit(PoolCreatedEvent {
            pool_id,
            maturity,
            initial_pt: 0,
            initial_yt: 0,
            timestamp: timestamp::now_seconds(),
        });
    }

    // First user adds liquidity with fair pricing (becomes first LP)
    public entry fun bootstrap_pool_liquidity(
        user: &signer,
        factory_addr: address,
        pool_id: u64,
        pt_amount: u64,
        expected_apy_bps: u64
    ) acquires AMMFactory, LPPosition {
        assert!(pt_amount > 0, E_ZERO_AMOUNT);
        
        let user_addr = signer::address_of(user);
        let factory = borrow_global_mut<AMMFactory>(factory_addr);
        assert!(pool_id < vector::length(&factory.pools), E_POOL_NOT_FOUND);
        
        let pool = vector::borrow_mut(&mut factory.pools, pool_id);
        
        // Only allow bootstrap if pool is empty
        assert!(pool.pt_reserve == 0 && pool.yt_reserve == 0, E_POOL_ALREADY_EXISTS);
        assert!(timestamp::now_seconds() < pool.maturity, E_MATURITY_EXPIRED);
        
        // Calculate fair YT amount
        let time_to_maturity = pool.maturity - timestamp::now_seconds();
        let yt_amount = calculate_fair_yt_amount(pt_amount, time_to_maturity, expected_apy_bps);
        
        // Calculate initial LP tokens
        let initial_lp = math64::sqrt(pt_amount * yt_amount);
        assert!(initial_lp >= MIN_LIQUIDITY, E_INSUFFICIENT_LIQUIDITY);
        
        // Update pool reserves
        pool.pt_reserve = pt_amount;
        pool.yt_reserve = yt_amount;
        pool.lp_token_supply = initial_lp;
        
        // Add user as first LP
        vector::push_back(&mut pool.lp_providers, user_addr);
        vector::push_back(&mut pool.lp_balances, initial_lp);
        
        // Initialize user's LP position
        if (!exists<LPPosition>(user_addr)) {
            move_to(user, LPPosition {
                total_lp_tokens: 0,
                pool_positions: vector::empty(),
                lp_amounts: vector::empty(),
                rewards_earned: 0,
                last_reward_claim: timestamp::now_seconds(),
            });
        };
        
        let position = borrow_global_mut<LPPosition>(user_addr);
        vector::push_back(&mut position.pool_positions, pool_id);
        vector::push_back(&mut position.lp_amounts, initial_lp);
        position.total_lp_tokens = position.total_lp_tokens + initial_lp;
        
        event::emit(LiquidityEvent {
            user: user_addr,
            pool_id,
            action: string::utf8(b"BOOTSTRAP"),
            pt_amount,
            yt_amount,
            lp_tokens: initial_lp,
            timestamp: timestamp::now_seconds(),
        });
    }

    // ONE-STEP: User creates pool and provides initial liquidity (NO PROTOCOL FUNDS NEEDED)
    public entry fun create_and_bootstrap_pool(
        user: &signer,
        factory_addr: address,
        maturity: u64,
        pt_amount: u64,
        expected_apy_bps: u64
    ) acquires AMMFactory, LPPosition {
        assert!(pt_amount > 0, E_ZERO_AMOUNT);
        assert!(maturity > timestamp::now_seconds(), E_INVALID_MATURITY);
        
        let factory = borrow_global_mut<AMMFactory>(factory_addr);
        
        // Check if pool already exists
        assert!(!pool_exists_for_maturity(&factory.pools, maturity), E_POOL_ALREADY_EXISTS);
        
        let pool_id = factory.next_pool_id;
        
        // Calculate fair YT amount
        let time_to_maturity = maturity - timestamp::now_seconds();
        let yt_amount = calculate_fair_yt_amount(pt_amount, time_to_maturity, expected_apy_bps);
        
        // Calculate LP tokens
        let initial_lp = math64::sqrt(pt_amount * yt_amount);
        assert!(initial_lp >= MIN_LIQUIDITY, E_INSUFFICIENT_LIQUIDITY);
        
        let user_addr = signer::address_of(user);
        
        // Create pool with user's liquidity
        let pool = PTYTPool {
            pool_id,
            maturity,
            pt_reserve: pt_amount,
            yt_reserve: yt_amount,
            lp_token_supply: initial_lp,
            last_price_update: timestamp::now_seconds(),
            total_volume_24h: 0,
            fees_collected: 0,
            lp_providers: vector::empty(),
            lp_balances: vector::empty(),
        };
        
        // Add user as first LP
        vector::push_back(&mut pool.lp_providers, user_addr);
        vector::push_back(&mut pool.lp_balances, initial_lp);
        
        vector::push_back(&mut factory.pools, pool);
        factory.next_pool_id = factory.next_pool_id + 1;
        factory.total_pools = factory.total_pools + 1;
        
        // Initialize user's LP position
        if (!exists<LPPosition>(user_addr)) {
            move_to(user, LPPosition {
                total_lp_tokens: 0,
                pool_positions: vector::empty(),
                lp_amounts: vector::empty(),
                rewards_earned: 0,
                last_reward_claim: timestamp::now_seconds(),
            });
        };
        
        let position = borrow_global_mut<LPPosition>(user_addr);
        vector::push_back(&mut position.pool_positions, pool_id);
        vector::push_back(&mut position.lp_amounts, initial_lp);
        position.total_lp_tokens = position.total_lp_tokens + initial_lp;
        
        event::emit(PoolCreatedEvent {
            pool_id,
            maturity,
            initial_pt: pt_amount,
            initial_yt: yt_amount,
            timestamp: timestamp::now_seconds(),
        });
    }

    // Create PT/YT trading pool with fair pricing (RECOMMENDED - for protocol use)
    public entry fun create_pt_yt_pool_with_fair_price(
        creator: &signer,
        factory_addr: address,
        maturity: u64,
        pt_amount: u64,
        expected_apy_bps: u64  // e.g., 950 = 9.5% APY
    ) acquires AMMFactory, LPPosition {
        // This is now just an alias for create_and_bootstrap_pool
        create_and_bootstrap_pool(creator, factory_addr, maturity, pt_amount, expected_apy_bps);
    }

    // Create PT/YT trading pool (manual ratio - use with caution)
    public entry fun create_pt_yt_pool(
        creator: &signer,
        factory_addr: address,
        maturity: u64,
        initial_pt: u64,
        initial_yt: u64
    ) acquires AMMFactory, LPPosition {
        assert!(initial_pt > 0 && initial_yt > 0, E_ZERO_AMOUNT);
        assert!(maturity > timestamp::now_seconds(), E_INVALID_MATURITY);
        
        let creator_addr = signer::address_of(creator);
        let factory = borrow_global_mut<AMMFactory>(factory_addr);
        
        // Check if pool already exists for this maturity
        assert!(!pool_exists_for_maturity(&factory.pools, maturity), E_POOL_ALREADY_EXISTS);
        
        let pool_id = factory.next_pool_id;
        
        // Calculate initial LP tokens (geometric mean)
        let initial_lp = math64::sqrt(initial_pt * initial_yt);
        assert!(initial_lp >= MIN_LIQUIDITY, E_INSUFFICIENT_LIQUIDITY);
        
        // Create pool
        let pool = PTYTPool {
            pool_id,
            maturity,
            pt_reserve: initial_pt,
            yt_reserve: initial_yt,
            lp_token_supply: initial_lp,
            last_price_update: timestamp::now_seconds(),
            total_volume_24h: 0,
            fees_collected: 0,
            lp_providers: vector::empty(),
            lp_balances: vector::empty(),
        };
        
        // Add creator as first LP provider
        vector::push_back(&mut pool.lp_providers, creator_addr);
        vector::push_back(&mut pool.lp_balances, initial_lp);
        
        vector::push_back(&mut factory.pools, pool);
        factory.next_pool_id = factory.next_pool_id + 1;
        factory.total_pools = factory.total_pools + 1;
        
        // Initialize creator's LP position
        if (!exists<LPPosition>(creator_addr)) {
            move_to(creator, LPPosition {
                total_lp_tokens: 0,
                pool_positions: vector::empty(),
                lp_amounts: vector::empty(),
                rewards_earned: 0,
                last_reward_claim: timestamp::now_seconds(),
            });
        };
        
        let position = borrow_global_mut<LPPosition>(creator_addr);
        vector::push_back(&mut position.pool_positions, pool_id);
        vector::push_back(&mut position.lp_amounts, initial_lp);
        position.total_lp_tokens = position.total_lp_tokens + initial_lp;
        
        event::emit(PoolCreatedEvent {
            pool_id,
            maturity,
            initial_pt,
            initial_yt,
            timestamp: timestamp::now_seconds(),
        });
    }

    // Swap PT for YT using x*y=k formula
    public entry fun swap_pt_for_yt(
        user: &signer,
        factory_addr: address,
        pool_id: u64,
        pt_amount_in: u64,
        min_yt_out: u64
    ) acquires AMMFactory {
        assert!(pt_amount_in > 0, E_ZERO_AMOUNT);
        
        let factory = borrow_global_mut<AMMFactory>(factory_addr);
        assert!(pool_id < vector::length(&factory.pools), E_POOL_NOT_FOUND);
        
        let pool = vector::borrow_mut(&mut factory.pools, pool_id);
        assert!(timestamp::now_seconds() < pool.maturity, E_MATURITY_EXPIRED);
        
        // Calculate output using x*y=k formula with fees
        let pt_amount_in_with_fee = pt_amount_in - (pt_amount_in * TRADING_FEE_BPS) / 10000;
        let yt_amount_out = (pool.yt_reserve * pt_amount_in_with_fee) / (pool.pt_reserve + pt_amount_in_with_fee);
        
        assert!(yt_amount_out >= min_yt_out, E_SLIPPAGE_EXCEEDED);
        assert!(yt_amount_out < pool.yt_reserve, E_INSUFFICIENT_LIQUIDITY);
        
        // Update reserves
        pool.pt_reserve = pool.pt_reserve + pt_amount_in;
        pool.yt_reserve = pool.yt_reserve - yt_amount_out;
        
        // Update volume and fees
        pool.total_volume_24h = pool.total_volume_24h + pt_amount_in;
        pool.fees_collected = pool.fees_collected + (pt_amount_in * TRADING_FEE_BPS) / 10000;
        factory.total_volume_all_time = factory.total_volume_all_time + pt_amount_in;
        
        // Calculate new prices
        let pt_price = calculate_pt_price_internal(pool);
        let yt_price = calculate_yt_price_internal(pool);
        
        event::emit(SwapEvent {
            user: signer::address_of(user),
            pool_id,
            token_in: string::utf8(b"PT"),
            amount_in: pt_amount_in,
            amount_out: yt_amount_out,
            new_pt_price: pt_price,
            new_yt_price: yt_price,
            timestamp: timestamp::now_seconds(),
        });
    }

    // Swap YT for PT using x*y=k formula
    public entry fun swap_yt_for_pt(
        user: &signer,
        factory_addr: address,
        pool_id: u64,
        yt_amount_in: u64,
        min_pt_out: u64
    ) acquires AMMFactory {
        assert!(yt_amount_in > 0, E_ZERO_AMOUNT);
        
        let factory = borrow_global_mut<AMMFactory>(factory_addr);
        assert!(pool_id < vector::length(&factory.pools), E_POOL_NOT_FOUND);
        
        let pool = vector::borrow_mut(&mut factory.pools, pool_id);
        assert!(timestamp::now_seconds() < pool.maturity, E_MATURITY_EXPIRED);
        
        // Calculate output using x*y=k formula with fees
        let yt_amount_in_with_fee = yt_amount_in - (yt_amount_in * TRADING_FEE_BPS) / 10000;
        let pt_amount_out = (pool.pt_reserve * yt_amount_in_with_fee) / (pool.yt_reserve + yt_amount_in_with_fee);
        
        assert!(pt_amount_out >= min_pt_out, E_SLIPPAGE_EXCEEDED);
        assert!(pt_amount_out < pool.pt_reserve, E_INSUFFICIENT_LIQUIDITY);
        
        // Update reserves
        pool.yt_reserve = pool.yt_reserve + yt_amount_in;
        pool.pt_reserve = pool.pt_reserve - pt_amount_out;
        
        // Update volume and fees
        pool.total_volume_24h = pool.total_volume_24h + yt_amount_in;
        pool.fees_collected = pool.fees_collected + (yt_amount_in * TRADING_FEE_BPS) / 10000;
        factory.total_volume_all_time = factory.total_volume_all_time + yt_amount_in;
        
        // Calculate new prices
        let pt_price = calculate_pt_price_internal(pool);
        let yt_price = calculate_yt_price_internal(pool);
        
        event::emit(SwapEvent {
            user: signer::address_of(user),
            pool_id,
            token_in: string::utf8(b"YT"),
            amount_in: yt_amount_in,
            amount_out: pt_amount_out,
            new_pt_price: pt_price,
            new_yt_price: yt_price,
            timestamp: timestamp::now_seconds(),
        });
    }

    // Add liquidity to PT/YT pool
    public entry fun add_liquidity_pt_yt(
        user: &signer,
        factory_addr: address,
        pool_id: u64,
        pt_amount: u64,
        yt_amount: u64
    ) acquires AMMFactory, LPPosition {
        assert!(pt_amount > 0 && yt_amount > 0, E_ZERO_AMOUNT);
        
        let user_addr = signer::address_of(user);
        let factory = borrow_global_mut<AMMFactory>(factory_addr);
        assert!(pool_id < vector::length(&factory.pools), E_POOL_NOT_FOUND);
        
        let pool = vector::borrow_mut(&mut factory.pools, pool_id);
        
        // Calculate LP tokens to mint (proportional to existing reserves)
        let lp_tokens = if (pool.lp_token_supply == 0) {
            math64::sqrt(pt_amount * yt_amount)
        } else {
            let pt_ratio = (pt_amount * pool.lp_token_supply) / pool.pt_reserve;
            let yt_ratio = (yt_amount * pool.lp_token_supply) / pool.yt_reserve;
            if (pt_ratio < yt_ratio) pt_ratio else yt_ratio
        };
        
        assert!(lp_tokens > 0, E_INSUFFICIENT_LIQUIDITY);
        
        // Update pool reserves
        pool.pt_reserve = pool.pt_reserve + pt_amount;
        pool.yt_reserve = pool.yt_reserve + yt_amount;
        pool.lp_token_supply = pool.lp_token_supply + lp_tokens;
        
        // Add user as LP provider or update existing
        let (found, idx) = find_lp_provider(&pool.lp_providers, user_addr);
        if (found) {
            let balance = vector::borrow_mut(&mut pool.lp_balances, idx);
            *balance = *balance + lp_tokens;
        } else {
            vector::push_back(&mut pool.lp_providers, user_addr);
            vector::push_back(&mut pool.lp_balances, lp_tokens);
        };
        
        // Initialize or update user LP position
        if (!exists<LPPosition>(user_addr)) {
            move_to(user, LPPosition {
                total_lp_tokens: 0,
                pool_positions: vector::empty(),
                lp_amounts: vector::empty(),
                rewards_earned: 0,
                last_reward_claim: timestamp::now_seconds(),
            });
        };
        
        let position = borrow_global_mut<LPPosition>(user_addr);
        let (pos_found, pos_idx) = find_pool_position(&position.pool_positions, pool_id);
        if (pos_found) {
            let amount = vector::borrow_mut(&mut position.lp_amounts, pos_idx);
            *amount = *amount + lp_tokens;
        } else {
            vector::push_back(&mut position.pool_positions, pool_id);
            vector::push_back(&mut position.lp_amounts, lp_tokens);
        };
        
        position.total_lp_tokens = position.total_lp_tokens + lp_tokens;
        
        event::emit(LiquidityEvent {
            user: user_addr,
            pool_id,
            action: string::utf8(b"ADD"),
            pt_amount,
            yt_amount,
            lp_tokens,
            timestamp: timestamp::now_seconds(),
        });
    }

    // Calculate fair YT amount for initial pool based on time and APY
    fun calculate_fair_yt_amount(pt_amount: u64, time_to_maturity: u64, expected_apy_bps: u64): u64 {
        // Calculate fair PT price based on time to maturity and expected yield
        // PT_price = 1 / (1 + yield)^(time_fraction)
        // Simplified: PT_price ≈ 1 - (yield * time_fraction)
        
        let time_fraction = (time_to_maturity * DECIMALS_MULTIPLIER) / SECONDS_PER_YEAR;
        let yield_decimal = (expected_apy_bps * DECIMALS_MULTIPLIER) / 10000;
        
        // PT price ≈ 1 - (yield * time_fraction)
        let pt_price = DECIMALS_MULTIPLIER - (yield_decimal * time_fraction) / DECIMALS_MULTIPLIER;
        
        // YT price = 1 - PT price
        let yt_price = DECIMALS_MULTIPLIER - pt_price;
        
        // YT amount = PT amount * (YT_price / PT_price)
        // This ensures PT_reserve/YT_reserve = YT_price/PT_price
        (pt_amount * yt_price) / pt_price
    }

    // Calculate PT price based on pool reserves
    fun calculate_pt_price_internal(pool: &PTYTPool): u64 {
        if (pool.pt_reserve == 0) return 0;
        
        // PT price = YT_reserve / PT_reserve (in terms of YT per PT)
        (pool.yt_reserve * DECIMALS_MULTIPLIER) / pool.pt_reserve
    }

    // Calculate YT price based on pool reserves
    fun calculate_yt_price_internal(pool: &PTYTPool): u64 {
        if (pool.yt_reserve == 0) return 0;
        
        // YT price = PT_reserve / YT_reserve (in terms of PT per YT)
        (pool.pt_reserve * DECIMALS_MULTIPLIER) / pool.yt_reserve
    }

    // Helper functions
    fun pool_exists_for_maturity(pools: &vector<PTYTPool>, maturity: u64): bool {
        let len = vector::length(pools);
        let i = 0;
        while (i < len) {
            if (vector::borrow(pools, i).maturity == maturity) {
                return true
            };
            i = i + 1;
        };
        false
    }

    fun find_lp_provider(providers: &vector<address>, user: address): (bool, u64) {
        let len = vector::length(providers);
        let i = 0;
        while (i < len) {
            if (*vector::borrow(providers, i) == user) {
                return (true, i)
            };
            i = i + 1;
        };
        (false, 0)
    }

    fun find_pool_position(pool_ids: &vector<u64>, pool_id: u64): (bool, u64) {
        let len = vector::length(pool_ids);
        let i = 0;
        while (i < len) {
            if (*vector::borrow(pool_ids, i) == pool_id) {
                return (true, i)
            };
            i = i + 1;
        };
        (false, 0)
    }

    // View functions
    #[view]
    public fun get_pt_price(factory_addr: address, pool_id: u64): u64 acquires AMMFactory {
        let factory = borrow_global<AMMFactory>(factory_addr);
        assert!(pool_id < vector::length(&factory.pools), E_POOL_NOT_FOUND);
        let pool = vector::borrow(&factory.pools, pool_id);
        calculate_pt_price_internal(pool)
    }

    #[view]
    public fun get_yt_price(factory_addr: address, pool_id: u64): u64 acquires AMMFactory {
        let factory = borrow_global<AMMFactory>(factory_addr);
        assert!(pool_id < vector::length(&factory.pools), E_POOL_NOT_FOUND);
        let pool = vector::borrow(&factory.pools, pool_id);
        calculate_yt_price_internal(pool)
    }

    #[view]
    public fun get_pool_reserves(factory_addr: address, pool_id: u64): (u64, u64) acquires AMMFactory {
        let factory = borrow_global<AMMFactory>(factory_addr);
        assert!(pool_id < vector::length(&factory.pools), E_POOL_NOT_FOUND);
        let pool = vector::borrow(&factory.pools, pool_id);
        (pool.pt_reserve, pool.yt_reserve)
    }

    #[view]
    public fun calculate_implied_apy(factory_addr: address, pool_id: u64): u64 acquires AMMFactory {
        let factory = borrow_global<AMMFactory>(factory_addr);
        assert!(pool_id < vector::length(&factory.pools), E_POOL_NOT_FOUND);
        let pool = vector::borrow(&factory.pools, pool_id);
        
        let current_time = timestamp::now_seconds();
        if (pool.maturity <= current_time) return 0;
        
        let days_to_maturity = (pool.maturity - current_time) / SECONDS_PER_DAY;
        if (days_to_maturity == 0) return 0;
        
        let pt_price = calculate_pt_price_internal(pool);
        let yt_price = calculate_yt_price_internal(pool);
        
        if (pt_price == 0) return 0;
        
        // Implied APY = (YT_price / PT_price) * (365 / days_to_maturity) * 100
        (yt_price * 365 * 100) / (pt_price * days_to_maturity)
    }

    #[view]
    public fun get_pool_info(factory_addr: address, pool_id: u64): (u64, u64, u64, u64, u64) acquires AMMFactory {
        let factory = borrow_global<AMMFactory>(factory_addr);
        assert!(pool_id < vector::length(&factory.pools), E_POOL_NOT_FOUND);
        let pool = vector::borrow(&factory.pools, pool_id);
        (pool.maturity, pool.pt_reserve, pool.yt_reserve, pool.lp_token_supply, pool.total_volume_24h)
    }

    #[view]
    public fun get_user_lp_balance(user_addr: address, pool_id: u64): u64 acquires LPPosition {
        if (!exists<LPPosition>(user_addr)) return 0;
        let position = borrow_global<LPPosition>(user_addr);
        let (found, idx) = find_pool_position(&position.pool_positions, pool_id);
        if (found) *vector::borrow(&position.lp_amounts, idx) else 0
    }

    #[view]
    public fun get_total_pools(factory_addr: address): u64 acquires AMMFactory {
        borrow_global<AMMFactory>(factory_addr).total_pools
    }

    // Preview fair YT amount for given PT amount and maturity
    #[view]
    public fun preview_fair_yt_amount(
        pt_amount: u64,
        maturity: u64,
        expected_apy_bps: u64
    ): u64 {
        let current_time = timestamp::now_seconds();
        if (maturity <= current_time) return pt_amount; // 1:1 at maturity
        
        let time_to_maturity = maturity - current_time;
        calculate_fair_yt_amount(pt_amount, time_to_maturity, expected_apy_bps)
    }

    // Calculate fair PT and YT prices for a given maturity and APY
    #[view]
    public fun calculate_fair_prices(
        maturity: u64,
        expected_apy_bps: u64
    ): (u64, u64) {
        let current_time = timestamp::now_seconds();
        if (maturity <= current_time) {
            return (DECIMALS_MULTIPLIER, 0) // PT=1.0, YT=0.0 at maturity
        };
        
        let time_to_maturity = maturity - current_time;
        let time_fraction = (time_to_maturity * DECIMALS_MULTIPLIER) / SECONDS_PER_YEAR;
        let yield_decimal = (expected_apy_bps * DECIMALS_MULTIPLIER) / 10000;
        
        // PT price ≈ 1 - (yield * time_fraction)
        let pt_price = DECIMALS_MULTIPLIER - (yield_decimal * time_fraction) / DECIMALS_MULTIPLIER;
        let yt_price = DECIMALS_MULTIPLIER - pt_price;
        
        (pt_price, yt_price)
    }
}