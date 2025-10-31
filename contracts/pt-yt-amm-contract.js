// TESSERAPT PT/YT AMM Contract Interface
// Handles PT and YT token trading through the AMM

class PTYTAMMContract {
    constructor(aptosClient) {
        this.client = aptosClient;
        this.contractAddress = '0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16';
        this.poolId = 0;
        this.decimals = 8;
        this.fee = 0.997; // 0.3% trading fee
        
        this.reserves = {
            pt: 0,
            yt: 0,
            lastUpdate: 0
        };
        
        console.log('🔄 PT/YT AMM Contract initialized');
        this.startReserveUpdates();
    }

    // ==========================================
    // RESERVE MANAGEMENT
    // ==========================================

    async getPoolReserves() {
        try {
            if (!this.client || !this.client.isInitialized) {
                console.warn('⚠️ Aptos client not initialized, using cached reserves');
                return this.reserves;
            }

            const result = await this.client.client.view({
                payload: {
                    function: `${this.contractAddress}::pt_yt_amm::get_pool_reserves`,
                    functionArguments: [this.contractAddress, this.poolId]
                }
            });

            this.reserves = {
                pt: Number(result[0]),
                yt: Number(result[1]),
                lastUpdate: Date.now()
            };

            console.log(`📊 Pool Reserves: PT=${this.fromBlockchainAmount(this.reserves.pt).toFixed(4)}, YT=${this.fromBlockchainAmount(this.reserves.yt).toFixed(4)}`);
            
            return this.reserves;
        } catch (error) {
            console.error('❌ Failed to fetch pool reserves:', error);
            return this.reserves;
        }
    }

    startReserveUpdates() {
        // Update reserves every 5 seconds
        setInterval(() => {
            this.getPoolReserves();
        }, 5000);

        // Initial fetch
        this.getPoolReserves();
    }

    // ==========================================
    // PRICE CALCULATION
    // ==========================================

    calculateSwapOutput(amountIn, fromToken) {
        if (this.reserves.pt === 0 || this.reserves.yt === 0) {
            console.warn('⚠️ Pool reserves not loaded yet');
            return 0;
        }

        const amountInScaled = this.toBlockchainAmount(amountIn);
        const k = this.reserves.pt * this.reserves.yt;

        let output = 0;

        if (fromToken === 'PT') {
            // Swapping PT for YT
            const newPtReserve = this.reserves.pt + amountInScaled;
            const newYtReserve = k / newPtReserve;
            const ytOut = (this.reserves.yt - newYtReserve) * this.fee;
            output = this.fromBlockchainAmount(ytOut);
        } else {
            // Swapping YT for PT
            const newYtReserve = this.reserves.yt + amountInScaled;
            const newPtReserve = k / newYtReserve;
            const ptOut = (this.reserves.pt - newPtReserve) * this.fee;
            output = this.fromBlockchainAmount(ptOut);
        }

        return output;
    }

    getExchangeRate(fromToken) {
        if (this.reserves.pt === 0 || this.reserves.yt === 0) return 0;

        if (fromToken === 'PT') {
            return this.fromBlockchainAmount(this.reserves.yt) / this.fromBlockchainAmount(this.reserves.pt);
        } else {
            return this.fromBlockchainAmount(this.reserves.pt) / this.fromBlockchainAmount(this.reserves.yt);
        }
    }

    // ==========================================
    // SWAP FUNCTIONS
    // ==========================================

    async swapPTForYT(ptAmount, minYtOut = 0, walletAddress) {
        try {
            console.log(`💱 Swapping ${ptAmount} PT for YT...`);

            if (!this.client || !this.client.isInitialized) {
                throw new Error('Aptos client not initialized');
            }

            if (!walletAddress) {
                throw new Error('Wallet not connected');
            }

            const ptAmountScaled = this.toBlockchainAmount(ptAmount);
            const minYtOutScaled = this.toBlockchainAmount(minYtOut);

            const payload = {
                type: 'entry_function_payload',
                function: `${this.contractAddress}::pt_yt_amm::swap_pt_for_yt`,
                type_arguments: [],
                arguments: [
                    this.contractAddress,
                    this.poolId,
                    ptAmountScaled.toString(),
                    minYtOutScaled.toString()
                ]
            };

            // Request transaction through Petra wallet
            const pendingTransaction = await window.aptos.signAndSubmitTransaction(payload);
            
            console.log(`⏳ Transaction submitted: ${pendingTransaction.hash}`);

            // Wait for transaction
            await this.client.client.waitForTransaction({
                transactionHash: pendingTransaction.hash
            });

            console.log(`✅ Swap completed: ${pendingTransaction.hash}`);

            // Update reserves
            await this.getPoolReserves();

            return {
                success: true,
                hash: pendingTransaction.hash,
                fromToken: 'PT',
                toToken: 'YT',
                amountIn: ptAmount,
                message: `Successfully swapped ${ptAmount} PT for YT`
            };

        } catch (error) {
            console.error('❌ PT→YT swap failed:', error);
            throw error;
        }
    }

    async swapYTForPT(ytAmount, minPtOut = 0, walletAddress) {
        try {
            console.log(`💱 Swapping ${ytAmount} YT for PT...`);

            if (!this.client || !this.client.isInitialized) {
                throw new Error('Aptos client not initialized');
            }

            if (!walletAddress) {
                throw new Error('Wallet not connected');
            }

            const ytAmountScaled = this.toBlockchainAmount(ytAmount);
            const minPtOutScaled = this.toBlockchainAmount(minPtOut);

            const payload = {
                type: 'entry_function_payload',
                function: `${this.contractAddress}::pt_yt_amm::swap_yt_for_pt`,
                type_arguments: [],
                arguments: [
                    this.contractAddress,
                    this.poolId,
                    ytAmountScaled.toString(),
                    minPtOutScaled.toString()
                ]
            };

            // Request transaction through Petra wallet
            const pendingTransaction = await window.aptos.signAndSubmitTransaction(payload);
            
            console.log(`⏳ Transaction submitted: ${pendingTransaction.hash}`);

            // Wait for transaction
            await this.client.client.waitForTransaction({
                transactionHash: pendingTransaction.hash
            });

            console.log(`✅ Swap completed: ${pendingTransaction.hash}`);

            // Update reserves
            await this.getPoolReserves();

            return {
                success: true,
                hash: pendingTransaction.hash,
                fromToken: 'YT',
                toToken: 'PT',
                amountIn: ytAmount,
                message: `Successfully swapped ${ytAmount} YT for PT`
            };

        } catch (error) {
            console.error('❌ YT→PT swap failed:', error);
            throw error;
        }
    }

    // ==========================================
    // HELPER FUNCTIONS
    // ==========================================

    toBlockchainAmount(amount) {
        return Math.floor(amount * Math.pow(10, this.decimals));
    }

    fromBlockchainAmount(amount) {
        return amount / Math.pow(10, this.decimals);
    }

    calculateMinOutput(expectedOutput, slippagePercent = 1) {
        return expectedOutput * (1 - slippagePercent / 100);
    }

    // ==========================================
    // UTILITY FUNCTIONS
    // ==========================================

    getReservesDisplay() {
        return {
            pt: this.fromBlockchainAmount(this.reserves.pt).toFixed(4),
            yt: this.fromBlockchainAmount(this.reserves.yt).toFixed(4),
            lastUpdate: new Date(this.reserves.lastUpdate).toLocaleTimeString()
        };
    }

    isReady() {
        return this.reserves.pt > 0 && this.reserves.yt > 0;
    }
}

// Initialize when dependencies are ready
let ptytAMMContract = null;

function initializePTYTAMM() {
    if (typeof aptosClient !== 'undefined' && aptosClient.isInitialized) {
        ptytAMMContract = new PTYTAMMContract(aptosClient);
        window.ptytAMMContract = ptytAMMContract;
        console.log('✅ PT/YT AMM Contract ready');
    } else {
        setTimeout(initializePTYTAMM, 1000);
    }
}

// Auto-initialize
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initializePTYTAMM);
} else {
    initializePTYTAMM();
}

// Export for module usage
if (typeof module !== 'undefined' && module.exports) {
    module.exports = PTYTAMMContract;
}
