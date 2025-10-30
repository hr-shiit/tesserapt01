module yield_tokenization::multi_lp_staking {
    use std::signer;
    use std::vector;
    use std::string::{Self, String};
    use aptos_framework::timestamp;
    use aptos_framework::event;
    use yield_tokenization::oracles_and_mocks;

    // Error codes
    const E_NOT_OWNER: u64 = 1;
    const E_POOL_NOT_FOUND: u64 = 2;
    const E_ZERO_AMOUNT: u64 = 3;
    const E_INSUFFICIENT_BALANCE: u64 = 4;
    const E_POOL_ALREADY_EXISTS: u64 = 5;
    const E_INVALID_POOL_ID: u64 = 6;

    // Constants
    const DECIMALS_MULTIPLIER: u64 = 100000000; // 10^8
    const SECONDS_PER_YEAR: u64 = 31536000; // 365 * 24 * 60 * 60
    const TRADING_FEE_BPS: u64 = 30; // 0.3% trading fee
    const MIN_LIQUIDITY: u64 = 1000; // Minimum liquidity requirement

    // Staking Pool Structure
    struct StakingPool has store {
        pool_id: u64,
        name: String,
        symbol: String,
        token_a_oracle: address,  // e.g., stAPT oracle
        token_b_oracle: address,  // e.g., USDC oracle
        base_apy_bps: u64,        // Base APY in basis points
        current_apy_bps: u64,     // Current APY including fees
        total_liquidity: u64,     // Total LP tokens
        total_volume_24h: u64,    // 24h trading volume
        fees_collected: u64,      // Total fees collected
        last_update: u64,         // Last APY update timestamp
        stakers: vector<address>, // List of stakers
        stakes: vector<u64>,      // Corresponding stake amounts
    }

    // Main Staking System
    struct StakingPools has key {
        owner: address,
        pools: vector<StakingPool>,
        next_pool_id: u64,
        total_pools: u64,
        best_yield_pool_id: u64,  // Pool with highest APY
    }

    // User Staking Position
    struct UserStakingPosition has key {
        total_staked: u64,
        pool_stakes: vector<u64>,     // Amount staked in each pool
        pool_ids: vector<u64>,        // Pool IDs user is staking in
        last_claim_time: u64,         // Last time user claimed rewards
        pending_rewards: u64,         // Unclaimed rewards
    }

    // Events
    #[event]
    struct PoolCreatedEvent has drop, store {
        pool_id: u64,
        name: String,
        base_apy_bps: u64,
        timestamp: u64,
    }

    #[event]
    struct StakeEvent has drop, store {
        user: address,
        pool_id: u64,
        amount: u64,
        new_apy: u64,
        timestamp: u64,
    }

    #[event]
    struct BestYieldUpdateEvent has drop, store {
        old_pool_id: u64,
        new_pool_id: u64,
        new_apy: u64,
        timestamp: u64,
    }

    // Initialize the staking pools system
    public entry fun initialize_staking_pools(owner: &signer) {
        move_to(owner, StakingPools {
            owner: signer::address_of(owner),
            pools: vector::empty(),
            next_pool_id: 0,
            total_pools: 0,
            best_yield_pool_id: 0,
        });
    }

    // Create a new staking pool
    public entry fun create_staking_pool(
        owner: &signer,
        name: vector<u8>,
        symbol: vector<u8>,
        token_a_oracle: address,
        token_b_oracle: address,
        base_apy_bps: u64
    ) acquires StakingPools {
        let staking_pools = borrow_global_mut<StakingPools>(signer::address_of(owner));
        assert!(signer::address_of(owner) == staking_pools.owner, E_NOT_OWNER);

        let pool_id = staking_pools.next_pool_id;
        let pool = StakingPool {
            pool_id,
            name: string::utf8(name),
            symbol: string::utf8(symbol),
            token_a_oracle,
            token_b_oracle,
            base_apy_bps,
            current_apy_bps: base_apy_bps,
            total_liquidity: 0,
            total_volume_24h: 0,
            fees_collected: 0,
            last_update: timestamp::now_seconds(),
            stakers: vector::empty(),
            stakes: vector::empty(),
        };

        vector::push_back(&mut staking_pools.pools, pool);
        staking_pools.next_pool_id = staking_pools.next_pool_id + 1;
        staking_pools.total_pools = staking_pools.total_pools + 1;

        // Update best yield pool if this is better
        update_best_yield_pool_internal(staking_pools);

        event::emit(PoolCreatedEvent {
            pool_id,
            name: string::utf8(name),
            base_apy_bps,
            timestamp: timestamp::now_seconds(),
        });
    }

    // Stake to a specific pool
    public entry fun stake_to_pool(
        user: &signer,
        staking_pools_addr: address,
        pool_id: u64,
        amount: u64
    ) acquires StakingPools, UserStakingPosition {
        assert!(amount > 0, E_ZERO_AMOUNT);
        
        let user_addr = signer::address_of(user);
        let staking_pools = borrow_global_mut<StakingPools>(staking_pools_addr);
        
        assert!(pool_id < vector::length(&staking_pools.pools), E_INVALID_POOL_ID);
        
        // Initialize user position if needed
        if (!exists<UserStakingPosition>(user_addr)) {
            move_to(user, UserStakingPosition {
                total_staked: 0,
                pool_stakes: vector::empty(),
                pool_ids: vector::empty(),
                last_claim_time: timestamp::now_seconds(),
                pending_rewards: 0,
            });
        };
        
        let position = borrow_global_mut<UserStakingPosition>(user_addr);
        
        // Update pool APY based on new liquidity
        update_pool_apy_internal(staking_pools, pool_id, amount, true);
        
        let pool = vector::borrow_mut(&mut staking_pools.pools, pool_id);
        let current_apy = pool.current_apy_bps; // Store APY before borrowing issues
        
        // Add user to pool if not already there
        let (found, stake_idx) = find_user_in_pool(&pool.stakers, user_addr);
        if (found) {
            let current_stake = vector::borrow_mut(&mut pool.stakes, stake_idx);
            *current_stake = *current_stake + amount;
        } else {
            vector::push_back(&mut pool.stakers, user_addr);
            vector::push_back(&mut pool.stakes, amount);
        };
        
        // Update user position
        let (user_found, user_idx) = find_pool_in_user_position(&position.pool_ids, pool_id);
        if (user_found) {
            let user_stake = vector::borrow_mut(&mut position.pool_stakes, user_idx);
            *user_stake = *user_stake + amount;
        } else {
            vector::push_back(&mut position.pool_ids, pool_id);
            vector::push_back(&mut position.pool_stakes, amount);
        };
        
        position.total_staked = position.total_staked + amount;
        pool.total_liquidity = pool.total_liquidity + amount;
        
        // Update best yield pool
        update_best_yield_pool_internal(staking_pools);
        
        event::emit(StakeEvent {
            user: user_addr,
            pool_id,
            amount,
            new_apy: current_apy,
            timestamp: timestamp::now_seconds(),
        });
    }

    // Stake to the best yield pool automatically
    public entry fun stake_to_best_pool(
        user: &signer,
        staking_pools_addr: address,
        amount: u64
    ) acquires StakingPools, UserStakingPosition {
        let staking_pools = borrow_global<StakingPools>(staking_pools_addr);
        let best_pool_id = get_best_yield_pool_internal(staking_pools);
        
        stake_to_pool(user, staking_pools_addr, best_pool_id, amount);
    }

    // Update pool APY based on trading activity and liquidity
    fun update_pool_apy_internal(
        staking_pools: &mut StakingPools,
        pool_id: u64,
        liquidity_change: u64,
        is_deposit: bool
    ) {
        let pool = vector::borrow_mut(&mut staking_pools.pools, pool_id);
        let current_time = timestamp::now_seconds();
        
        // Simulate trading volume based on liquidity
        let simulated_volume = pool.total_liquidity / 10; // 10% of liquidity as daily volume
        pool.total_volume_24h = simulated_volume;
        
        // Calculate fees from trading volume
        let daily_fees = (simulated_volume * TRADING_FEE_BPS) / 10000;
        pool.fees_collected = pool.fees_collected + daily_fees;
        
        // Calculate APY boost from fees
        let fee_apy_boost = if (pool.total_liquidity > 0) {
            (daily_fees * 365 * 10000) / pool.total_liquidity
        } else { 0 };
        
        // Update current APY (base APY + fee boost)
        pool.current_apy_bps = pool.base_apy_bps + fee_apy_boost;
        
        // Apply liquidity impact (more liquidity = slightly lower APY due to dilution)
        if (is_deposit && liquidity_change > 0) {
            let dilution_factor = (liquidity_change * 100) / (pool.total_liquidity + liquidity_change);
            if (dilution_factor > 0) {
                pool.current_apy_bps = pool.current_apy_bps - (dilution_factor / 10);
            };
        };
        
        pool.last_update = current_time;
    }

    // Find the best yield pool
    fun get_best_yield_pool_internal(staking_pools: &StakingPools): u64 {
        let best_pool_id = 0;
        let best_apy = 0;
        let i = 0;
        
        while (i < vector::length(&staking_pools.pools)) {
            let pool = vector::borrow(&staking_pools.pools, i);
            if (pool.current_apy_bps > best_apy) {
                best_apy = pool.current_apy_bps;
                best_pool_id = pool.pool_id;
            };
            i = i + 1;
        };
        
        best_pool_id
    }

    // Update the best yield pool tracker
    fun update_best_yield_pool_internal(staking_pools: &mut StakingPools) {
        let old_best = staking_pools.best_yield_pool_id;
        let new_best = get_best_yield_pool_internal(staking_pools);
        
        if (old_best != new_best) {
            staking_pools.best_yield_pool_id = new_best;
            
            let new_apy = if (vector::length(&staking_pools.pools) > new_best) {
                vector::borrow(&staking_pools.pools, new_best).current_apy_bps
            } else { 0 };
            
            event::emit(BestYieldUpdateEvent {
                old_pool_id: old_best,
                new_pool_id: new_best,
                new_apy,
                timestamp: timestamp::now_seconds(),
            });
        };
    }

    // Helper functions
    fun find_user_in_pool(stakers: &vector<address>, user: address): (bool, u64) {
        let len = vector::length(stakers);
        let i = 0;
        while (i < len) {
            if (*vector::borrow(stakers, i) == user) {
                return (true, i)
            };
            i = i + 1;
        };
        (false, 0)
    }

    fun find_pool_in_user_position(pool_ids: &vector<u64>, pool_id: u64): (bool, u64) {
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
    public fun get_best_yield_pool(staking_pools_addr: address): u64 acquires StakingPools {
        let staking_pools = borrow_global<StakingPools>(staking_pools_addr);
        staking_pools.best_yield_pool_id
    }

    #[view]
    public fun get_pool_apy(staking_pools_addr: address, pool_id: u64): u64 acquires StakingPools {
        let staking_pools = borrow_global<StakingPools>(staking_pools_addr);
        assert!(pool_id < vector::length(&staking_pools.pools), E_INVALID_POOL_ID);
        vector::borrow(&staking_pools.pools, pool_id).current_apy_bps
    }

    #[view]
    public fun get_pool_info(staking_pools_addr: address, pool_id: u64): (String, u64, u64, u64) acquires StakingPools {
        let staking_pools = borrow_global<StakingPools>(staking_pools_addr);
        assert!(pool_id < vector::length(&staking_pools.pools), E_INVALID_POOL_ID);
        let pool = vector::borrow(&staking_pools.pools, pool_id);
        (pool.name, pool.current_apy_bps, pool.total_liquidity, pool.total_volume_24h)
    }

    #[view]
    public fun get_user_total_staked(user_addr: address): u64 acquires UserStakingPosition {
        if (!exists<UserStakingPosition>(user_addr)) return 0;
        borrow_global<UserStakingPosition>(user_addr).total_staked
    }

    #[view]
    public fun get_user_pool_stake(user_addr: address, pool_id: u64): u64 acquires UserStakingPosition {
        if (!exists<UserStakingPosition>(user_addr)) return 0;
        let position = borrow_global<UserStakingPosition>(user_addr);
        let (found, idx) = find_pool_in_user_position(&position.pool_ids, pool_id);
        if (found) *vector::borrow(&position.pool_stakes, idx) else 0
    }

    #[view]
    public fun get_all_pool_apys(staking_pools_addr: address): vector<u64> acquires StakingPools {
        let staking_pools = borrow_global<StakingPools>(staking_pools_addr);
        let apys = vector::empty<u64>();
        let i = 0;
        while (i < vector::length(&staking_pools.pools)) {
            let pool = vector::borrow(&staking_pools.pools, i);
            vector::push_back(&mut apys, pool.current_apy_bps);
            i = i + 1;
        };
        apys
    }

    #[view]
    public fun get_total_pools(staking_pools_addr: address): u64 acquires StakingPools {
        borrow_global<StakingPools>(staking_pools_addr).total_pools
    }
}