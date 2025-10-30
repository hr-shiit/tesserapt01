module yield_tokenization::token_contracts {
    use std::signer;
    use std::vector;
    use aptos_framework::timestamp;

    // Error codes
    const E_NOT_OWNER: u64 = 1;
    const E_NOT_MINTER: u64 = 2;
    const E_ZERO_AMOUNT: u64 = 3;
    const E_INSUFFICIENT_BALANCE: u64 = 4;
    const E_EXCEED_CAP: u64 = 5;

    // SY Token - Standardized Yield Token
    struct SYToken has key {
        owner: address,
        name: vector<u8>,
        symbol: vector<u8>,
        decimals: u8,
        total_supply: u64,
        underlying_asset: address,  // Address of underlying stAPT
        balances: vector<address>,
        amounts: vector<u64>,
    }

    // PT Token - Principal Token (enhanced)
    struct PTToken has key {
        owner: address,
        maturity: u64,
        underlying_sy: address,     // Address of underlying SY token
        total_supply: u64,
        balances: vector<address>,
        amounts: vector<u64>,
    }

    // YT Token - Yield Token (enhanced)
    struct YTToken has key {
        owner: address,
        maturity: u64,
        underlying_sy: address,     // Address of underlying SY token
        total_supply: u64,
        balances: vector<address>,
        amounts: vector<u64>,
    }

    // Configurable ERC20
    struct ConfigurableToken has key {
        owner: address,
        total_supply: u64,
        supply_cap: u64,
        mint_limit: u64,
        minters: vector<address>,
        balances: vector<address>,
        amounts: vector<u64>,
    }

    // Standardized Token Wrapper
    struct TokenWrapper has key {
        owner: address,
        underlying_tokens: vector<address>,
        ratios: vector<u64>, // Conversion ratios in basis points
        total_wrapped: u64,
        user_balances: vector<address>,
        wrapped_amounts: vector<u64>,
    }

    // USDC Yield Tokenization (Avalanche specific)
    struct USDCTokenization has key {
        owner: address,
        usdc_token: address,
        total_deposited: u64,
        pt_tokens: vector<u64>, // maturity timestamps
        yt_tokens: vector<u64>,
        user_positions: vector<address>,
        pt_balances: vector<vector<u64>>, // user -> maturity -> balance
        yt_balances: vector<vector<u64>>,
    }

    // Initialize SY Token
    public entry fun init_sy_token(
        owner: &signer,
        name: vector<u8>,
        symbol: vector<u8>,
        decimals: u8,
        underlying_asset: address
    ) {
        move_to(owner, SYToken {
            owner: signer::address_of(owner),
            name,
            symbol,
            decimals,
            total_supply: 0,
            underlying_asset,
            balances: vector::empty(),
            amounts: vector::empty(),
        });
    }

    // Initialize PT Token (enhanced)
    public entry fun init_pt_token(owner: &signer, maturity: u64, underlying_sy: address) {
        move_to(owner, PTToken {
            owner: signer::address_of(owner),
            maturity,
            underlying_sy,
            total_supply: 0,
            balances: vector::empty(),
            amounts: vector::empty(),
        });
    }

    // Initialize YT Token (enhanced)
    public entry fun init_yt_token(owner: &signer, maturity: u64, underlying_sy: address) {
        move_to(owner, YTToken {
            owner: signer::address_of(owner),
            maturity,
            underlying_sy,
            total_supply: 0,
            balances: vector::empty(),
            amounts: vector::empty(),
        });
    }

    // Initialize Configurable Token
    public entry fun init_configurable_token(
        owner: &signer,
        supply_cap: u64,
        mint_limit: u64
    ) {
        let owner_addr = signer::address_of(owner);
        let minters = vector::empty();
        vector::push_back(&mut minters, owner_addr);
        
        move_to(owner, ConfigurableToken {
            owner: owner_addr,
            total_supply: 0,
            supply_cap,
            mint_limit,
            minters,
            balances: vector::empty(),
            amounts: vector::empty(),
        });
    }

    // Initialize Token Wrapper
    public entry fun init_token_wrapper(owner: &signer) {
        move_to(owner, TokenWrapper {
            owner: signer::address_of(owner),
            underlying_tokens: vector::empty(),
            ratios: vector::empty(),
            total_wrapped: 0,
            user_balances: vector::empty(),
            wrapped_amounts: vector::empty(),
        });
    }

    // Initialize USDC Tokenization
    public entry fun init_usdc_tokenization(owner: &signer, usdc_token: address) {
        move_to(owner, USDCTokenization {
            owner: signer::address_of(owner),
            usdc_token,
            total_deposited: 0,
            pt_tokens: vector::empty(),
            yt_tokens: vector::empty(),
            user_positions: vector::empty(),
            pt_balances: vector::empty(),
            yt_balances: vector::empty(),
        });
    }

    // Mint SY tokens (owner only)
    public entry fun mint_sy(owner: &signer, to: address, amount: u64) acquires SYToken {
        let token = borrow_global_mut<SYToken>(signer::address_of(owner));
        assert!(signer::address_of(owner) == token.owner, E_NOT_OWNER);
        assert!(amount > 0, E_ZERO_AMOUNT);
        
        add_balance(&mut token.balances, &mut token.amounts, to, amount);
        token.total_supply = token.total_supply + amount;
    }

    // Mint PT tokens (owner only)
    public entry fun mint_pt(owner: &signer, to: address, amount: u64) acquires PTToken {
        let token = borrow_global_mut<PTToken>(signer::address_of(owner));
        assert!(signer::address_of(owner) == token.owner, E_NOT_OWNER);
        assert!(amount > 0, E_ZERO_AMOUNT);
        
        add_balance(&mut token.balances, &mut token.amounts, to, amount);
        token.total_supply = token.total_supply + amount;
    }

    // Mint YT tokens (owner only)
    public entry fun mint_yt(owner: &signer, to: address, amount: u64) acquires YTToken {
        let token = borrow_global_mut<YTToken>(signer::address_of(owner));
        assert!(signer::address_of(owner) == token.owner, E_NOT_OWNER);
        assert!(amount > 0, E_ZERO_AMOUNT);
        
        add_balance(&mut token.balances, &mut token.amounts, to, amount);
        token.total_supply = token.total_supply + amount;
    }

    // Mint configurable tokens (authorized minters only)
    public entry fun mint_configurable(
        minter: &signer,
        token_addr: address,
        to: address,
        amount: u64
    ) acquires ConfigurableToken {
        let token = borrow_global_mut<ConfigurableToken>(token_addr);
        let minter_addr = signer::address_of(minter);
        
        assert!(is_minter(&token.minters, minter_addr), E_NOT_MINTER);
        assert!(amount > 0, E_ZERO_AMOUNT);
        
        if (token.mint_limit > 0) {
            assert!(amount <= token.mint_limit, E_EXCEED_CAP);
        };
        if (token.supply_cap > 0) {
            assert!(token.total_supply + amount <= token.supply_cap, E_EXCEED_CAP);
        };
        
        add_balance(&mut token.balances, &mut token.amounts, to, amount);
        token.total_supply = token.total_supply + amount;
    }

    // Wrap tokens
    public entry fun wrap_tokens(
        user: &signer,
        wrapper_addr: address,
        amounts: vector<u64>
    ) acquires TokenWrapper {
        let wrapper = borrow_global_mut<TokenWrapper>(wrapper_addr);
        let user_addr = signer::address_of(user);
        
        let total_wrapped = 0;
        let i = 0;
        while (i < vector::length(&amounts)) {
            let amount = *vector::borrow(&amounts, i);
            let ratio = *vector::borrow(&wrapper.ratios, i);
            total_wrapped = total_wrapped + (amount * ratio) / 10000;
            i = i + 1;
        };
        
        add_balance(&mut wrapper.user_balances, &mut wrapper.wrapped_amounts, user_addr, total_wrapped);
        wrapper.total_wrapped = wrapper.total_wrapped + total_wrapped;
    }

    // USDC deposit and tokenization
    public entry fun deposit_usdc(
        user: &signer,
        tokenization_addr: address,
        amount: u64,
        maturity_idx: u64
    ) acquires USDCTokenization {
        let tokenization = borrow_global_mut<USDCTokenization>(tokenization_addr);
        let user_addr = signer::address_of(user);
        
        // Add user if not exists
        if (!has_user_position(&tokenization.user_positions, user_addr)) {
            vector::push_back(&mut tokenization.user_positions, user_addr);
            vector::push_back(&mut tokenization.pt_balances, vector::empty());
            vector::push_back(&mut tokenization.yt_balances, vector::empty());
        };
        
        // Update balances (simplified)
        tokenization.total_deposited = tokenization.total_deposited + amount;
    }

    // Helper functions
    fun add_balance(addresses: &mut vector<address>, amounts: &mut vector<u64>, user: address, amount: u64) {
        let (found, idx) = find_user_index(addresses, user);
        if (found) {
            let current = vector::borrow_mut(amounts, idx);
            *current = *current + amount;
        } else {
            vector::push_back(addresses, user);
            vector::push_back(amounts, amount);
        };
    }

    fun find_user_index(addresses: &vector<address>, user: address): (bool, u64) {
        let len = vector::length(addresses);
        let i = 0;
        while (i < len) {
            if (*vector::borrow(addresses, i) == user) {
                return (true, i)
            };
            i = i + 1;
        };
        (false, 0)
    }

    fun is_minter(minters: &vector<address>, addr: address): bool {
        let len = vector::length(minters);
        let i = 0;
        while (i < len) {
            if (*vector::borrow(minters, i) == addr) return true;
            i = i + 1;
        };
        false
    }

    fun has_user_position(users: &vector<address>, user: address): bool {
        let (found, _) = find_user_index(users, user);
        found
    }

    // View functions
    #[view]
    public fun get_sy_balance(token_addr: address, user: address): u64 acquires SYToken {
        let token = borrow_global<SYToken>(token_addr);
        let (found, idx) = find_user_index(&token.balances, user);
        if (found) *vector::borrow(&token.amounts, idx) else 0
    }

    #[view]
    public fun get_pt_balance(token_addr: address, user: address): u64 acquires PTToken {
        let token = borrow_global<PTToken>(token_addr);
        let (found, idx) = find_user_index(&token.balances, user);
        if (found) *vector::borrow(&token.amounts, idx) else 0
    }

    #[view]
    public fun get_yt_balance(token_addr: address, user: address): u64 acquires YTToken {
        let token = borrow_global<YTToken>(token_addr);
        let (found, idx) = find_user_index(&token.balances, user);
        if (found) *vector::borrow(&token.amounts, idx) else 0
    }

    #[view]
    public fun get_configurable_balance(token_addr: address, user: address): u64 acquires ConfigurableToken {
        let token = borrow_global<ConfigurableToken>(token_addr);
        let (found, idx) = find_user_index(&token.balances, user);
        if (found) *vector::borrow(&token.amounts, idx) else 0
    }

    #[view]
    public fun get_sy_info(token_addr: address): (vector<u8>, vector<u8>, u8, u64, address) acquires SYToken {
        let token = borrow_global<SYToken>(token_addr);
        (token.name, token.symbol, token.decimals, token.total_supply, token.underlying_asset)
    }

    #[view]
    public fun get_pt_info(token_addr: address): (u64, address, u64) acquires PTToken {
        let token = borrow_global<PTToken>(token_addr);
        (token.maturity, token.underlying_sy, token.total_supply)
    }

    #[view]
    public fun get_yt_info(token_addr: address): (u64, address, u64) acquires YTToken {
        let token = borrow_global<YTToken>(token_addr);
        (token.maturity, token.underlying_sy, token.total_supply)
    }
}