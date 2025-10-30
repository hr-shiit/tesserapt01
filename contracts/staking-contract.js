// TESSERAPT Staking Contract Interface
// Handles APT staking and stAPT token operations

class TesseraptStakingContract {
    constructor(aptosClient, walletManager) {
        this.client = aptosClient;
        this.wallet = walletManager;
        this.contractAddr = aptosClient.config.contractAddress;
        
        // Contract module names from move-contracts-p1
        this.modules = {
            oracles: 'oracles_and_mocks',
            staking: 'stapt_staking'
        };
        
        console.log('🏦 Staking Contract initialized');
        console.log('📍 Contract Address:', this.contractAddr);
    }

    // ==========================================
    // STAKING OPERATIONS
    // ==========================================

    async stakeAPT(amount) {
        console.log(`🔄 Staking ${amount} APT...`);
        
        if (!this.wallet.isConnected()) {
            throw new Error('Wallet not connected');
        }
        
        if (amount <= 0) {
            throw new Error('Amount must be greater than 0');
        }
        
        try {
            // Convert APT to Octas (8 decimals)
            const amountInOctas = this.client.aptToOctas(amount);
            console.log(`💰 Amount in Octas: ${amountInOctas}`);
            
            // Build transaction for minting stAPT
            const transaction = this.client.buildTransaction(
                `${this.modules.oracles}::mint_stapt`,
                [],
                [this.contractAddr, amountInOctas.toString()]
            );
            
            console.log('📝 Built staking transaction:', transaction);
            
            // Simulate transaction first (optional - skip if not available)
            try {
                console.log('🧪 Simulating transaction...');
                const simulation = await this.wallet.simulateTransaction(transaction);
                console.log('✅ Simulation successful:', simulation);
            } catch (simError) {
                console.warn('⚠️ Simulation skipped (not critical):', simError.message);
            }
            
            // Execute transaction
            console.log('🚀 Executing staking transaction...');
            const result = await this.wallet.signAndSubmitTransaction(transaction);
            
            console.log('✅ Staking transaction completed:', result);
            
            return {
                success: true,
                txHash: result.hash,
                amount: amount,
                explorerUrl: this.client.getExplorerUrl(result.hash)
            };
            
        } catch (error) {
            console.error('❌ Staking failed:', error);
            throw new Error(`Staking failed: ${error.message}`);
        }
    }

    async unstakeAPT(amount) {
        console.log(`🔄 Unstaking ${amount} stAPT...`);
        
        if (!this.wallet.isConnected()) {
            throw new Error('Wallet not connected');
        }
        
        if (amount <= 0) {
            throw new Error('Amount must be greater than 0');
        }
        
        try {
            const amountInOctas = this.client.aptToOctas(amount);
            
            // Build transaction for burning stAPT
            const transaction = this.client.buildTransaction(
                `${this.modules.oracles}::burn_stapt`,
                [],
                [this.contractAddr, amountInOctas.toString()]
            );
            
            console.log('📝 Built unstaking transaction:', transaction);
            
            // Execute transaction
            const result = await this.wallet.signAndSubmitTransaction(transaction);
            
            console.log('✅ Unstaking transaction completed:', result);
            
            return {
                success: true,
                txHash: result.hash,
                amount: amount,
                explorerUrl: this.client.getExplorerUrl(result.hash)
            };
            
        } catch (error) {
            console.error('❌ Unstaking failed:', error);
            throw new Error(`Unstaking failed: ${error.message}`);
        }
    }

    // ==========================================
    // BALANCE QUERIES
    // ==========================================

    async getStAPTBalance(userAddress) {
        console.log(`📊 Getting stAPT balance for ${this.client.formatAddress(userAddress)}`);
        
        try {
            const result = await this.client.view(
                `${this.modules.oracles}::get_stapt_balance`,
                [],
                [this.contractAddr, userAddress]
            );
            
            const balance = this.client.octasToApt(result[0]);
            console.log(`💰 stAPT Balance: ${balance}`);
            
            return balance;
        } catch (error) {
            console.error('❌ Failed to get stAPT balance:', error);
            return 0;
        }
    }

    async getAPTBalance(userAddress) {
        console.log(`📊 Getting APT balance for ${this.client.formatAddress(userAddress)}`);
        
        try {
            const balance = await this.client.getAccountBalance(userAddress);
            console.log(`💰 APT Balance: ${balance}`);
            return balance;
        } catch (error) {
            console.error('❌ Failed to get APT balance:', error);
            return 0;
        }
    }

    // ==========================================
    // STAKING INFORMATION
    // ==========================================

    async getExchangeRate() {
        console.log('📊 Getting stAPT exchange rate...');
        
        try {
            const result = await this.client.view(
                `${this.modules.oracles}::get_stapt_exchange_rate`,
                [],
                [this.contractAddr]
            );
            
            const rate = this.client.octasToApt(result[0]);
            console.log(`📈 Exchange Rate: 1 stAPT = ${rate} APT`);
            
            return rate;
        } catch (error) {
            console.error('❌ Failed to get exchange rate:', error);
            return 1.0; // Default 1:1 ratio
        }
    }

    async getCurrentAPY() {
        console.log('📊 Getting current APY...');
        
        try {
            // From the contract documentation, stAPT has 9.5% APY
            const apy = 9.5;
            console.log(`📈 Current APY: ${apy}%`);
            return apy;
        } catch (error) {
            console.error('❌ Failed to get APY:', error);
            return 9.5; // Default APY
        }
    }

    async getTotalStaked() {
        console.log('📊 Getting total staked amount...');
        
        try {
            const result = await this.client.view(
                `${this.modules.oracles}::get_total_stapt_supply`,
                [],
                [this.contractAddr]
            );
            
            const totalStaked = this.client.octasToApt(result[0]);
            console.log(`💰 Total Staked: ${totalStaked} APT`);
            
            return totalStaked;
        } catch (error) {
            console.error('❌ Failed to get total staked:', error);
            return 0;
        }
    }

    // ==========================================
    // UTILITY METHODS
    // ==========================================

    async getStakingStats(userAddress) {
        console.log('📊 Getting comprehensive staking stats...');
        
        try {
            const [aptBalance, staptBalance, exchangeRate, apy, totalStaked] = await Promise.all([
                this.getAPTBalance(userAddress),
                this.getStAPTBalance(userAddress),
                this.getExchangeRate(),
                this.getCurrentAPY(),
                this.getTotalStaked()
            ]);
            
            const staptValue = staptBalance * exchangeRate;
            
            const stats = {
                user: {
                    aptBalance,
                    staptBalance,
                    staptValue,
                    address: userAddress
                },
                protocol: {
                    exchangeRate,
                    apy,
                    totalStaked
                },
                timestamp: Date.now()
            };
            
            console.log('📊 Staking Stats:', stats);
            return stats;
            
        } catch (error) {
            console.error('❌ Failed to get staking stats:', error);
            throw error;
        }
    }

    // ==========================================
    // VALIDATION METHODS
    // ==========================================

    async validateStakeAmount(amount, userAddress) {
        try {
            const aptBalance = await this.getAPTBalance(userAddress);
            
            if (amount > aptBalance) {
                throw new Error(`Insufficient APT balance. Available: ${aptBalance}, Required: ${amount}`);
            }
            
            if (amount < 0.01) {
                throw new Error('Minimum stake amount is 0.01 APT');
            }
            
            return true;
        } catch (error) {
            console.error('❌ Stake amount validation failed:', error);
            throw error;
        }
    }

    async validateUnstakeAmount(amount, userAddress) {
        try {
            const staptBalance = await this.getStAPTBalance(userAddress);
            
            if (amount > staptBalance) {
                throw new Error(`Insufficient stAPT balance. Available: ${staptBalance}, Required: ${amount}`);
            }
            
            if (amount < 0.01) {
                throw new Error('Minimum unstake amount is 0.01 stAPT');
            }
            
            return true;
        } catch (error) {
            console.error('❌ Unstake amount validation failed:', error);
            throw error;
        }
    }

    // ==========================================
    // DEBUG METHODS
    // ==========================================

    debugInfo() {
        console.log('🔍 Staking Contract Debug Info:');
        console.log('Contract Address:', this.contractAddr);
        console.log('Modules:', this.modules);
        console.log('Wallet Connected:', this.wallet.isConnected());
        console.log('Client Initialized:', this.client.isInitialized);
        
        return {
            contractAddress: this.contractAddr,
            modules: this.modules,
            walletConnected: this.wallet.isConnected(),
            clientInitialized: this.client.isInitialized
        };
    }
}

// Export for module usage
if (typeof module !== 'undefined' && module.exports) {
    module.exports = TesseraptStakingContract;
}
