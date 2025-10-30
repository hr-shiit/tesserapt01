module yield_tokenization::simple_amm {
    use std::signer;

    // Error codes
    const E_NOT_OWNER: u64 = 1;
    const E_ZERO_AMOUNT: u64 = 2;
    const E_INSUFFICIENT_LIQUIDITY: u64 = 3;
    const E_INSUFFICIENT_OUTPUT: u64 = 4;

    // AMM pool for token pair
    struct Pool<phantom TokenA, phantom TokenB> has key {
        owner: address,
        reserve_a: u64,
        reserve_b: u64,
        fee: u64, // Fee in basis points (e.g., 30 = 0.3%)
    }

    // Initialize AMM pool
    public entry fun initialize<TokenA, TokenB>(
        owner: &signer,
        fee: u64
    ) {
        let owner_addr = signer::address_of(owner);
        move_to(owner, Pool<TokenA, TokenB> {
            owner: owner_addr,
            reserve_a: 0,
            reserve_b: 0,
            fee,
        });
    }

    // Add liquidity to pool
    public entry fun add_liquidity<TokenA, TokenB>(
        user: &signer,
        pool_addr: address,
        amount_a: u64,
        amount_b: u64
    ) acquires Pool {
        assert!(amount_a > 0 && amount_b > 0, E_ZERO_AMOUNT);
        
        let pool = borrow_global_mut<Pool<TokenA, TokenB>>(pool_addr);
        pool.reserve_a = pool.reserve_a + amount_a;
        pool.reserve_b = pool.reserve_b + amount_b;
    }

    // Swap token A for token B
    public entry fun swap_a_for_b<TokenA, TokenB>(
        user: &signer,
        pool_addr: address,
        amount_in: u64
    ) acquires Pool {
        assert!(amount_in > 0, E_ZERO_AMOUNT);
        
        let pool = borrow_global_mut<Pool<TokenA, TokenB>>(pool_addr);
        let amount_out = get_amount_out(amount_in, pool.reserve_a, pool.reserve_b, pool.fee);
        
        assert!(amount_out > 0, E_INSUFFICIENT_OUTPUT);
        assert!(amount_out <= pool.reserve_b, E_INSUFFICIENT_LIQUIDITY);
        
        pool.reserve_a = pool.reserve_a + amount_in;
        pool.reserve_b = pool.reserve_b - amount_out;
    }

    // Swap token B for token A
    public entry fun swap_b_for_a<TokenA, TokenB>(
        user: &signer,
        pool_addr: address,
        amount_in: u64
    ) acquires Pool {
        assert!(amount_in > 0, E_ZERO_AMOUNT);
        
        let pool = borrow_global_mut<Pool<TokenA, TokenB>>(pool_addr);
        let amount_out = get_amount_out(amount_in, pool.reserve_b, pool.reserve_a, pool.fee);
        
        assert!(amount_out > 0, E_INSUFFICIENT_OUTPUT);
        assert!(amount_out <= pool.reserve_a, E_INSUFFICIENT_LIQUIDITY);
        
        pool.reserve_b = pool.reserve_b + amount_in;
        pool.reserve_a = pool.reserve_a - amount_out;
    }

    // Calculate output amount using constant product formula
    #[view]
    public fun get_amount_out(
        amount_in: u64,
        reserve_in: u64,
        reserve_out: u64,
        fee: u64
    ): u64 {
        if (amount_in == 0 || reserve_in == 0 || reserve_out == 0) return 0;
        
        let amount_in_with_fee = amount_in * (1000 - fee);
        let numerator = amount_in_with_fee * reserve_out;
        let denominator = reserve_in * 1000 + amount_in_with_fee;
        
        numerator / denominator
    }

    // Get pool reserves
    #[view]
    public fun get_reserves<TokenA, TokenB>(pool_addr: address): (u64, u64) acquires Pool {
        let pool = borrow_global<Pool<TokenA, TokenB>>(pool_addr);
        (pool.reserve_a, pool.reserve_b)
    }
}