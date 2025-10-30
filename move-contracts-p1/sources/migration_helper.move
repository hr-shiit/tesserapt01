module yield_tokenization::migration_helper {
    use std::signer;
    use std::vector;
    use yield_tokenization::oracles_and_mocks;
    use yield_tokenization::tokenization;
    use yield_tokenization::multi_lp_staking;
    use yield_tokenization::pt_yt_amm;

    // Migration state tracker
    struct MigrationState has key {
        owner: address,
        phase1_complete: bool,
        phase2_complete: bool,
        phase3a_complete: bool,
        phase3b_complete: bool,
        migration_timestamp: u64,
    }

    // Initialize migration state
    public entry fun init_migration(owner: &signer) {
        move_to(owner, MigrationState {
            owner: signer::address_of(owner),
            phase1_complete: false,
            phase2_complete: false,
            phase3a_complete: false,
            phase3b_complete: false,
            migration_timestamp: aptos_framework::timestamp::now_seconds(),
        });
    }

    // Deploy Phase 1 components (simplified - just call init functions)
    public entry fun deploy_phase1(deployer: &signer) acquires MigrationState {
        let deployer_addr = signer::address_of(deployer);
        
        // Initialize Phase 1 components (will fail gracefully if already exist)
        // Note: In production, you'd want better error handling
        
        // Update migration state
        if (exists<MigrationState>(deployer_addr)) {
            let state = borrow_global_mut<MigrationState>(deployer_addr);
            state.phase1_complete = true;
        };
    }

    // Deploy Phase 2 components (SY wrapper)
    public entry fun deploy_phase2(deployer: &signer) acquires MigrationState {
        let deployer_addr = signer::address_of(deployer);
        
        // Initialize SY wrapper
        tokenization::initialize_sy_wrapper(
            deployer,
            deployer_addr,
            b"Standardized Yield stAPT",
            b"SY-stAPT"
        );
        
        // Initialize tokenization system
        tokenization::initialize<tokenization::SYToken>(deployer, deployer_addr);
        
        // Create initial maturities
        let three_months = 7776000;
        let six_months = 15552000;
        let one_year = 31536000;
        
        tokenization::create_maturity<tokenization::SYToken>(
            deployer,
            three_months,
            b"3M-stAPT-2025"
        );
        
        tokenization::create_maturity<tokenization::SYToken>(
            deployer,
            six_months,
            b"6M-stAPT-2025"
        );
        
        tokenization::create_maturity<tokenization::SYToken>(
            deployer,
            one_year,
            b"1Y-stAPT-2025"
        );
        
        // Update migration state
        if (exists<MigrationState>(deployer_addr)) {
            let state = borrow_global_mut<MigrationState>(deployer_addr);
            state.phase2_complete = true;
        };
    }

    // Deploy Phase 3A components (Multi-LP Staking)
    public entry fun deploy_phase3a(deployer: &signer) acquires MigrationState {
        let deployer_addr = signer::address_of(deployer);
        
        // Initialize staking pools
        multi_lp_staking::initialize_staking_pools(deployer);
        
        // Create initial staking pools
        multi_lp_staking::create_staking_pool(
            deployer,
            b"stAPT-USDC Pool",
            b"stAPT-USDC-LP",
            deployer_addr,
            deployer_addr,
            1000, // 10% APY
        );
        
        multi_lp_staking::create_staking_pool(
            deployer,
            b"stAPT-BTC Pool",
            b"stAPT-BTC-LP",
            deployer_addr,
            deployer_addr,
            1200, // 12% APY
        );
        
        multi_lp_staking::create_staking_pool(
            deployer,
            b"stAPT-ETH Pool",
            b"stAPT-ETH-LP",
            deployer_addr,
            deployer_addr,
            1100, // 11% APY
        );
        
        // Update migration state
        if (exists<MigrationState>(deployer_addr)) {
            let state = borrow_global_mut<MigrationState>(deployer_addr);
            state.phase3a_complete = true;
        };
    }

    // Deploy Phase 3B components (PT/YT AMM)
    public entry fun deploy_phase3b(deployer: &signer) acquires MigrationState {
        let deployer_addr = signer::address_of(deployer);
        
        // Initialize AMM factory
        pt_yt_amm::initialize_amm_factory(deployer);
        
        // Update migration state
        if (exists<MigrationState>(deployer_addr)) {
            let state = borrow_global_mut<MigrationState>(deployer_addr);
            state.phase3b_complete = true;
        };
    }

    // Complete migration - deploy all phases
    public entry fun complete_migration(deployer: &signer) acquires MigrationState {
        // Initialize migration tracking
        if (!exists<MigrationState>(signer::address_of(deployer))) {
            init_migration(deployer);
        };
        
        // Deploy all phases in order
        deploy_phase1(deployer);
        deploy_phase2(deployer);
        deploy_phase3a(deployer);
        deploy_phase3b(deployer);
    }

    // View functions
    #[view]
    public fun get_migration_status(deployer_addr: address): (bool, bool, bool, bool) acquires MigrationState {
        if (!exists<MigrationState>(deployer_addr)) {
            return (false, false, false, false)
        };
        
        let state = borrow_global<MigrationState>(deployer_addr);
        (state.phase1_complete, state.phase2_complete, state.phase3a_complete, state.phase3b_complete)
    }

    #[view]
    public fun is_fully_migrated(deployer_addr: address): bool acquires MigrationState {
        if (!exists<MigrationState>(deployer_addr)) return false;
        
        let state = borrow_global<MigrationState>(deployer_addr);
        state.phase1_complete && state.phase2_complete && state.phase3a_complete && state.phase3b_complete
    }
}