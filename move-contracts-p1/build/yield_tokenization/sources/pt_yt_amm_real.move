module yield_tokenization::pt_yt_amm_real {
    use std::signer;
    use std::vector;
    use std::string::{Self, String};
    use aptos_framework::coin::{Self, Coin};
    use aptos_framework::timestamp;
    use aptos_framework::event;
    use aptos_framework::math64;
    use yield_tokenization::coin_types::{PTToken, YTToken};

    // Error codes
    const E_NOT_OWNER: u64 = 1;
    const E_POOL_NOT_FOUND: u64 = 2;
    const E_ZERO_AMOUNT: u64 = 3;
    const E_INSUFFICIENT_LIQUIDITY: u64 = 4;
    const E_SLIPPAGE_EXCEEDED: u64 = 5;
    const E_POOL_ALREADY_EXISTS: u64 = 6;
    const E_INVALID_MATURITY: u64 = 7;

    // Constants
    const DECIMALS_MULTIPLIER: u64 = 100000000; // 10^8
    const MIN_LIQUIDITY: u64 = 1000;
    const TRADING_FEE_BPS: u64 = 30; // 0.3%

    // Pool structure
    struct Pool has store {
        pool_id: u64,
        maturity: u64,
        pt_reserve: Coin<PTToken>,
        yt_reserve: Coin<YTToken>,
        lp_token_supply: u64,
        total_volume: u64,
        fees_collected: u64,
        lp_providers: vector<address>,
        lp_balances: vector<u64>,
    }

    // AMM Factory
    struct AMMFactory has key {
        owner: address,
        pools: vector<Pool>,
        next_pool_id: u64,
    }

    // User LP Position
    struct LPPosition has key {
        pool_positions: vector<u64>,
        lp_amounts: vector<u64>,
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
        token_in: String,
        amount_in: u64,
        amount_out: u64,
        timestamp: u64,
    }

    #[event]
    struct LiquidityEvent has drop, store {
        user: address,
        pool_id: u64,
        action: String,
        pt_amount: u64,
        yt_amount: u64,
        lp_tokens: u64,
        timestamp: u64,
    }

    // Initialize AMM
    public entry fun initialize(owner: &signer) {
        move_to(owner, AMMFactory {
            owner: signer::address_of(owner),
            pools: vector::empty(),
            next_pool_id: 0,
        });
    }

    // Create PT/YT pool
    public entry fun create_pool(
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
        
        // Withdraw PT and YT from creator
        let pt_coins = coin::withdraw<PTToken>(creator, initial_pt);
        let yt_coins = coin::withdraw<YTToken>(creator, initial_yt);
        
        // Calculate initial LP tokens
        let initial_lp = math64::sqrt(initial_pt * initial_yt);
        assert!(initial_lp >= MIN_LIQUIDITY, E_INSUFFICIENT_LIQUIDITY);
        
        let pool_id = factory.next_pool_id;
        
        // Create pool
        let pool = Pool {
            pool_id,
            maturity,
            pt_reserve: pt_coins,
            yt_reserve: yt_coins,
            lp_token_supply: initial_lp,
            total_volume: 0,
            fees_collected: 0,
            lp_providers: vector::empty(),
            lp_balances: vector::empty(),
        };
        
        // Add creator as LP provider
        vector::push_back(&mut pool.lp_providers, creator_addr);
        vector::push_back(&mut pool.lp_balances, initial_lp);
        
        vector::push_back(&mut factory.pools, pool);
        factory.next_pool_id = factory.next_pool_id + 1;
        
        // Initialize creator's LP position
        if (!exists<LPPosition>(creator_addr)) {
            move_to(creator, LPPosition {
                pool_positions: vector::empty(),
                lp_amounts: vector::empty(),
            });
        };
        
        let position = borrow_global_mut<LPPosition>(creator_addr);
        vector::push_back(&mut position.pool_positions, pool_id);
        vector::push_back(&mut position.lp_amounts, initial_lp);
        
        event::emit(PoolCreatedEvent {
            pool_id,
            maturity,
            initial_pt,
            initial_yt,
            timestamp: timestamp::now_seconds(),
        });
    }

    // Swap PT for YT
    public entry fun swap_pt_for_yt(
        user: &signer,
        factory_addr: address,
        pool_id: u64,
        pt_amount_in: u64,
        min_yt_out: u64
    ) acquires AMMFactory {
        assert!(pt_amount_in > 0, E_ZERO_AMOUNT);
        
        let user_addr = signer::address_of(user);
        let factory = borrow_global_mut<AMMFactory>(factory_addr);
        assert!(pool_id < vector::length(&factory.pools), E_POOL_NOT_FOUND);
        
        let pool = vector::borrow_mut(&mut factory.pools, pool_id);
        
        // Withdraw PT from user
        let pt_coins = coin::withdraw<PTToken>(user, pt_amount_in);
        
        // Calculate output with fee
        let pt_amount_with_fee = pt_amount_in - (pt_amount_in * TRADING_FEE_BPS) / 10000;
        let pt_reserve_value = coin::value(&pool.pt_reserve);
        let yt_reserve_value = coin::value(&pool.yt_reserve);
        let yt_amount_out = (yt_reserve_value * pt_amount_with_fee) / (pt_reserve_value + pt_amount_with_fee);
        
        assert!(yt_amount_out >= min_yt_out, E_SLIPPAGE_EXCEEDED);
        assert!(yt_amount_out < yt_reserve_value, E_INSUFFICIENT_LIQUIDITY);
        
        // Update reserves
        coin::merge(&mut pool.pt_reserve, pt_coins);
        let yt_out = coin::extract(&mut pool.yt_reserve, yt_amount_out);
        
        // Deposit YT to user
        coin::deposit(user_addr, yt_out);
        
        // Update stats
        pool.total_volume = pool.total_volume + pt_amount_in;
        pool.fees_collected = pool.fees_collected + (pt_amount_in * TRADING_FEE_BPS) / 10000;
        
        event::emit(SwapEvent {
            user: user_addr,
            pool_id,
            token_in: string::utf8(b"PT"),
            amount_in: pt_amount_in,
            amount_out: yt_amount_out,
            timestamp: timestamp::now_seconds(),
        });
    }

    // Swap YT for PT
    public entry fun swap_yt_for_pt(
        user: &signer,
        factory_addr: address,
        pool_id: u64,
        yt_amount_in: u64,
        min_pt_out: u64
    ) acquires AMMFactory {
        assert!(yt_amount_in > 0, E_ZERO_AMOUNT);
        
        let user_addr = signer::address_of(user);
        let factory = borrow_global_mut<AMMFactory>(factory_addr);
        assert!(pool_id < vector::length(&factory.pools), E_POOL_NOT_FOUND);
        
        let pool = vector::borrow_mut(&mut factory.pools, pool_id);
        
        // Withdraw YT from user
        let yt_coins = coin::withdraw<YTToken>(user, yt_amount_in);
        
        // Calculate output with fee
        let yt_amount_with_fee = yt_amount_in - (yt_amount_in * TRADING_FEE_BPS) / 10000;
        let pt_reserve_value = coin::value(&pool.pt_reserve);
        let yt_reserve_value = coin::value(&pool.yt_reserve);
        let pt_amount_out = (pt_reserve_value * yt_amount_with_fee) / (yt_reserve_value + yt_amount_with_fee);
        
        assert!(pt_amount_out >= min_pt_out, E_SLIPPAGE_EXCEEDED);
        assert!(pt_amount_out < pt_reserve_value, E_INSUFFICIENT_LIQUIDITY);
        
        // Update reserves
        coin::merge(&mut pool.yt_reserve, yt_coins);
        let pt_out = coin::extract(&mut pool.pt_reserve, pt_amount_out);
        
        // Deposit PT to user
        coin::deposit(user_addr, pt_out);
        
        // Update stats
        pool.total_volume = pool.total_volume + yt_amount_in;
        pool.fees_collected = pool.fees_collected + (yt_amount_in * TRADING_FEE_BPS) / 10000;
        
        event::emit(SwapEvent {
            user: user_addr,
            pool_id,
            token_in: string::utf8(b"YT"),
            amount_in: yt_amount_in,
            amount_out: pt_amount_out,
            timestamp: timestamp::now_seconds(),
        });
    }

    // Add liquidity
    public entry fun add_liquidity(
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
        
        // Withdraw tokens from user
        let pt_coins = coin::withdraw<PTToken>(user, pt_amount);
        let yt_coins = coin::withdraw<YTToken>(user, yt_amount);
        
        // Calculate LP tokens
        let pt_reserve_value = coin::value(&pool.pt_reserve);
        let yt_reserve_value = coin::value(&pool.yt_reserve);
        
        let lp_tokens = if (pool.lp_token_supply == 0) {
            math64::sqrt(pt_amount * yt_amount)
        } else {
            let pt_ratio = (pt_amount * pool.lp_token_supply) / pt_reserve_value;
            let yt_ratio = (yt_amount * pool.lp_token_supply) / yt_reserve_value;
            if (pt_ratio < yt_ratio) pt_ratio else yt_ratio
        };
        
        assert!(lp_tokens > 0, E_INSUFFICIENT_LIQUIDITY);
        
        // Update reserves
        coin::merge(&mut pool.pt_reserve, pt_coins);
        coin::merge(&mut pool.yt_reserve, yt_coins);
        pool.lp_token_supply = pool.lp_token_supply + lp_tokens;
        
        // Update LP provider
        let (found, idx) = find_lp_provider(&pool.lp_providers, user_addr);
        if (found) {
            let balance = vector::borrow_mut(&mut pool.lp_balances, idx);
            *balance = *balance + lp_tokens;
        } else {
            vector::push_back(&mut pool.lp_providers, user_addr);
            vector::push_back(&mut pool.lp_balances, lp_tokens);
        };
        
        // Update user position
        if (!exists<LPPosition>(user_addr)) {
            move_to(user, LPPosition {
                pool_positions: vector::empty(),
                lp_amounts: vector::empty(),
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

    // Helper functions
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
    public fun get_pool_reserves(factory_addr: address, pool_id: u64): (u64, u64) acquires AMMFactory {
        let factory = borrow_global<AMMFactory>(factory_addr);
        assert!(pool_id < vector::length(&factory.pools), E_POOL_NOT_FOUND);
        let pool = vector::borrow(&factory.pools, pool_id);
        (coin::value(&pool.pt_reserve), coin::value(&pool.yt_reserve))
    }

    #[view]
    public fun get_pt_price(factory_addr: address, pool_id: u64): u64 acquires AMMFactory {
        let factory = borrow_global<AMMFactory>(factory_addr);
        let pool = vector::borrow(&factory.pools, pool_id);
        let pt_reserve = coin::value(&pool.pt_reserve);
        if (pt_reserve == 0) return 0;
        (coin::value(&pool.yt_reserve) * DECIMALS_MULTIPLIER) / pt_reserve
    }

    #[view]
    public fun get_yt_price(factory_addr: address, pool_id: u64): u64 acquires AMMFactory {
        let factory = borrow_global<AMMFactory>(factory_addr);
        let pool = vector::borrow(&factory.pools, pool_id);
        let yt_reserve = coin::value(&pool.yt_reserve);
        if (yt_reserve == 0) return 0;
        (coin::value(&pool.pt_reserve) * DECIMALS_MULTIPLIER) / yt_reserve
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
        vector::length(&borrow_global<AMMFactory>(factory_addr).pools)
    }
}
