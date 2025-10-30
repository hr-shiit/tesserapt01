// Phase 2 Testing Script - Test stAPT → SY → PT/YT flow
script {
    use yield_tokenization::tokenization;
    use yield_tokenization::oracles_and_mocks;
    use yield_tokenization::token_contracts;
    use std::signer;
    use std::debug;
    use std::string;

    fun test_phase2(tester: &signer) {
        let tester_addr = signer::address_of(tester);
        
        // Test 1: Initialize SY wrapper for stAPT
        debug::print(&string::utf8(b"=== Test 1: Initialize SY Wrapper ==="));
        tokenization::initialize_sy_wrapper(
            tester, 
            tester_addr, // stAPT oracle address (same as our contract)
            b"Standardized Yield stAPT",
            b"SY-stAPT"
        );
        
        // Test 2: Check SY wrapper info
        let (name, symbol, decimals, total_supply) = tokenization::get_sy_info(tester_addr);
        debug::print(&name);
        debug::print(&symbol);
        debug::print(&decimals);
        debug::print(&total_supply);
        
        // Test 3: Deposit stAPT for SY tokens (simulate having 100 stAPT)
        debug::print(&string::utf8(b"=== Test 3: Deposit stAPT for SY ==="));
        tokenization::deposit_stapt_for_sy(tester, tester_addr, 10000000000); // 100 stAPT
        
        // Test 4: Check SY balance
        let sy_balance = tokenization::get_sy_balance(tester_addr, tester_addr);
        debug::print(&sy_balance); // Should be 100 SY tokens
        
        // Test 5: Initialize tokenization system
        debug::print(&string::utf8(b"=== Test 5: Initialize Tokenization ==="));
        tokenization::initialize<tokenization::SYToken>(tester, tester_addr);
        
        // Test 6: Create maturity (6 months from now)
        let six_months = 15552000; // 6 months in seconds
        tokenization::create_maturity<tokenization::SYToken>(
            tester, 
            six_months,
            b"6M-stAPT-2025"
        );
        
        // Test 7: Split SY tokens into PT and YT
        debug::print(&string::utf8(b"=== Test 7: Split SY into PT/YT ==="));
        tokenization::split<tokenization::SYToken>(
            tester,
            tester_addr,
            5000000000, // Split 50 SY tokens
            0 // First maturity
        );
        
        // Test 8: Check PT and YT balances
        let pt_balance = tokenization::get_user_pt_balance<tokenization::SYToken>(tester_addr, 0);
        let yt_balance = tokenization::get_user_yt_balance<tokenization::SYToken>(tester_addr, 0);
        debug::print(&pt_balance); // Should be 50 PT tokens
        debug::print(&yt_balance); // Should be 50 YT tokens
        
        // Test 9: Check remaining SY balance
        let remaining_sy = tokenization::get_sy_balance(tester_addr, tester_addr);
        debug::print(&remaining_sy); // Should be 50 SY tokens
        
        // Test 10: Check SY exchange rate
        let exchange_rate = tokenization::get_sy_exchange_rate(tester_addr);
        debug::print(&exchange_rate); // Should be 1.0 (100000000)
        
        // Test 11: Test conversion calculations
        let sy_to_stapt = tokenization::calculate_sy_to_stapt(tester_addr, 1000000000);
        let stapt_to_sy = tokenization::calculate_stapt_to_sy(tester_addr, 1000000000);
        debug::print(&sy_to_stapt); // Should be 1000000000 (1:1)
        debug::print(&stapt_to_sy); // Should be 1000000000 (1:1)
        
        // Test 12: Redeem some SY for stAPT
        debug::print(&string::utf8(b"=== Test 12: Redeem SY for stAPT ==="));
        tokenization::redeem_sy_for_stapt(tester, tester_addr, 2000000000); // Redeem 20 SY
        
        // Test 13: Check final SY balance
        let final_sy = tokenization::get_sy_balance(tester_addr, tester_addr);
        debug::print(&final_sy); // Should be 30 SY tokens
        
        // Test 14: Check SY reserves and total supply
        let reserves = tokenization::get_sy_stapt_reserves(tester_addr);
        let supply = tokenization::get_sy_total_supply(tester_addr);
        debug::print(&reserves); // Should be 80 stAPT
        debug::print(&supply);   // Should be 80 SY tokens
        
        debug::print(&string::utf8(b"=== Phase 2 Tests Complete ==="));
    }
}