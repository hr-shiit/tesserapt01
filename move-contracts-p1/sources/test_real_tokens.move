module yield_tokenization::test_real_tokens {
    use std::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::timestamp;
    use yield_tokenization::coin_types::{Self, StAPT, SYToken, PTToken, YTToken};
    use yield_tokenization::stapt_staking;
    use yield_tokenization::sy_wrapper;
    use yield_tokenization::pt_yt_tokenization;
    use yield_tokenization::pt_yt_amm_real;

    // Test the complete flow
    public entry fun test_complete_flow(user: &signer, deployer_addr: address) {
        let user_addr = signer::address_of(user);
        
        // Assume user has 100 APT
        let apt_amount = 100_00000000; // 100 APT with 8 decimals
        
        // Step 1: Stake APT for stAPT
        stapt_staking::stake_apt(user, deployer_addr, apt_amount);
        
        // Verify stAPT balance
        let stapt_balance = coin_types::get_stapt_balance(user_addr);
        assert!(stapt_balance > 0, 1);
        
        // Step 2: Wrap stAPT to SY
        let stapt_to_wrap = 50_00000000; // 50 stAPT
        sy_wrapper::deposit_stapt(user, deployer_addr, stapt_to_wrap);
        
        // Verify SY balance
        let sy_balance = coin_types::get_sy_balance(user_addr);
        assert!(sy_balance > 0, 2);
        
        // Step 3: Split SY into PT and YT
        let sy_to_split = 25_00000000; // 25 SY
        let current_time = timestamp::now_seconds();
        let six_months = current_time + (180 * 24 * 60 * 60);
        
        pt_yt_tokenization::split_sy(user, deployer_addr, sy_to_split, six_months);
        
        // Verify PT and YT balances
        let pt_balance = coin_types::get_pt_balance(user_addr);
        let yt_balance = coin_types::get_yt_balance(user_addr);
        assert!(pt_balance > 0, 3);
        assert!(yt_balance > 0, 4);
        
        // Step 4: Create AMM pool with PT and YT
        let pt_for_pool = 10_00000000; // 10 PT
        let yt_for_pool = 10_00000000; // 10 YT
        
        pt_yt_amm_real::create_pool(user, deployer_addr, six_months, pt_for_pool, yt_for_pool);
        
        // Step 5: Swap PT for YT
        let pt_to_swap = 1_00000000; // 1 PT
        pt_yt_amm_real::swap_pt_for_yt(user, deployer_addr, 0, pt_to_swap, 0);
        
        // Verify swap worked
        let new_yt_balance = coin_types::get_yt_balance(user_addr);
        assert!(new_yt_balance > yt_balance, 5);
    }

    // Test staking only
    public entry fun test_staking(user: &signer, deployer_addr: address) {
        let user_addr = signer::address_of(user);
        
        // Stake 10 APT
        let apt_amount = 10_00000000;
        stapt_staking::stake_apt(user, deployer_addr, apt_amount);
        
        // Check balance
        let stapt_balance = coin_types::get_stapt_balance(user_addr);
        assert!(stapt_balance > 0, 1);
        
        // Compound yield
        stapt_staking::compound_yield(deployer_addr);
        
        // Unstake 5 stAPT
        let stapt_to_unstake = 5_00000000;
        stapt_staking::unstake_apt(user, deployer_addr, stapt_to_unstake);
        
        // Verify balance decreased
        let new_balance = coin_types::get_stapt_balance(user_addr);
        assert!(new_balance < stapt_balance, 2);
    }

    // Test SY wrapping
    public entry fun test_sy_wrapper(user: &signer, deployer_addr: address) {
        let user_addr = signer::address_of(user);
        
        // First stake APT to get stAPT
        stapt_staking::stake_apt(user, deployer_addr, 20_00000000);
        
        // Wrap stAPT to SY
        let stapt_amount = 10_00000000;
        sy_wrapper::deposit_stapt(user, deployer_addr, stapt_amount);
        
        // Check SY balance
        let sy_balance = coin_types::get_sy_balance(user_addr);
        assert!(sy_balance > 0, 1);
        
        // Redeem SY back to stAPT
        let sy_to_redeem = 5_00000000;
        sy_wrapper::redeem_sy(user, deployer_addr, sy_to_redeem);
        
        // Verify SY balance decreased
        let new_sy_balance = coin_types::get_sy_balance(user_addr);
        assert!(new_sy_balance < sy_balance, 2);
    }

    // Test PT/YT splitting
    public entry fun test_pt_yt_split(user: &signer, deployer_addr: address) {
        let user_addr = signer::address_of(user);
        
        // Setup: Get SY tokens
        stapt_staking::stake_apt(user, deployer_addr, 30_00000000);
        sy_wrapper::deposit_stapt(user, deployer_addr, 20_00000000);
        
        // Split SY into PT and YT
        let sy_amount = 10_00000000;
        let current_time = timestamp::now_seconds();
        let maturity = current_time + (180 * 24 * 60 * 60);
        
        pt_yt_tokenization::split_sy(user, deployer_addr, sy_amount, maturity);
        
        // Verify PT and YT balances
        let pt_balance = coin_types::get_pt_balance(user_addr);
        let yt_balance = coin_types::get_yt_balance(user_addr);
        assert!(pt_balance == sy_amount, 1);
        assert!(yt_balance == sy_amount, 2);
        
        // Combine PT and YT back to SY
        let amount_to_combine = 5_00000000;
        pt_yt_tokenization::combine_pt_yt(user, deployer_addr, amount_to_combine, maturity);
        
        // Verify balances decreased
        let new_pt_balance = coin_types::get_pt_balance(user_addr);
        let new_yt_balance = coin_types::get_yt_balance(user_addr);
        assert!(new_pt_balance < pt_balance, 3);
        assert!(new_yt_balance < yt_balance, 4);
    }

    // Test AMM swaps
    public entry fun test_amm_swaps(user: &signer, deployer_addr: address) {
        let user_addr = signer::address_of(user);
        
        // Setup: Get PT and YT tokens
        stapt_staking::stake_apt(user, deployer_addr, 50_00000000);
        sy_wrapper::deposit_stapt(user, deployer_addr, 40_00000000);
        
        let current_time = timestamp::now_seconds();
        let maturity = current_time + (180 * 24 * 60 * 60);
        pt_yt_tokenization::split_sy(user, deployer_addr, 30_00000000, maturity);
        
        // Create pool
        pt_yt_amm_real::create_pool(user, deployer_addr, maturity, 10_00000000, 10_00000000);
        
        // Swap PT for YT
        let initial_yt = coin_types::get_yt_balance(user_addr);
        pt_yt_amm_real::swap_pt_for_yt(user, deployer_addr, 0, 1_00000000, 0);
        let new_yt = coin_types::get_yt_balance(user_addr);
        assert!(new_yt > initial_yt, 1);
        
        // Swap YT for PT
        let initial_pt = coin_types::get_pt_balance(user_addr);
        pt_yt_amm_real::swap_yt_for_pt(user, deployer_addr, 0, 1_00000000, 0);
        let new_pt = coin_types::get_pt_balance(user_addr);
        assert!(new_pt > initial_pt, 2);
    }
}
