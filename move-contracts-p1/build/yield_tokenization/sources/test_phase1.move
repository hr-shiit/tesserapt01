// Phase 1 Testing Script - Test stAPT functionality
script {
    use yield_tokenization::oracles_and_mocks;
    use std::signer;
    use std::debug;

    fun test_phase1(tester: &signer) {
        let tester_addr = signer::address_of(tester);
        
        // Test 1: Update APT price from Pyth (using real price ~$3.40)
        let real_apt_price = oracles_and_mocks::get_real_apt_price_usd();
        oracles_and_mocks::update_apt_price_from_pyth(tester, tester_addr, real_apt_price);
        
        // Test 2: Check current APT price
        let apt_price = oracles_and_mocks::get_current_apt_price(tester_addr);
        debug::print(&apt_price);
        
        // Test 3: Mint some stAPT tokens (simulate staking 100 APT)
        oracles_and_mocks::mint_stapt(tester, tester_addr, 10000000000); // 100 APT (8 decimals)
        
        // Test 4: Check stAPT balance
        let stapt_balance = oracles_and_mocks::get_stapt_balance(tester_addr, tester_addr);
        debug::print(&stapt_balance);
        
        // Test 5: Check exchange rate
        let exchange_rate = oracles_and_mocks::get_stapt_exchange_rate(tester_addr);
        debug::print(&exchange_rate);
        
        // Test 6: Compound yield (simulate time passing)
        oracles_and_mocks::compound_all_yield(tester, tester_addr);
        
        // Test 7: Check new exchange rate after compounding
        let new_exchange_rate = oracles_and_mocks::get_stapt_exchange_rate(tester_addr);
        debug::print(&new_exchange_rate);
        
        // Test 8: Calculate stAPT value in APT
        let apt_value = oracles_and_mocks::calculate_stapt_value_in_apt(tester_addr, stapt_balance);
        debug::print(&apt_value);
    }
}