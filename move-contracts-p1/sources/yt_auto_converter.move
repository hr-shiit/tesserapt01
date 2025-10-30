module yield_tokenization::auto_converter {
    use std::signer;
    use std::vector;
    use aptos_framework::timestamp;

    // Error codes
    const E_NOT_OWNER: u64 = 1;
    const E_NOT_ENABLED: u64 = 2;
    const E_THRESHOLD_NOT_REACHED: u64 = 3;
    const E_ALREADY_EXECUTED: u64 = 4;
    const E_INSUFFICIENT_BALANCE: u64 = 5;

    // Auto converter configuration
    struct AutoConverter<phantom SY> has key {
        owner: address,
        tokenization_addr: address,
        oracle_addr: address,
    }

    // User configuration for auto conversion
    struct UserConfig has key, store {
        enabled: bool,
        threshold_price: u64,  // Price threshold (scaled by 10^8)
        maturities: vector<u64>,
        executed: vector<bool>, // Track execution status per maturity
    }

    // Simple price oracle interface
    struct PriceOracle has key {
        prices: vector<u64>,
        thresholds: vector<u64>,
        threshold_reached: vector<bool>,
    }

    // Initialize auto converter
    public entry fun initialize<SY>(
        owner: &signer,
        tokenization_addr: address,
        oracle_addr: address
    ) {
        let owner_addr = signer::address_of(owner);
        move_to(owner, AutoConverter<SY> {
            owner: owner_addr,
            tokenization_addr,
            oracle_addr,
        });
    }

    // Configure user's auto conversion settings
    public entry fun configure(
        user: &signer,
        enabled: bool,
        threshold_price: u64
    ) acquires UserConfig {
        let user_addr = signer::address_of(user);
        
        if (!exists<UserConfig>(user_addr)) {
            move_to(user, UserConfig {
                enabled,
                threshold_price,
                maturities: vector::empty(),
                executed: vector::empty(),
            });
        } else {
            let config = borrow_global_mut<UserConfig>(user_addr);
            config.enabled = enabled;
            config.threshold_price = threshold_price;
        };
    }

    // Add maturity for auto conversion
    public entry fun add_maturity(
        user: &signer,
        maturity_idx: u64
    ) acquires UserConfig {
        let user_addr = signer::address_of(user);
        
        if (!exists<UserConfig>(user_addr)) {
            let maturities = vector::empty();
            let executed = vector::empty();
            vector::push_back(&mut maturities, maturity_idx);
            vector::push_back(&mut executed, false);
            
            move_to(user, UserConfig {
                enabled: true,
                threshold_price: 0,
                maturities,
                executed,
            });
        } else {
            let config = borrow_global_mut<UserConfig>(user_addr);
            vector::push_back(&mut config.maturities, maturity_idx);
            vector::push_back(&mut config.executed, false);
        };
    }

    // Execute conversion from YT to PT when threshold is reached
    public entry fun execute_conversion<SY>(
        executor: &signer,
        user_addr: address,
        maturity_idx: u64
    ) acquires UserConfig {
        let config = borrow_global_mut<UserConfig>(user_addr);
        assert!(config.enabled, E_NOT_ENABLED);
        
        // Find maturity in user's list
        let (found, idx) = find_maturity_index(&config.maturities, maturity_idx);
        assert!(found, E_INSUFFICIENT_BALANCE);
        assert!(!*vector::borrow(&config.executed, idx), E_ALREADY_EXECUTED);
        
        // Check if threshold is reached (simplified)
        assert!(is_threshold_reached(config.threshold_price), E_THRESHOLD_NOT_REACHED);
        
        // Mark as executed
        let executed_ref = vector::borrow_mut(&mut config.executed, idx);
        *executed_ref = true;
        
        // In a real implementation, this would:
        // 1. Get YT balance from tokenization contract
        // 2. Swap YT for PT through AMM
        // 3. Transfer PT tokens to user
        // For minimal version, we just mark as executed
    }

    // Check if conversion can be executed
    #[view]
    public fun can_execute_conversion(
        user_addr: address,
        maturity_idx: u64
    ): bool acquires UserConfig {
        if (!exists<UserConfig>(user_addr)) return false;
        
        let config = borrow_global<UserConfig>(user_addr);
        if (!config.enabled) return false;
        
        let (found, idx) = find_maturity_index(&config.maturities, maturity_idx);
        if (!found) return false;
        
        let already_executed = *vector::borrow(&config.executed, idx);
        if (already_executed) return false;
        
        is_threshold_reached(config.threshold_price)
    }

    // Get user's configured maturities
    #[view]
    public fun get_user_maturities(user_addr: address): vector<u64> acquires UserConfig {
        if (!exists<UserConfig>(user_addr)) return vector::empty();
        borrow_global<UserConfig>(user_addr).maturities
    }

    // Helper function to find maturity index
    fun find_maturity_index(maturities: &vector<u64>, target: u64): (bool, u64) {
        let len = vector::length(maturities);
        let i = 0;
        while (i < len) {
            if (*vector::borrow(maturities, i) == target) {
                return (true, i)
            };
            i = i + 1;
        };
        (false, 0)
    }

    // Simplified threshold check (in real implementation, would query oracle)
    fun is_threshold_reached(threshold: u64): bool {
        // Simplified: assume threshold is reached if current time is even
        timestamp::now_seconds() % 2 == 0
    }

    // Initialize simple oracle (for testing)
    public entry fun init_oracle(owner: &signer) {
        move_to(owner, PriceOracle {
            prices: vector::empty(),
            thresholds: vector::empty(),
            threshold_reached: vector::empty(),
        });
    }

    // Set threshold in oracle
    public entry fun set_threshold(
        oracle_owner: &signer,
        threshold: u64
    ) acquires PriceOracle {
        let oracle = borrow_global_mut<PriceOracle>(signer::address_of(oracle_owner));
        vector::push_back(&mut oracle.thresholds, threshold);
        vector::push_back(&mut oracle.threshold_reached, false);
    }

    // Trigger threshold (for testing)
    public entry fun trigger_threshold(
        oracle_owner: &signer,
        idx: u64
    ) acquires PriceOracle {
        let oracle = borrow_global_mut<PriceOracle>(signer::address_of(oracle_owner));
        let reached_ref = vector::borrow_mut(&mut oracle.threshold_reached, idx);
        *reached_ref = true;
    }
}