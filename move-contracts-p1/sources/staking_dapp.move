module yield_tokenization::staking_dapp {
    use std::signer;
    use aptos_framework::timestamp;

    // Error codes
    const E_NOT_OWNER: u64 = 1;
    const E_ZERO_AMOUNT: u64 = 2;
    const E_INSUFFICIENT_STAKE: u64 = 3;
    const E_NO_REWARDS: u64 = 4;

    // Staking pool configuration
    struct StakingPool<phantom StakeToken, phantom RewardToken> has key {
        owner: address,
        total_staked: u64,
        reward_rate: u64, // Rewards per second per token staked
    }

    // User stake information
    struct UserStake<phantom StakeToken, phantom RewardToken> has key {
        amount: u64,
        last_reward_time: u64,
        pending_rewards: u64,
    }

    // Initialize staking pool
    public entry fun initialize<StakeToken, RewardToken>(
        owner: &signer,
        reward_rate: u64
    ) {
        let owner_addr = signer::address_of(owner);
        move_to(owner, StakingPool<StakeToken, RewardToken> {
            owner: owner_addr,
            total_staked: 0,
            reward_rate,
        });
    }

    // Stake tokens
    public entry fun stake<StakeToken, RewardToken>(
        user: &signer,
        pool_addr: address,
        amount: u64
    ) acquires StakingPool, UserStake {
        assert!(amount > 0, E_ZERO_AMOUNT);
        
        let user_addr = signer::address_of(user);
        let pool = borrow_global_mut<StakingPool<StakeToken, RewardToken>>(pool_addr);
        
        // Update user stake
        if (!exists<UserStake<StakeToken, RewardToken>>(user_addr)) {
            move_to(user, UserStake<StakeToken, RewardToken> {
                amount,
                last_reward_time: timestamp::now_seconds(),
                pending_rewards: 0,
            });
        } else {
            let user_stake = borrow_global_mut<UserStake<StakeToken, RewardToken>>(user_addr);
            
            // Calculate and add pending rewards
            let pending = calculate_rewards(user_stake.amount, user_stake.last_reward_time, pool.reward_rate);
            user_stake.pending_rewards = user_stake.pending_rewards + pending;
            user_stake.amount = user_stake.amount + amount;
            user_stake.last_reward_time = timestamp::now_seconds();
        };
        
        pool.total_staked = pool.total_staked + amount;
    }

    // Unstake tokens
    public entry fun unstake<StakeToken, RewardToken>(
        user: &signer,
        pool_addr: address,
        amount: u64
    ) acquires StakingPool, UserStake {
        assert!(amount > 0, E_ZERO_AMOUNT);
        
        let user_addr = signer::address_of(user);
        let pool = borrow_global_mut<StakingPool<StakeToken, RewardToken>>(pool_addr);
        let user_stake = borrow_global_mut<UserStake<StakeToken, RewardToken>>(user_addr);
        
        assert!(user_stake.amount >= amount, E_INSUFFICIENT_STAKE);
        
        // Calculate and add pending rewards
        let pending = calculate_rewards(user_stake.amount, user_stake.last_reward_time, pool.reward_rate);
        user_stake.pending_rewards = user_stake.pending_rewards + pending;
        user_stake.amount = user_stake.amount - amount;
        user_stake.last_reward_time = timestamp::now_seconds();
        
        pool.total_staked = pool.total_staked - amount;
    }

    // Claim accumulated rewards
    public entry fun claim_rewards<StakeToken, RewardToken>(
        user: &signer,
        pool_addr: address
    ) acquires StakingPool, UserStake {
        let user_addr = signer::address_of(user);
        let pool = borrow_global<StakingPool<StakeToken, RewardToken>>(pool_addr);
        let user_stake = borrow_global_mut<UserStake<StakeToken, RewardToken>>(user_addr);
        
        // Calculate total rewards
        let pending = calculate_rewards(user_stake.amount, user_stake.last_reward_time, pool.reward_rate);
        let total_rewards = user_stake.pending_rewards + pending;
        
        assert!(total_rewards > 0, E_NO_REWARDS);
        
        // Reset rewards and update time
        user_stake.pending_rewards = 0;
        user_stake.last_reward_time = timestamp::now_seconds();
        
        // In real implementation, would mint/transfer reward tokens
    }

    // Calculate pending rewards for a user
    fun calculate_rewards(staked_amount: u64, last_reward_time: u64, reward_rate: u64): u64 {
        if (staked_amount == 0) return 0;
        
        let time_passed = timestamp::now_seconds() - last_reward_time;
        (staked_amount * reward_rate * time_passed) / 1000000 // Scale down
    }

    // Get user's staked amount
    #[view]
    public fun get_staked_amount<StakeToken, RewardToken>(user_addr: address): u64 acquires UserStake {
        if (!exists<UserStake<StakeToken, RewardToken>>(user_addr)) return 0;
        borrow_global<UserStake<StakeToken, RewardToken>>(user_addr).amount
    }

    // Get user's total rewards (pending + accumulated)
    #[view]
    public fun get_total_rewards<StakeToken, RewardToken>(
        user_addr: address,
        pool_addr: address
    ): u64 acquires StakingPool, UserStake {
        if (!exists<UserStake<StakeToken, RewardToken>>(user_addr)) return 0;
        
        let pool = borrow_global<StakingPool<StakeToken, RewardToken>>(pool_addr);
        let user_stake = borrow_global<UserStake<StakeToken, RewardToken>>(user_addr);
        
        let pending = calculate_rewards(user_stake.amount, user_stake.last_reward_time, pool.reward_rate);
        user_stake.pending_rewards + pending
    }

    // Get pool total staked
    #[view]
    public fun get_total_staked<StakeToken, RewardToken>(pool_addr: address): u64 acquires StakingPool {
        borrow_global<StakingPool<StakeToken, RewardToken>>(pool_addr).total_staked
    }
}