// WalletConnect Integration for TESSERAPT
// This file handles automatic wallet detection and connection

class TesseraptWalletManager {
    constructor() {
        this.connectedWallet = null;
        this.walletAddress = null;
        this.walletAccount = null;
        this.walletConnectClient = null;
        this.supportedWallets = [];

        this.init();
    }

    async init() {
        // Initialize WalletConnect
        await this.initWalletConnect();

        // Detect available wallets
        this.detectAvailableWallets();

        // Check for existing connections
        await this.checkExistingConnections();

        // Setup event listeners
        this.setupEventListeners();
    }

    async initWalletConnect() {
        try {
            // Import WalletConnect modules (these would be loaded via CDN or npm)
            const { WalletConnectModal } = window.WalletConnectModal || {};
            const { createWeb3Modal, defaultConfig } = window.Web3Modal || {};

            if (!WalletConnectModal || !createWeb3Modal) {
                console.log('WalletConnect not available, falling back to direct wallet connections');
                return;
            }

            // Project configuration
            const projectId = 'YOUR_WALLETCONNECT_PROJECT_ID'; // Replace with actual project ID

            const metadata = {
                name: 'TESSERAPT',
                description: 'AI-powered DeFi yield maximizer with native lending on Aptos',
                url: window.location.origin,
                icons: [`${window.location.origin}/logof1.png`]
            };

            // Aptos chain configuration
            const aptosChain = {
                chainId: 1, // Aptos mainnet
                name: 'Aptos',
                currency: 'APT',
                explorerUrl: 'https://explorer.aptoslabs.com',
                rpcUrl: 'https://fullnode.mainnet.aptoslabs.com/v1'
            };

            const config = defaultConfig({
                metadata,
                chains: [aptosChain],
                projectId,
                enableAnalytics: true
            });

            // Create Web3Modal instance
            this.walletConnectClient = createWeb3Modal({
                config,
                chains: [aptosChain],
                projectId,
                enableAnalytics: true
            });

            console.log('WalletConnect initialized successfully');
        } catch (error) {
            console.error('Failed to initialize WalletConnect:', error);
        }
    }

    detectAvailableWallets() {
        const wallets = [];

        // Petra Wallet Detection (Always show first)
        if (window.aptos) {
            wallets.push({
                name: 'Petra Wallet',
                id: 'petra',
                icon: 'P',
                description: 'Official Aptos wallet extension',
                installed: true,
                connector: window.aptos,
                primary: true
            });
        } else {
            wallets.push({
                name: 'Petra Wallet',
                id: 'petra',
                icon: 'P',
                description: 'Official Aptos wallet extension',
                installed: false,
                downloadUrl: 'https://petra.app/',
                primary: true
            });
        }

        // MetaMask Detection
        if (window.ethereum && window.ethereum.isMetaMask) {
            wallets.push({
                name: 'MetaMask',
                id: 'metamask',
                icon: 'MM',
                description: 'Popular Ethereum wallet (via bridge)',
                installed: true,
                connector: window.ethereum,
                primary: false
            });
        } else {
            wallets.push({
                name: 'MetaMask',
                id: 'metamask',
                icon: 'MM',
                description: 'Popular Ethereum wallet (via bridge)',
                installed: false,
                downloadUrl: 'https://metamask.io/',
                primary: false
            });
        }

        // Martian Wallet Detection
        if (window.martian) {
            wallets.push({
                name: 'Martian Wallet',
                id: 'martian',
                icon: 'M',
                description: 'Multi-chain wallet for Aptos',
                installed: true,
                connector: window.martian,
                primary: false
            });
        } else {
            wallets.push({
                name: 'Martian Wallet',
                id: 'martian',
                icon: 'M',
                description: 'Multi-chain wallet for Aptos',
                installed: false,
                downloadUrl: 'https://martianwallet.xyz/',
                primary: false
            });
        }

        // Pontem Wallet Detection
        if (window.pontem) {
            wallets.push({
                name: 'Pontem Wallet',
                id: 'pontem',
                icon: 'Po',
                description: 'Secure Aptos wallet',
                installed: true,
                connector: window.pontem,
                primary: false
            });
        } else {
            wallets.push({
                name: 'Pontem Wallet',
                id: 'pontem',
                icon: 'Po',
                description: 'Secure Aptos wallet',
                installed: false,
                downloadUrl: 'https://pontem.network/pontem-wallet',
                primary: false
            });
        }

        // Fewcha Wallet Detection
        if (window.fewcha) {
            wallets.push({
                name: 'Fewcha Wallet',
                id: 'fewcha',
                icon: 'F',
                description: 'Aptos ecosystem wallet',
                installed: true,
                connector: window.fewcha,
                primary: false
            });
        } else {
            wallets.push({
                name: 'Fewcha Wallet',
                id: 'fewcha',
                icon: 'F',
                description: 'Aptos ecosystem wallet',
                installed: false,
                downloadUrl: 'https://fewcha.app/',
                primary: false
            });
        }

        // WalletConnect Support
        if (this.walletConnectClient) {
            wallets.push({
                name: 'WalletConnect',
                id: 'walletconnect',
                icon: 'WC',
                description: 'Connect with mobile wallets',
                installed: true,
                connector: this.walletConnectClient,
                primary: false
            });
        }

        this.supportedWallets = wallets;
        this.currentView = 'primary'; // Track current view
        this.updateWalletUI();
    }

    async checkExistingConnections() {
        // Check Petra connection
        if (window.aptos) {
            try {
                const isConnected = await window.aptos.isConnected();
                if (isConnected) {
                    const account = await window.aptos.account();
                    if (account) {
                        this.connectedWallet = 'petra';
                        this.walletAddress = account.address;
                        this.walletAccount = account;
                        this.updateConnectedUI();
                        return;
                    }
                }
            } catch (error) {
                console.log('No existing Petra connection');
            }
        }

        // Check WalletConnect connection
        if (this.walletConnectClient) {
            try {
                const isConnected = this.walletConnectClient.getIsConnected();
                if (isConnected) {
                    const account = this.walletConnectClient.getAccount();
                    if (account) {
                        this.connectedWallet = 'walletconnect';
                        this.walletAddress = account.address;
                        this.walletAccount = account;
                        this.updateConnectedUI();
                        return;
                    }
                }
            } catch (error) {
                console.log('No existing WalletConnect connection');
            }
        }
    }

    async connectWallet(walletId) {
        const wallet = this.supportedWallets.find(w => w.id === walletId);

        if (!wallet) {
            throw new Error('Wallet not found');
        }

        if (!wallet.installed) {
            window.open(wallet.downloadUrl, '_blank');
            return;
        }

        try {
            switch (walletId) {
                case 'petra':
                    return await this.connectPetra(wallet.connector);
                case 'martian':
                    return await this.connectMartian(wallet.connector);
                case 'pontem':
                    return await this.connectPontem(wallet.connector);
                case 'fewcha':
                    return await this.connectFewcha(wallet.connector);
                case 'walletconnect':
                    return await this.connectWalletConnect();
                case 'metamask':
                    return await this.connectMetaMask();
                default:
                    throw new Error('Unsupported wallet');
            }
        } catch (error) {
            console.error(`Failed to connect to ${walletId}:`, error);
            throw error;
        }
    }

    async connectPetra(connector) {
        const response = await connector.connect();
        const account = await connector.account();

        if (account && account.address) {
            this.connectedWallet = 'petra';
            this.walletAddress = account.address;
            this.walletAccount = account;

            // Get network info
            try {
                const network = await connector.network();
                console.log('Connected to network:', network);
            } catch (error) {
                console.log('Could not get network info');
            }

            this.updateConnectedUI();
            return { success: true, address: account.address };
        }

        throw new Error('Failed to get account information');
    }

    async connectMartian(connector) {
        const response = await connector.connect();

        if (response && response.address) {
            this.connectedWallet = 'martian';
            this.walletAddress = response.address;
            this.walletAccount = response;
            this.updateConnectedUI();
            return { success: true, address: response.address };
        }

        throw new Error('Failed to connect to Martian wallet');
    }

    async connectPontem(connector) {
        const response = await connector.connect();

        if (response && response.address) {
            this.connectedWallet = 'pontem';
            this.walletAddress = response.address;
            this.walletAccount = response;
            this.updateConnectedUI();
            return { success: true, address: response.address };
        }

        throw new Error('Failed to connect to Pontem wallet');
    }

    async connectFewcha(connector) {
        const response = await connector.connect();

        if (response && response.address) {
            this.connectedWallet = 'fewcha';
            this.walletAddress = response.address;
            this.walletAccount = response;
            this.updateConnectedUI();
            return { success: true, address: response.address };
        }

        throw new Error('Failed to connect to Fewcha wallet');
    }

    async connectMetaMask() {
        if (!window.ethereum || !window.ethereum.isMetaMask) {
            window.open('https://metamask.io/', '_blank');
            return;
        }

        try {
            // Request account access
            const accounts = await window.ethereum.request({
                method: 'eth_requestAccounts'
            });

            if (accounts && accounts.length > 0) {
                // Note: MetaMask provides Ethereum addresses, not Aptos addresses
                // In a real implementation, you'd need a bridge or conversion mechanism
                this.connectedWallet = 'metamask';
                this.walletAddress = accounts[0];
                this.walletAccount = { address: accounts[0], type: 'ethereum' };

                this.updateConnectedUI();

                // Show warning about Ethereum vs Aptos
                alert('MetaMask connected! Note: This is an Ethereum wallet. For full Aptos functionality, consider using Petra or other Aptos-native wallets.');

                return { success: true, address: accounts[0] };
            }

            throw new Error('No accounts found in MetaMask');
        } catch (error) {
            if (error.code === 4001) {
                throw new Error('Connection rejected by user');
            }
            throw new Error(`MetaMask connection failed: ${error.message}`);
        }
    }

    async connectWalletConnect() {
        if (!this.walletConnectClient) {
            throw new Error('WalletConnect not initialized');
        }

        try {
            await this.walletConnectClient.open();

            // Wait for connection
            return new Promise((resolve, reject) => {
                const timeout = setTimeout(() => {
                    reject(new Error('Connection timeout'));
                }, 60000); // 60 second timeout

                this.walletConnectClient.subscribeState((state) => {
                    if (state.open === false && state.selectedNetworkId) {
                        clearTimeout(timeout);

                        const account = this.walletConnectClient.getAccount();
                        if (account) {
                            this.connectedWallet = 'walletconnect';
                            this.walletAddress = account.address;
                            this.walletAccount = account;
                            this.updateConnectedUI();
                            resolve({ success: true, address: account.address });
                        } else {
                            reject(new Error('Failed to get account from WalletConnect'));
                        }
                    }
                });
            });
        } catch (error) {
            throw new Error(`WalletConnect connection failed: ${error.message}`);
        }
    }

    async disconnectWallet() {
        try {
            if (this.connectedWallet === 'petra' && window.aptos) {
                await window.aptos.disconnect();
            } else if (this.connectedWallet === 'walletconnect' && this.walletConnectClient) {
                await this.walletConnectClient.disconnect();
            }

            this.connectedWallet = null;
            this.walletAddress = null;
            this.walletAccount = null;

            this.updateDisconnectedUI();
            return { success: true };
        } catch (error) {
            console.error('Disconnect error:', error);
            // Force UI update even if disconnect fails
            this.connectedWallet = null;
            this.walletAddress = null;
            this.walletAccount = null;
            this.updateDisconnectedUI();
            return { success: false, error: error.message };
        }
    }

    setupEventListeners() {
        // Petra event listeners
        if (window.aptos) {
            window.aptos.onAccountChange((account) => {
                if (this.connectedWallet === 'petra') {
                    if (account) {
                        this.walletAddress = account.address;
                        this.walletAccount = account;
                        this.updateConnectedUI();
                    } else {
                        this.disconnectWallet();
                    }
                }
            });

            window.aptos.onNetworkChange((network) => {
                console.log('Network changed:', network);
            });
        }

        // WalletConnect event listeners
        if (this.walletConnectClient) {
            this.walletConnectClient.subscribeState((state) => {
                console.log('WalletConnect state changed:', state);
            });
        }
    }

    updateWalletUI() {
        // Update wallet options in modal
        const walletOptions = document.querySelector('.wallet-options');
        if (!walletOptions) return;

        walletOptions.innerHTML = '';

        if (this.currentView === 'primary') {
            // Show Petra and "Other Wallets" option
            const petraWallet = this.supportedWallets.find(w => w.id === 'petra');
            if (petraWallet) {
                const petraElement = document.createElement('div');
                petraElement.className = 'wallet-option';
                petraElement.onclick = () => this.handleWalletClick('petra');

                petraElement.innerHTML = `
                    <div class="wallet-icon">${petraWallet.icon}</div>
                    <div class="wallet-info">
                        <div class="wallet-name">${petraWallet.name}</div>
                        <div class="wallet-description">${petraWallet.description}</div>
                    </div>
                    <div class="wallet-status">${petraWallet.installed ? 'Available' : 'Install'}</div>
                `;

                walletOptions.appendChild(petraElement);
            }

            // Add "Other Wallets" option
            const otherWalletsElement = document.createElement('div');
            otherWalletsElement.className = 'wallet-option';
            otherWalletsElement.onclick = () => this.showOtherWallets();

            otherWalletsElement.innerHTML = `
                <div class="wallet-icon">⋯</div>
                <div class="wallet-info">
                    <div class="wallet-name">Other Wallets</div>
                    <div class="wallet-description">View more wallet options</div>
                </div>
                <div class="wallet-status">→</div>
            `;

            walletOptions.appendChild(otherWalletsElement);
        } else {
            // Show all wallets with back button
            const backElement = document.createElement('div');
            backElement.className = 'wallet-option wallet-back';
            backElement.onclick = () => this.showPrimaryWallets();

            backElement.innerHTML = `
                <div class="wallet-icon">←</div>
                <div class="wallet-info">
                    <div class="wallet-name">Back</div>
                    <div class="wallet-description">Return to main options</div>
                </div>
                <div class="wallet-status"></div>
            `;

            walletOptions.appendChild(backElement);

            // Show all non-primary wallets
            this.supportedWallets.filter(w => !w.primary).forEach(wallet => {
                const walletElement = document.createElement('div');
                walletElement.className = 'wallet-option';
                walletElement.onclick = () => this.handleWalletClick(wallet.id);

                walletElement.innerHTML = `
                    <div class="wallet-icon">${wallet.icon}</div>
                    <div class="wallet-info">
                        <div class="wallet-name">${wallet.name}</div>
                        <div class="wallet-description">${wallet.description}</div>
                    </div>
                    <div class="wallet-status">${wallet.installed ? 'Available' : 'Install'}</div>
                `;

                walletOptions.appendChild(walletElement);
            });
        }
    }

    showOtherWallets() {
        this.currentView = 'other';
        this.updateWalletUI();
    }

    showPrimaryWallets() {
        this.currentView = 'primary';
        this.updateWalletUI();
    }

    async handleWalletClick(walletId) {
        try {
            const result = await this.connectWallet(walletId);
            if (result && result.success) {
                this.closeWalletModal();
                this.showSuccessMessage(`Successfully connected to ${walletId}!`);
            }
        } catch (error) {
            this.showErrorMessage(`Failed to connect: ${error.message}`);
        }
    }

    updateConnectedUI() {
        if (this.walletAddress) {
            const loginBtn = document.querySelector('.login-btn');
            const connectedWallet = document.getElementById('connectedWallet');
            const walletAddress = document.getElementById('walletAddress');

            if (loginBtn) loginBtn.style.display = 'none';
            if (connectedWallet) connectedWallet.style.display = 'flex';
            if (walletAddress) {
                walletAddress.textContent = `${this.walletAddress.slice(0, 6)}...${this.walletAddress.slice(-4)}`;
            }
        }
    }

    updateDisconnectedUI() {
        const loginBtn = document.querySelector('.login-btn');
        const connectedWallet = document.getElementById('connectedWallet');

        if (loginBtn) loginBtn.style.display = 'block';
        if (connectedWallet) connectedWallet.style.display = 'none';
    }

    openWalletModal() {
        const modal = document.getElementById('walletModal');
        if (modal) {
            modal.style.display = 'flex';
            this.detectAvailableWallets(); // Refresh wallet detection
        }
    }

    closeWalletModal() {
        const modal = document.getElementById('walletModal');
        if (modal) {
            modal.style.display = 'none';
        }
    }

    showSuccessMessage(message) {
        alert(message); // Replace with better notification system
    }

    showErrorMessage(message) {
        alert(message); // Replace with better notification system
    }

    // Public API methods
    getConnectedWallet() {
        return {
            type: this.connectedWallet,
            address: this.walletAddress,
            account: this.walletAccount
        };
    }

    isConnected() {
        return !!this.connectedWallet;
    }

    async getBalance() {
        if (!this.walletAddress) return null;

        try {
            // Implementation would depend on Aptos SDK
            console.log('Getting balance for:', this.walletAddress);
            return null; // Placeholder
        } catch (error) {
            console.error('Error getting balance:', error);
            return null;
        }
    }

    async signTransaction(transaction) {
        if (!this.connectedWallet) {
            throw new Error('No wallet connected');
        }

        try {
            switch (this.connectedWallet) {
                case 'petra':
                    return await window.aptos.signTransaction(transaction);
                case 'martian':
                    return await window.martian.signTransaction(transaction);
                case 'pontem':
                    return await window.pontem.signTransaction(transaction);
                case 'fewcha':
                    return await window.fewcha.signTransaction(transaction);
                default:
                    throw new Error('Unsupported wallet for transaction signing');
            }
        } catch (error) {
            console.error('Transaction signing error:', error);
            throw error;
        }
    }

    // ==========================================
    // TRANSACTION METHODS
    // ==========================================

    async signAndSubmitTransaction(transaction) {
        if (!this.connectedWallet || !this.walletAddress) {
            throw new Error('Wallet not connected');
        }
        
        console.log('📝 Signing transaction:', transaction);
        console.log('🔗 Using wallet:', this.connectedWallet);
        
        try {
            let result;
            
            switch (this.connectedWallet) {
                case 'petra':
                    if (!window.aptos) {
                        throw new Error('Petra wallet not available');
                    }
                    result = await window.aptos.signAndSubmitTransaction(transaction);
                    break;
                    
                case 'martian':
                    if (!window.martian) {
                        throw new Error('Martian wallet not available');
                    }
                    result = await window.martian.signAndSubmitTransaction(transaction);
                    break;
                    
                case 'pontem':
                    if (!window.pontem) {
                        throw new Error('Pontem wallet not available');
                    }
                    result = await window.pontem.signAndSubmitTransaction(transaction);
                    break;
                    
                case 'fewcha':
                    if (!window.fewcha) {
                        throw new Error('Fewcha wallet not available');
                    }
                    result = await window.fewcha.signAndSubmitTransaction(transaction);
                    break;
                    
                default:
                    throw new Error(`Unsupported wallet for transactions: ${this.connectedWallet}`);
            }
            
            console.log('✅ Transaction signed and submitted:', result);
            
            // Wait for transaction confirmation if aptosClient is available
            if (window.aptosClient && window.aptosClient.isInitialized) {
                console.log('⏳ Waiting for transaction confirmation...');
                const confirmedResult = await window.aptosClient.waitForTransaction(result.hash);
                console.log('✅ Transaction confirmed:', confirmedResult);
                return {
                    ...result,
                    confirmed: confirmedResult
                };
            }
            
            return result;
            
        } catch (error) {
            console.error('❌ Transaction failed:', error);
            
            // Handle specific error types
            if (error.code === 4001) {
                throw new Error('Transaction rejected by user');
            } else if (error.message.includes('insufficient')) {
                throw new Error('Insufficient balance for transaction');
            } else if (error.message.includes('gas')) {
                throw new Error('Transaction failed due to gas issues');
            }
            
            throw error;
        }
    }

    async simulateTransaction(transaction) {
        if (!this.connectedWallet || !this.walletAddress) {
            throw new Error('Wallet not connected');
        }
        
        if (!window.aptosClient || !window.aptosClient.isInitialized) {
            throw new Error('Aptos client not available');
        }
        
        try {
            const simulation = await window.aptosClient.simulateTransaction(
                transaction,
                this.walletAddress
            );
            
            return simulation;
        } catch (error) {
            console.error('❌ Transaction simulation failed:', error);
            throw error;
        }
    }
}

// Initialize wallet manager when DOM is loaded
let walletManager;

document.addEventListener('DOMContentLoaded', function () {
    walletManager = new TesseraptWalletManager();

    // Expose global functions for HTML onclick handlers
    window.openWalletModal = () => walletManager.openWalletModal();
    window.closeWalletModal = () => walletManager.closeWalletModal();
    window.disconnectWallet = () => walletManager.disconnectWallet();
    window.connectWallet = (walletId) => walletManager.connectWallet(walletId);
});

// Export for module usage
if (typeof module !== 'undefined' && module.exports) {
    module.exports = TesseraptWalletManager;
}