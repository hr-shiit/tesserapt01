// COMPLETE DEPLOYMENT - All Phases 1, 2, 3 Together
script {
    use yield_tokenization::oracles_and_mocks;
    use yield_tokenization::tokenization;
    use yield_tokenization::multi_lp_staking;
    use yield_tokenization::pt_yt_amm;
    use std::signer;

    fun complete_deployment(deployer: &signer) {
        let deployer_addr = signer::address_of(deployer);
        
        // ========== PHASE 1: Oracle Integration ==========
        // Initialize Pyth Oracle for APT price feeds
        oracles_and_mocks::init_pyth_oracle(deployer);
        
        // Initialize stAPT token with 9.5% APY
        oracles_and_mocks::init_stapt_token(deployer);
        
        // Initialize production oracle
        oracles_and_mocks::init_production_oracle(deployer);
        
        // Initialize mock oracle for testing
        oracles_and_mocks::init_mock_oracle(deployer);
        
        // Initialize mock USDC for testing
        oracles_and_mocks::init_mock_usdc(deployer);
        
        // ========== PHASE 2: SY Wrapper & Tokenization ==========
        // Initialize SY wrapper for stAPT
        tokenization::initialize_sy_wrapper(
            deployer,
            deployer_addr, // stAPT oracle address
            b"Standardized Yield stAPT",
            b"SY-stAPT"
        );
        
        // Initialize tokenization system
        tokenization::initialize<tokenization::SYToken>(deployer, deployer_addr);
        
        // Create maturity options
        let three_months = 7776000;  // 3 months in seconds
        let six_months = 15552000;   // 6 months in seconds
        let one_year = 31536000;     // 1 year in seconds
        
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
        
        // ========== PHASE 3A: Multi-LP Staking ==========
        // Initialize staking pools system
        multi_lp_staking::initialize_staking_pools(deployer);
        
        // Create stAPT-USDC Pool (10% APY)
        multi_lp_staking::create_staking_pool(
            deployer,
            b"stAPT-USDC Pool",
            b"stAPT-USDC-LP",
            deployer_addr, // stAPT oracle
            deployer_addr, // USDC oracle
            1000, // 10% base APY in basis points
        );
        
        // Create stAPT-BTC Pool (12% APY)
        multi_lp_staking::create_staking_pool(
            deployer,
            b"stAPT-BTC Pool", 
            b"stAPT-BTC-LP",
            deployer_addr, // stAPT oracle
            deployer_addr, // BTC oracle
            1200, // 12% base APY in basis points
        );
        
        // Create stAPT-ETH Pool (11% APY)
        multi_lp_staking::create_staking_pool(
            deployer,
            b"stAPT-ETH Pool",
            b"stAPT-ETH-LP", 
            deployer_addr, // stAPT oracle
            deployer_addr, // ETH oracle
            1100, // 11% base APY in basis points
        );
        
        // ========== PHASE 3B: PT/YT AMM ==========
        // Initialize AMM factory for PT/YT trading
        pt_yt_amm::initialize_amm_factory(deployer);
        
        // All phases deployed successfully!
    }
}