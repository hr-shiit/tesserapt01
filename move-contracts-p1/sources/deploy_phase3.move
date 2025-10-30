// Phase 3 Deployment Script - Backwards Compatible Deployment
script {
    use yield_tokenization::oracles_and_mocks;
    use yield_tokenization::tokenization;
    use yield_tokenization::multi_lp_staking;
    use yield_tokenization::pt_yt_amm;
    use std::signer;

    fun deploy_phase3(deployer: &signer) {
        let deployer_addr = signer::address_of(deployer);
        
        // Phase 3A: Initialize Multi-LP Staking System
        multi_lp_staking::initialize_staking_pools(deployer);
        
        // Create multiple staking pool options
        multi_lp_staking::create_staking_pool(
            deployer,
            b"stAPT-USDC Pool",
            b"stAPT-USDC-LP",
            deployer_addr, // stAPT oracle
            deployer_addr, // USDC oracle (mock)
            1000, // 10% base APY in basis points
        );
        
        multi_lp_staking::create_staking_pool(
            deployer,
            b"stAPT-BTC Pool", 
            b"stAPT-BTC-LP",
            deployer_addr, // stAPT oracle
            deployer_addr, // BTC oracle (mock)
            1200, // 12% base APY in basis points
        );
        
        multi_lp_staking::create_staking_pool(
            deployer,
            b"stAPT-ETH Pool",
            b"stAPT-ETH-LP", 
            deployer_addr, // stAPT oracle
            deployer_addr, // ETH oracle (mock)
            1100, // 11% base APY in basis points
        );
        
        // Phase 3B: Initialize PT/YT AMM
        pt_yt_amm::initialize_amm_factory(deployer);
        
        // Create initial PT/YT trading pairs
        // These will be created dynamically as users split tokens
    }
}