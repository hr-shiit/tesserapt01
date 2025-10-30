// TESSERAPT AMM Contract Interface
// Handles PT/YT token swaps using simple_amm.move

class TesseraptAMMContract {
    constructor(aptosClient, walletManager) {
        this.client = aptosClient;
        this.wallet = walletManager;
        this.contractAddr = aptosClient.config.contractAddress;
        
        // Contract module name
        this.module = 'simple_amm';
        
        console.log('💱 AMM Contract initialized');
        console.log('📍 Contract Address:', this.contractAddr);
    }

    // ==========================================
    // SWAP OPERATIONS
    // ==========================================

    async swapPTForAPT(amount) {
        console.log(`🔄 Swapping ${amount} PT for APT...`);
        
        if (!this.wallet.isConnected()) {
            throw new Error('Wallet not connected');
        }
        
        if (amount <= 0) {
            throw new Error('Amount must be greater than 0');
        }
        
        try {
            // Convert to Octas
            const amountInOctas = this.client.aptToOctas(amount);
            console.log(`💰 Amount in Octas: ${amountInOctas}`);
            
            // Build swap transaction
            // swap_a_for_b where A = PTToken, B = AptosCoin
            const transaction = this.client.buildTransaction(
                `${this.module}::swap_a_for_b`,
                [
                    `${this.contractAddr}::coin_types::PTToken`,
                    '0x1::aptos_coin::AptosCoin'
                ],
                [this.contractAddr, amountInOctas.toString()]
            );
            
            console.log('📝 Built swap transaction:', transaction);
            
            // Execute transaction
            console.log('🚀 Executing swap transaction...');
            const result = await this.wallet.signAndSubmitTransaction(transaction);
            
            console.log('✅ Swap transaction completed:', result);
            
            return {
                success: true,
                txHash: result.hash,
                sellToken: 'PT',
                sellAmount: amount,
                receiveToken: 'APT',
                explorerUrl: this.client.getExplorerUrl(result.hash)
            };
            
        } catch (error) {
            console.error('❌ PT → APT swap failed:', error);
            throw new Error(`Swap failed: ${error.message}`);
        }
    }

    async swapYTForAPT(amount) {
        console.log(`🔄 Swapping ${amount} YT for APT...`);
        
        if (!this.wallet.isConnected()) {
            throw new Error('Wallet not connected');
        }
        
        if (amount <= 0) {
            throw new Error('Amount must be greater than 0');
        }
        
        try {
            // Convert to Octas
            const amountInOctas = this.client.aptToOctas(amount);
            console.log(`💰 Amount in Octas: ${amountInOctas}`);
            
            // Build swap transaction
            // swap_a_for_b where A = YTToken, B = AptosCoin
            const transaction = this.client.buildTransaction(
                `${this.module}::swap_a_for_b`,
                [
                    `${this.contractAddr}::coin_types::YTToken`,
                    '0x1::aptos_coin::AptosCoin'
                ],
                [this.contractAddr, amountInOctas.toString()]
            );
            
            console.log('📝 Built swap transaction:', transaction);
            
            // Execute transaction
            console.log('🚀 Executing swap transaction...');
            const result = await this.wallet.signAndSubmitTransaction(transaction);
            
            console.log('✅ Swap transaction completed:', result);
            
            return {
                success: true,
                txHash: result.hash,
                sellToken: 'YT',
                sellAmount: amount,
                receiveToken: 'APT',
                explorerUrl: this.client.getExplorerUrl(result.hash)
            };
            
        } catch (error) {
            console.error('❌ YT → APT swap failed:', error);
            throw new Error(`Swap failed: ${error.message}`);
        }
    }

    async swapAPTForPT(amount) {
        console.log(`🔄 Swapping ${amount} APT for PT...`);
        
        if (!this.wallet.isConnected()) {
            throw new Error('Wallet not connected');
        }
        
        if (amount <= 0) {
            throw new Error('Amount must be greater than 0');
        }
        
        try {
            // Convert to Octas
            const amountInOctas = this.client.aptToOctas(amount);
            
            // Build swap transaction
            // swap_b_for_a where A = PTToken, B = AptosCoin
            const transaction = this.client.buildTransaction(
                `${this.module}::swap_b_for_a`,
                [
                    `${this.contractAddr}::coin_types::PTToken`,
                    '0x1::aptos_coin::AptosCoin'
                ],
                [this.contractAddr, amountInOctas.toString()]
            );
            
            console.log('📝 Built swap transaction:', transaction);
            
            // Execute transaction
            const result = await this.wallet.signAndSubmitTransaction(transaction);
            
            console.log('✅ Swap transaction completed:', result);
            
            return {
                success: true,
                txHash: result.hash,
                sellToken: 'APT',
                sellAmount: amount,
                receiveToken: 'PT',
                explorerUrl: this.client.getExplorerUrl(result.hash)
            };
            
        } catch (error) {
            console.error('❌ APT → PT swap failed:', error);
            throw new Error(`Swap failed: ${error.message}`);
        }
    }

    async swapAPTForYT(amount) {
        console.log(`🔄 Swapping ${amount} APT for YT...`);
        
        if (!this.wallet.isConnected()) {
            throw new Error('Wallet not connected');
        }
        
        if (amount <= 0) {
            throw new Error('Amount must be greater than 0');
        }
        
        try {
            // Convert to Octas
            const amountInOctas = this.client.aptToOctas(amount);
            
            // Build swap transaction
            // swap_b_for_a where A = YTToken, B = AptosCoin
            const transaction = this.client.buildTransaction(
                `${this.module}::swap_b_for_a`,
                [
                    `${this.contractAddr}::coin_types::YTToken`,
                    '0x1::aptos_coin::AptosCoin'
                ],
                [this.contractAddr, amountInOctas.toString()]
            );
            
            console.log('📝 Built swap transaction:', transaction);
            
            // Execute transaction
            const result = await this.wallet.signAndSubmitTransaction(transaction);
            
            console.log('✅ Swap transaction completed:', result);
            
            return {
                success: true,
                txHash: result.hash,
                sellToken: 'APT',
                sellAmount: amount,
                receiveToken: 'YT',
                explorerUrl: this.client.getExplorerUrl(result.hash)
            };
            
        } catch (error) {
            console.error('❌ APT → YT swap failed:', error);
            throw new Error(`Swap failed: ${error.message}`);
        }
    }

    // ==========================================
    // LIQUIDITY OPERATIONS
    // ==========================================

    async addLiquidity(tokenA, tokenB, amountA, amountB) {
        console.log(`💧 Adding liquidity: ${amountA} ${tokenA} + ${amountB} ${tokenB}`);
        
        if (!this.wallet.isConnected()) {
            throw new Error('Wallet not connected');
        }
        
        try {
            const amountAOctas = this.client.aptToOctas(amountA);
            const amountBOctas = this.client.aptToOctas(amountB);
            
            const transaction = this.client.buildTransaction(
                `${this.module}::add_liquidity`,
                [tokenA, tokenB],
                [this.contractAddr, amountAOctas.toString(), amountBOctas.toString()]
            );
            
            const result = await this.wallet.signAndSubmitTransaction(transaction);
            
            console.log('✅ Liquidity added:', result);
            
            return {
                success: true,
                txHash: result.hash,
                explorerUrl: this.client.getExplorerUrl(result.hash)
            };
            
        } catch (error) {
            console.error('❌ Add liquidity failed:', error);
            throw new Error(`Add liquidity failed: ${error.message}`);
        }
    }

    // ==========================================
    // VIEW FUNCTIONS
    // ==========================================

    async getAmountOut(amountIn, reserveIn, reserveOut, fee = 30) {
        console.log(`📊 Calculating output amount...`);
        
        try {
            const result = await this.client.view(
                `${this.module}::get_amount_out`,
                [],
                [amountIn.toString(), reserveIn.toString(), reserveOut.toString(), fee.toString()]
            );
            
            const amountOut = this.client.octasToApt(result[0]);
            console.log(`💰 Amount out: ${amountOut}`);
            
            return amountOut;
        } catch (error) {
            console.error('❌ Failed to calculate amount out:', error);
            return 0;
        }
    }

    async getReserves(tokenA, tokenB) {
        console.log(`📊 Getting reserves for ${tokenA}/${tokenB} pool...`);
        
        try {
            const result = await this.client.view(
                `${this.module}::get_reserves`,
                [tokenA, tokenB],
                [this.contractAddr]
            );
            
            const reserveA = this.client.octasToApt(result[0]);
            const reserveB = this.client.octasToApt(result[1]);
            
            console.log(`💰 Reserves: ${reserveA} ${tokenA}, ${reserveB} ${tokenB}`);
            
            return { reserveA, reserveB };
        } catch (error) {
            console.error('❌ Failed to get reserves:', error);
            return { reserveA: 0, reserveB: 0 };
        }
    }

    // ==========================================
    // UTILITY METHODS
    // ==========================================

    async estimateSwapOutput(sellToken, sellAmount) {
        console.log(`📊 Estimating swap output for ${sellAmount} ${sellToken}...`);
        
        try {
            let tokenA, tokenB;
            
            if (sellToken === 'PT') {
                tokenA = `${this.contractAddr}::coin_types::PTToken`;
                tokenB = '0x1::aptos_coin::AptosCoin';
            } else if (sellToken === 'YT') {
                tokenA = `${this.contractAddr}::coin_types::YTToken`;
                tokenB = '0x1::aptos_coin::AptosCoin';
            } else {
                throw new Error(`Unsupported token: ${sellToken}`);
            }
            
            // Get pool reserves
            const { reserveA, reserveB } = await this.getReserves(tokenA, tokenB);
            
            if (reserveA === 0 || reserveB === 0) {
                console.warn('⚠️ Pool has no liquidity');
                return 0;
            }
            
            // Calculate output amount
            const amountInOctas = this.client.aptToOctas(sellAmount);
            const reserveInOctas = this.client.aptToOctas(reserveA);
            const reserveOutOctas = this.client.aptToOctas(reserveB);
            
            const amountOut = await this.getAmountOut(amountInOctas, reserveInOctas, reserveOutOctas);
            
            return amountOut;
            
        } catch (error) {
            console.error('❌ Failed to estimate swap output:', error);
            return 0;
        }
    }

    // ==========================================
    // DEBUG METHODS
    // ==========================================

    debugInfo() {
        console.log('🔍 AMM Contract Debug Info:');
        console.log('Contract Address:', this.contractAddr);
        console.log('Module:', this.module);
        console.log('Wallet Connected:', this.wallet.isConnected());
        console.log('Client Initialized:', this.client.isInitialized);
        
        return {
            contractAddress: this.contractAddr,
            module: this.module,
            walletConnected: this.wallet.isConnected(),
            clientInitialized: this.client.isInitialized
        };
    }
}

// Export for module usage
if (typeof module !== 'undefined' && module.exports) {
    module.exports = TesseraptAMMContract;
}
