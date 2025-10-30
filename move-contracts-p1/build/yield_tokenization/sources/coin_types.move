module yield_tokenization::coin_types {
    use std::signer;
    use std::string::{Self, String};
    use std::option;
    use aptos_framework::coin::{Self, Coin, BurnCapability, FreezeCapability, MintCapability};
    use aptos_framework::timestamp;

    // Error codes
    const E_NOT_ADMIN: u64 = 1;
    const E_ALREADY_INITIALIZED: u64 = 2;
    const E_NOT_INITIALIZED: u64 = 3;

    // Coin type markers
    struct StAPT {}
    struct SYToken {}
    struct PTToken {}
    struct YTToken {}
    struct MockUSDC {}

    // Capabilities storage
    struct StAPTCapabilities has key {
        mint_cap: MintCapability<StAPT>,
        burn_cap: BurnCapability<StAPT>,
        freeze_cap: FreezeCapability<StAPT>,
    }

    struct SYCapabilities has key {
        mint_cap: MintCapability<SYToken>,
        burn_cap: BurnCapability<SYToken>,
        freeze_cap: FreezeCapability<SYToken>,
    }

    struct PTCapabilities has key {
        mint_cap: MintCapability<PTToken>,
        burn_cap: BurnCapability<PTToken>,
        freeze_cap: FreezeCapability<PTToken>,
    }

    struct YTCapabilities has key {
        mint_cap: MintCapability<YTToken>,
        burn_cap: BurnCapability<YTToken>,
        freeze_cap: FreezeCapability<YTToken>,
    }

    struct MockUSDCCapabilities has key {
        mint_cap: MintCapability<MockUSDC>,
        burn_cap: BurnCapability<MockUSDC>,
        freeze_cap: FreezeCapability<MockUSDC>,
    }

    // Initialize stAPT coin
    public entry fun initialize_stapt(admin: &signer) {
        let (burn_cap, freeze_cap, mint_cap) = coin::initialize<StAPT>(
            admin,
            string::utf8(b"Staked APT"),
            string::utf8(b"stAPT"),
            8,
            true, // monitor_supply
        );

        move_to(admin, StAPTCapabilities {
            mint_cap,
            burn_cap,
            freeze_cap,
        });
    }

    // Initialize SY coin
    public entry fun initialize_sy(admin: &signer) {
        let (burn_cap, freeze_cap, mint_cap) = coin::initialize<SYToken>(
            admin,
            string::utf8(b"Standardized Yield stAPT"),
            string::utf8(b"SY-stAPT"),
            8,
            true,
        );

        move_to(admin, SYCapabilities {
            mint_cap,
            burn_cap,
            freeze_cap,
        });
    }

    // Initialize PT coin
    public entry fun initialize_pt(admin: &signer) {
        let (burn_cap, freeze_cap, mint_cap) = coin::initialize<PTToken>(
            admin,
            string::utf8(b"Principal Token"),
            string::utf8(b"PT-stAPT"),
            8,
            true,
        );

        move_to(admin, PTCapabilities {
            mint_cap,
            burn_cap,
            freeze_cap,
        });
    }

    // Initialize YT coin
    public entry fun initialize_yt(admin: &signer) {
        let (burn_cap, freeze_cap, mint_cap) = coin::initialize<YTToken>(
            admin,
            string::utf8(b"Yield Token"),
            string::utf8(b"YT-stAPT"),
            8,
            true,
        );

        move_to(admin, YTCapabilities {
            mint_cap,
            burn_cap,
            freeze_cap,
        });
    }

    // Initialize Mock USDC
    public entry fun initialize_mock_usdc(admin: &signer) {
        let (burn_cap, freeze_cap, mint_cap) = coin::initialize<MockUSDC>(
            admin,
            string::utf8(b"Mock USDC"),
            string::utf8(b"USDC"),
            6,
            true,
        );

        move_to(admin, MockUSDCCapabilities {
            mint_cap,
            burn_cap,
            freeze_cap,
        });
    }

    // Register user for stAPT
    public entry fun register_stapt(account: &signer) {
        coin::register<StAPT>(account);
    }

    // Register user for SY
    public entry fun register_sy(account: &signer) {
        coin::register<SYToken>(account);
    }

    // Register user for PT
    public entry fun register_pt(account: &signer) {
        coin::register<PTToken>(account);
    }

    // Register user for YT
    public entry fun register_yt(account: &signer) {
        coin::register<YTToken>(account);
    }

    // Register user for Mock USDC
    public entry fun register_mock_usdc(account: &signer) {
        coin::register<MockUSDC>(account);
    }

    // Mint stAPT (internal use)
    public fun mint_stapt(amount: u64, caps_addr: address): Coin<StAPT> acquires StAPTCapabilities {
        let caps = borrow_global<StAPTCapabilities>(caps_addr);
        coin::mint(amount, &caps.mint_cap)
    }

    // Mint SY (internal use)
    public fun mint_sy(amount: u64, caps_addr: address): Coin<SYToken> acquires SYCapabilities {
        let caps = borrow_global<SYCapabilities>(caps_addr);
        coin::mint(amount, &caps.mint_cap)
    }

    // Mint PT (internal use)
    public fun mint_pt(amount: u64, caps_addr: address): Coin<PTToken> acquires PTCapabilities {
        let caps = borrow_global<PTCapabilities>(caps_addr);
        coin::mint(amount, &caps.mint_cap)
    }

    // Mint YT (internal use)
    public fun mint_yt(amount: u64, caps_addr: address): Coin<YTToken> acquires YTCapabilities {
        let caps = borrow_global<YTCapabilities>(caps_addr);
        coin::mint(amount, &caps.mint_cap)
    }

    // Mint Mock USDC (for testing)
    public entry fun mint_mock_usdc_to(admin: &signer, to: address, amount: u64) acquires MockUSDCCapabilities {
        let caps = borrow_global<MockUSDCCapabilities>(signer::address_of(admin));
        let coins = coin::mint(amount, &caps.mint_cap);
        coin::deposit(to, coins);
    }

    // Burn stAPT
    public fun burn_stapt(coins: Coin<StAPT>, caps_addr: address) acquires StAPTCapabilities {
        let caps = borrow_global<StAPTCapabilities>(caps_addr);
        coin::burn(coins, &caps.burn_cap);
    }

    // Burn SY
    public fun burn_sy(coins: Coin<SYToken>, caps_addr: address) acquires SYCapabilities {
        let caps = borrow_global<SYCapabilities>(caps_addr);
        coin::burn(coins, &caps.burn_cap);
    }

    // Burn PT
    public fun burn_pt(coins: Coin<PTToken>, caps_addr: address) acquires PTCapabilities {
        let caps = borrow_global<PTCapabilities>(caps_addr);
        coin::burn(coins, &caps.burn_cap);
    }

    // Burn YT
    public fun burn_yt(coins: Coin<YTToken>, caps_addr: address) acquires YTCapabilities {
        let caps = borrow_global<YTCapabilities>(caps_addr);
        coin::burn(coins, &caps.burn_cap);
    }

    // View functions
    #[view]
    public fun get_stapt_balance(account: address): u64 {
        coin::balance<StAPT>(account)
    }

    #[view]
    public fun get_sy_balance(account: address): u64 {
        coin::balance<SYToken>(account)
    }

    #[view]
    public fun get_pt_balance(account: address): u64 {
        coin::balance<PTToken>(account)
    }

    #[view]
    public fun get_yt_balance(account: address): u64 {
        coin::balance<YTToken>(account)
    }

    #[view]
    public fun get_mock_usdc_balance(account: address): u64 {
        coin::balance<MockUSDC>(account)
    }
}
