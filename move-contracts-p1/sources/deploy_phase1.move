// Phase 1 & 2 Deployment Script - Oracle Integration + SY Wrapper
script {
    use yield_tokenization::oracles_and_mocks;
    use yield_tokenization::tokenization;
    use yield_tokenization::token_contracts;
    use std::signer;

    fun main(deployer: &signer) {
        let deployer_addr = signer::address_of(deployer);
        
        // Phase 1: Initialize oracles and stAPT
        oracles_and_mocks::init_pyth_oracle(deployer);
        oracles_and_mocks::init_stapt_token(deployer);
        oracles_and_mocks::init_production_oracle(deployer);
        oracles_and_mocks::init_mock_oracle(deployer);
        oracles_and_mocks::init_mock_usdc(deployer);
        
        // Phase 2: Initialize SY wrapper and tokenization
        tokenization::initialize_sy_wrapper(
            deployer,
            deployer_addr, // stAPT oracle address
            b"Standardized Yield stAPT",
            b"SY-stAPT"
        );
        
        // Initialize tokenization system
        tokenization::initialize<tokenization::SYToken>(deployer, deployer_addr);
        
        // Create initial maturity options
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
    }
}