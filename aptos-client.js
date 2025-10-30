// TESSERAPT Aptos Client Configuration
// Manages connection to Aptos blockchain and smart contracts

const APTOS_CONFIG = {
    network: 'testnet',
    nodeUrl: 'https://fullnode.testnet.aptoslabs.com/v1',
    contractAddress: '0x7c6a215d114fecaecf81efb2e4e1c44a8a781d906aa4b51a0c0ef44f9fe70c16',
    explorerUrl: 'https://explorer.aptoslabs.com'
};

class AptosClientManager {
    constructor() {
        this.config = APTOS_CONFIG;
        this.client = null;
        this.contractAddr = APTOS_CONFIG.contractAddress;
        this.isInitialized = false;
        
        this.init();
    }

    async init() {
        try {
            // No SDK needed - we use direct API calls
            this.client = {
                // Simple wrapper for API calls
                get: async (endpoint) => {
                    const response = await fetch(`${this.config.nodeUrl}/${endpoint}`);
                    if (!response.ok) throw new Error(`API call failed: ${response.statusText}`);
                    return await response.json();
                },
                post: async (endpoint, body) => {
                    const response = await fetch(`${this.config.nodeUrl}/${endpoint}`, {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify(body)
                    });
                    if (!response.ok) throw new Error(`API call failed: ${response.statusText}`);
                    return await response.json();
                }
            };
            
            this.isInitialized = true;
            console.log('✅ Aptos Client initialized successfully');
            console.log('📍 Network:', this.config.network);
            console.log('📍 Contract:', this.contractAddr);
            
            // Test connection
            await this.testConnection();
            
        } catch (error) {
            console.error('❌ Failed to initialize Aptos Client:', error);
            this.isInitialized = false;
        }
    }

    async testConnection() {
        try {
            const ledgerInfo = await this.client.get('');
            console.log('✅ Connected to Aptos blockchain');
            console.log('📊 Chain ID:', ledgerInfo.chain_id);
            console.log('📊 Ledger version:', ledgerInfo.ledger_version);
            return true;
        } catch (error) {
            console.error('❌ Connection test failed:', error);
            return false;
        }
    }

    // ==========================================
    // VIEW FUNCTIONS
    // ==========================================

    async view(functionName, typeArgs = [], args = []) {
        if (!this.isInitialized) {
            throw new Error('Aptos client not initialized');
        }

        try {
            const payload = {
                function: `${this.contractAddr}::${functionName}`,
                type_arguments: typeArgs,
                arguments: args
            };

            console.log('📖 View call:', functionName, args);
            
            const result = await this.client.post('view', payload);
            
            console.log('✅ View result:', result);
            return result;
            
        } catch (error) {
            console.error(`❌ View call failed (${functionName}):`, error);
            throw error;
        }
    }
    
    async waitForTransaction(txHash, timeoutSecs = 30) {
        console.log('⏳ Waiting for transaction:', txHash);
        
        const startTime = Date.now();
        const timeout = timeoutSecs * 1000;
        
        while (Date.now() - startTime < timeout) {
            try {
                const tx = await this.client.get(`transactions/by_hash/${txHash}`);
                
                if (tx && tx.type !== 'pending_transaction') {
                    console.log('✅ Transaction confirmed:', txHash);
                    
                    if (tx.success === false) {
                        throw new Error(`Transaction failed: ${tx.vm_status}`);
                    }
                    
                    return tx;
                }
            } catch (error) {
                // Transaction not found yet, continue waiting
            }
            
            // Wait 1 second before checking again
            await new Promise(resolve => setTimeout(resolve, 1000));
        }
        
        throw new Error(`Transaction ${txHash} timed out after ${timeoutSecs} seconds`);
    }

    // ==========================================
    // TRANSACTION BUILDING
    // ==========================================

    buildTransaction(functionName, typeArgs = [], args = []) {
        return {
            function: `${this.contractAddr}::${functionName}`,
            type_arguments: typeArgs,
            arguments: args
        };
    }

    buildTransactionPayload(functionName, typeArgs = [], args = []) {
        return {
            data: {
                function: `${this.contractAddr}::${functionName}`,
                typeArguments: typeArgs,
                functionArguments: args
            }
        };
    }

    // ==========================================
    // ACCOUNT FUNCTIONS
    // ==========================================

    async getAccountBalance(address) {
        try {
            const resources = await this.client.get(`accounts/${address}/resources`);
            const aptResource = resources.find(r => r.type === '0x1::coin::CoinStore<0x1::aptos_coin::AptosCoin>');
            
            if (aptResource && aptResource.data && aptResource.data.coin) {
                return this.fromOctas(aptResource.data.coin.value);
            }
            
            return 0;
        } catch (error) {
            console.error('Error getting APT balance:', error);
            return 0;
        }
    }

    async getAccountInfo(address) {
        try {
            const account = await this.client.get(`accounts/${address}`);
            return account;
        } catch (error) {
            console.error('Error getting account info:', error);
            return null;
        }
    }
    
    async getAccountResources(address) {
        try {
            return await this.client.get(`accounts/${address}/resources`);
        } catch (error) {
            console.error('Error getting account resources:', error);
            return [];
        }
    }

    // ==========================================
    // TRANSACTION MONITORING
    // ==========================================

    getExplorerUrl(txHash) {
        return `${this.config.explorerUrl}/txn/${txHash}?network=${this.config.network}`;
    }

    getAccountExplorerUrl(address) {
        return `${this.config.explorerUrl}/account/${address}?network=${this.config.network}`;
    }

    async simulateTransaction(transaction, senderAddress) {
        console.log('🧪 Simulating transaction...');
        
        if (!this.isInitialized) {
            throw new Error('Aptos client not initialized');
        }

        try {
            // Simulate the transaction to check if it will succeed
            const payload = {
                ...transaction,
                sender: senderAddress
            };

            const result = await this.client.post('transactions/simulate', payload);
            
            console.log('✅ Simulation result:', result);
            
            // Check if simulation was successful
            if (result && result[0] && result[0].success === false) {
                throw new Error(`Simulation failed: ${result[0].vm_status}`);
            }
            
            return result;
            
        } catch (error) {
            console.error('❌ Transaction simulation failed:', error);
            throw error;
        }
    }

    // ==========================================
    // UTILITY FUNCTIONS
    // ==========================================

    toOctas(amount) {
        // Convert human-readable amount to 8 decimals
        return Math.floor(amount * 100000000);
    }

    fromOctas(amount) {
        // Convert 8 decimals to human-readable
        return Number(amount) / 100000000;
    }

    formatAddress(address) {
        if (!address) return '';
        return `${address.slice(0, 6)}...${address.slice(-4)}`;
    }

    // ==========================================
    // HEALTH CHECK
    // ==========================================

    async getSystemHealth() {
        const health = {
            client: this.isInitialized,
            network: this.config.network,
            contractAddress: this.contractAddr,
            connection: false,
            ledgerInfo: null
        };

        try {
            health.ledgerInfo = await this.client.get('');
            health.connection = true;
        } catch (error) {
            console.error('Health check failed:', error);
        }

        return health;
    }
    
    // Alias methods for compatibility
    aptToOctas(amount) {
        return this.toOctas(amount);
    }
    
    octasToApt(amount) {
        return this.fromOctas(amount);
    }

    debugInfo() {
        console.log('🔍 Aptos Client Debug Info:');
        console.log('Initialized:', this.isInitialized);
        console.log('Network:', this.config.network);
        console.log('Node URL:', this.config.nodeUrl);
        console.log('Contract Address:', this.contractAddr);
        
        return {
            initialized: this.isInitialized,
            config: this.config,
            client: !!this.client
        };
    }
}

// Initialize global Aptos client
let aptosClient;

document.addEventListener('DOMContentLoaded', function() {
    aptosClient = new AptosClientManager();
    
    // Expose globally
    window.aptosClient = aptosClient;
    
    console.log('🚀 Aptos Client loaded and ready');
});

// Export for module usage
if (typeof module !== 'undefined' && module.exports) {
    module.exports = AptosClientManager;
}
