module yield_tokenization::deploy_real_tokens {
    use std::signer;
    use aptos_framework::timestamp;
    use yield_tokenization::coin_types;
    use yield_tokenization::stapt_staking;
    use yield_tokenization::sy_wrapper;
    use yield_tokenization::pt_yt_tokenization;
    use yield_tokenization::pt_yt_amm_real;

    // Deploy all real token contracts
    public entry fun deploy_all(deployer: &signer) {
        let deployer_addr = signer::address_of(deployer);
        
        // Step 1: Initialize all coin types
        coin_types::initialize_stapt(deployer);
        coin_types::initialize_sy(deployer);
        coin_types::initialize_pt(deployer);
        coin_types::initialize_yt(deployer);
        coin_types::initialize_mock_usdc(deployer);
        
        // Step 2: Register deployer for all coins
        coin_types::register_stapt(deployer);
        coin_types::register_sy(deployer);
        coin_types::register_pt(deployer);
        coin_types::register_yt(deployer);
        coin_types::register_mock_usdc(deployer);
        
        // Step 3: Initialize stAPT staking treasury
        stapt_staking::initialize(deployer, deployer_addr);
        
        // Step 4: Initialize SY wrapper
        sy_wrapper::initialize(deployer, deployer_addr);
        
        // Step 5: Initialize PT/YT tokenization
        pt_yt_tokenization::initialize(deployer, deployer_addr);
        
        // Step 6: Create maturities (3M, 6M, 1Y)
        let current_time = timestamp::now_seconds();
        let three_months = current_time + (90 * 24 * 60 * 60);
        let six_months = current_time + (180 * 24 * 60 * 60);
        let one_year = current_time + (365 * 24 * 60 * 60);
        
        pt_yt_tokenization::create_maturity(deployer, three_months, b"3M Maturity");
        pt_yt_tokenization::create_maturity(deployer, six_months, b"6M Maturity");
        pt_yt_tokenization::create_maturity(deployer, one_year, b"1Y Maturity");
        
        // Step 7: Initialize AMM factory
        pt_yt_amm_real::initialize(deployer);
    }

    // Quick setup for testing
    public entry fun quick_setup_for_testing(user: &signer) {
        // Register user for all coins
        coin_types::register_stapt(user);
        coin_types::register_sy(user);
        coin_types::register_pt(user);
        coin_types::register_yt(user);
        coin_types::register_mock_usdc(user);
    }
}
