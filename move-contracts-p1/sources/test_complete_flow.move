// Complete Token Flow Test - APT → stAPT → SY → PT/YT → Trade
script {
    use yield_tokenization::oracles_and_mocks;
    use yield_tokenization::tokenization;
    use yield_tokenization::pt_yt_amm;
    use yield_tokenization::multi_lp_staking;
    use std::signer;
    use std::debug;
    use std::string;

    fun test_complete_flow(user: &signer) {
        let user_addr = signer::address_of(user);
        
        debug::print(&string::utf8(b"=== COMPLETE TOKEN FLOW TEST ==="));
        
        // STEP 1: APT to stAPT (Stake)
        debug::print(&string::utf8(b"Step 1: Stake APT to Get stAPT"));
        oracles_and_mocks::mint_stapt(user, user_addr, 10000000000); // 100 stAPT
        let stapt_balance = oracles_and_mocks::get_stapt_balance(user_addr, user_addr);
        debug::print(&stapt_balance); // Should be 100 stAPT
        
        // STEP 2: stAPT to SY-stAPT (Wrap)
        debug::print(&string::utf8(b"Step 2: Wrap stAPT to Get SY-stAPT"));
        tokenization::deposit_stapt_for_sy(user, user_addr, 10000000000); // 100 SY
        let sy_balance = tokenization::get_sy_balance(user_addr, user_addr);
        debug::print(&sy_balance); // Should be 100 SY
        
        // STEP 3: SY to PT + YT (Split)
        debug::print(&string::utf8(b"Step 3: Split SY to Get PT + YT"));
        tokenization::split<tokenization::SYToken>(user, user_addr, 5000000000, 1); // Split 50 SY (6M maturity)
        let pt_balance = tokenization::get_user_pt_balance<tokenization::SYToken>(user_addr, 1);
        let yt_balance = tokenization::get_user_yt_balance<tokenization::SYToken>(user_addr, 1);
        debug::print(&pt_balance); // Should be 50 PT
        debug::print(&yt_balance); // Should be 50 YT
        
        // STEP 4: Create PT/YT Pool
        debug::print(&string::utf8(b"Step 4: Create PT/YT Trading Pool"));
        let six_months = 15552000;
        pt_yt_amm::create_pt_yt_pool(user, user_addr, six_months, 2000000000, 2000000000); // 20 PT + 20 YT
        let (pt_reserve, yt_reserve) = pt_yt_amm::get_pool_reserves(user_addr, 0);
        debug::print(&pt_reserve); // Should be 20 PT
        debug::print(&yt_reserve); // Should be 20 YT
        
        // STEP 5: Trade PT for YT
        debug::print(&string::utf8(b"Step 5: Swap PT for YT"));
        pt_yt_amm::swap_pt_for_yt(user, user_addr, 0, 500000000, 200000000); // Swap 5 PT for YT
        let pt_price = pt_yt_amm::get_pt_price(user_addr, 0);
        let yt_price = pt_yt_amm::get_yt_price(user_addr, 0);
        debug::print(&pt_price);
        debug::print(&yt_price);
        
        // STEP 6: Stake in Multi-LP Pool
        debug::print(&string::utf8(b"Step 6: Stake SY in Best Yield Pool"));
        multi_lp_staking::stake_to_best_pool(user, user_addr, 2000000000); // Stake 20 SY
        let total_staked = multi_lp_staking::get_user_total_staked(user_addr);
        debug::print(&total_staked); // Should be 20
        
        // STEP 7: Check Best Pool
        debug::print(&string::utf8(b"Step 7: Check Best Yield Pool"));
        let best_pool = multi_lp_staking::get_best_yield_pool(user_addr);
        let pool_apy = multi_lp_staking::get_pool_apy(user_addr, best_pool);
        debug::print(&best_pool); // Should be pool 1 (stAPT-BTC, 12% APY)
        debug::print(&pool_apy);
        
        // STEP 8: Add Liquidity to PT/YT Pool
        debug::print(&string::utf8(b"Step 8: Add Liquidity to PT/YT Pool"));
        pt_yt_amm::add_liquidity_pt_yt(user, user_addr, 0, 1000000000, 1000000000); // Add 10 PT + 10 YT
        let lp_balance = pt_yt_amm::get_user_lp_balance(user_addr, 0);
        debug::print(&lp_balance);
        
        // STEP 9: Calculate Implied APY
        debug::print(&string::utf8(b"Step 9: Calculate Implied APY"));
        let implied_apy = pt_yt_amm::calculate_implied_apy(user_addr, 0);
        debug::print(&implied_apy);
        
        // STEP 10: Check Final Balances
        debug::print(&string::utf8(b"Step 10: Final Balances"));
        let final_sy = tokenization::get_sy_balance(user_addr, user_addr);
        let final_pt = tokenization::get_user_pt_balance<tokenization::SYToken>(user_addr, 1);
        let final_yt = tokenization::get_user_yt_balance<tokenization::SYToken>(user_addr, 1);
        debug::print(&final_sy);
        debug::print(&final_pt);
        debug::print(&final_yt);
        
        debug::print(&string::utf8(b"=== FLOW TEST COMPLETE ==="));
        debug::print(&string::utf8(b"All steps executed successfully!"));
    }
}