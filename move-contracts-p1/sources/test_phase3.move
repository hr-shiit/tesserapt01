// Phase 3 Testing Script - Test Multi-LP Staking + PT/YT AMM
script {
    use yield_tokenization::multi_lp_staking;
    use yield_tokenization::pt_yt_amm;
    use yield_tokenization::oracles_and_mocks;
    use std::signer;
    use std::debug;
    use std::string;

    fun test_phase3(tester: &signer) {
        let tester_addr = signer::address_of(tester);
        
        debug::print(&string::utf8(b"=== Phase 3A: Multi-LP Staking Tests ==="));
        
        // Test 1: Initialize staking pools
        multi_lp_staking::initialize_staking_pools(tester);
        
        // Test 2: Create multiple staking pools
        multi_lp_staking::create_staking_pool(
            tester,
            b"stAPT-USDC Pool",
            b"stAPT-USDC-LP",
            tester_addr, // stAPT oracle
            tester_addr, // USDC oracle
            1000, // 10% base APY
        );
        
        multi_lp_staking::create_staking_pool(
            tester,
            b"stAPT-BTC Pool",
            b"stAPT-BTC-LP", 
            tester_addr,
            tester_addr,
            1200, // 12% base APY
        );
        
        multi_lp_staking::create_staking_pool(
            tester,
            b"stAPT-ETH Pool",
            b"stAPT-ETH-LP",
            tester_addr,
            tester_addr,
            1100, // 11% base APY
        );
        
        // Test 3: Check total pools created
        let total_pools = multi_lp_staking::get_total_pools(tester_addr);
        debug::print(&total_pools); // Should be 3
        
        // Test 4: Check best yield pool
        let best_pool = multi_lp_staking::get_best_yield_pool(tester_addr);
        debug::print(&best_pool); // Should be pool 1 (stAPT-BTC with 12% APY)
        
        // Test 5: Stake to specific pool
        multi_lp_staking::stake_to_pool(tester, tester_addr, 0, 5000000000); // 50 tokens to pool 0
        
        // Test 6: Check pool APY after staking
        let pool_apy = multi_lp_staking::get_pool_apy(tester_addr, 0);
        debug::print(&pool_apy);
        
        // Test 7: Stake to best yield pool automatically
        multi_lp_staking::stake_to_best_pool(tester, tester_addr, 3000000000); // 30 tokens
        
        // Test 8: Check user total staked
        let total_staked = multi_lp_staking::get_user_total_staked(tester_addr);
        debug::print(&total_staked); // Should be 80 tokens
        
        // Test 9: Get all pool APYs
        let all_apys = multi_lp_staking::get_all_pool_apys(tester_addr);
        debug::print(&all_apys);
        
        debug::print(&string::utf8(b"=== Phase 3B: PT/YT AMM Tests ==="));
        
        // Test 10: Initialize AMM factory
        pt_yt_amm::initialize_amm_factory(tester);
        
        // Test 11: Create PT/YT trading pool
        let six_months_maturity = 15552000; // 6 months from now
        pt_yt_amm::create_pt_yt_pool(
            tester,
            tester_addr,
            six_months_maturity,
            10000000000, // 100 PT tokens
            10000000000  // 100 YT tokens
        );
        
        // Test 12: Check pool info
        let (maturity, pt_reserve, yt_reserve, lp_supply, volume) = pt_yt_amm::get_pool_info(tester_addr, 0);
        debug::print(&maturity);
        debug::print(&pt_reserve);
        debug::print(&yt_reserve);
        debug::print(&lp_supply);
        debug::print(&volume);
        
        // Test 13: Check initial PT and YT prices
        let pt_price = pt_yt_amm::get_pt_price(tester_addr, 0);
        let yt_price = pt_yt_amm::get_yt_price(tester_addr, 0);
        debug::print(&pt_price);
        debug::print(&yt_price);
        
        // Test 14: Calculate implied APY
        let implied_apy = pt_yt_amm::calculate_implied_apy(tester_addr, 0);
        debug::print(&implied_apy);
        
        // Test 15: Swap PT for YT
        pt_yt_amm::swap_pt_for_yt(
            tester,
            tester_addr,
            0, // pool_id
            1000000000, // 10 PT tokens
            500000000   // min 5 YT tokens out
        );
        
        // Test 16: Check new prices after swap
        let new_pt_price = pt_yt_amm::get_pt_price(tester_addr, 0);
        let new_yt_price = pt_yt_amm::get_yt_price(tester_addr, 0);
        debug::print(&new_pt_price);
        debug::print(&new_yt_price);
        
        // Test 17: Check new reserves
        let (new_pt_reserve, new_yt_reserve) = pt_yt_amm::get_pool_reserves(tester_addr, 0);
        debug::print(&new_pt_reserve);
        debug::print(&new_yt_reserve);
        
        // Test 18: Add more liquidity
        pt_yt_amm::add_liquidity_pt_yt(
            tester,
            tester_addr,
            0, // pool_id
            2000000000, // 20 PT tokens
            2000000000  // 20 YT tokens
        );
        
        // Test 19: Check LP balance
        let lp_balance = pt_yt_amm::get_user_lp_balance(tester_addr, 0);
        debug::print(&lp_balance);
        
        // Test 20: Swap YT for PT
        pt_yt_amm::swap_yt_for_pt(
            tester,
            tester_addr,
            0, // pool_id
            500000000, // 5 YT tokens
            200000000  // min 2 PT tokens out
        );
        
        // Test 21: Check final prices
        let final_pt_price = pt_yt_amm::get_pt_price(tester_addr, 0);
        let final_yt_price = pt_yt_amm::get_yt_price(tester_addr, 0);
        debug::print(&final_pt_price);
        debug::print(&final_yt_price);
        
        // Test 22: Check final implied APY
        let final_implied_apy = pt_yt_amm::calculate_implied_apy(tester_addr, 0);
        debug::print(&final_implied_apy);
        
        // Test 23: Test oracle price functions
        let apt_price = oracles_and_mocks::get_real_apt_price_usd();
        let btc_price = oracles_and_mocks::get_btc_price_usd();
        let eth_price = oracles_and_mocks::get_eth_price_usd();
        let usdc_price = oracles_and_mocks::get_usdc_price_usd();
        debug::print(&apt_price);
        debug::print(&btc_price);
        debug::print(&eth_price);
        debug::print(&usdc_price);
        
        // Test 24: Test pool APY calculation
        let calculated_apy = oracles_and_mocks::calculate_pool_apy(
            1000, // 10% base APY
            10000000000, // 100 tokens liquidity
            1000000000,  // 10 tokens daily volume
            30           // 0.3% fee
        );
        debug::print(&calculated_apy);
        
        debug::print(&string::utf8(b"=== Phase 3 Tests Complete ==="));
    }
}