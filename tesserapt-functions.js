// TESSERAPT Platform Functions
// Enhanced implementations for all interactive features

class TesseraptPlatform {
    constructor() {
        this.walletManager = null;
        this.priceOracle = null;
        this.aptosClient = null;
        this.stakingContract = null;
        this.ammContract = null;
        this.stakingData = {
            amount: 0,
            token: 'APT',
            ptTokens: 0,
            ytTokens: 0,
            timestamp: 0
        };
        this.selectedTokenType = 'PT';
        this.selectedLoanDuration = 9;
        this.selectedLoanAmount = 89250;
        this.priceSubscriptions = new Map();
        this.marketData = new Map();

        this.init();
    }

    init() {
        this.setupEventListeners();
        this.initializeWalletManager();
        this.initializePriceOracle();
        this.initializeAptosClient();
        this.setupPriceSubscriptions();
    }

    // ==========================================
    // NAVIGATION FUNCTIONS
    // ==========================================

    showYieldSection() {
        console.log('Navigating to Yield Section');

        // Hide all main sections
        document.querySelectorAll('.hero-section, .trade-section, .loan-section, .about-section').forEach(section => {
            section.style.display = 'none';
        });

        // Show yield section
        const yieldSection = document.querySelector('.yield-section');
        if (yieldSection) {
            yieldSection.style.display = 'flex';
        }

        // Hide navigation
        const nav = document.querySelector('nav');
        if (nav) {
            nav.style.display = 'none';
        }

        // Hide background
        if (typeof toggleBackground === 'function') {
            toggleBackground(false);
        }

        // Scroll to top
        window.scrollTo(0, 0);
    }

    showTradingSection() {
        console.log('Navigating to Trading Section (PT/YT Tokens)');

        // Hide all sections
        document.querySelectorAll('.hero-section, .trade-section, .loan-section, .about-section, .yield-section, .lending-section').forEach(section => {
            section.style.display = 'none';
        });

        // Show trading section
        const tradingSection = document.querySelector('.trading-section');
        if (tradingSection) {
            tradingSection.style.display = 'block';
        }

        // Hide navigation
        const nav = document.querySelector('nav');
        if (nav) {
            nav.style.display = 'none';
        }

        // Update token data
        this.updateTokenPortfolio();

        // Scroll to top
        window.scrollTo(0, 0);
    }

    showLendingSection() {
        console.log('Navigating to Lending Section');

        // Hide all sections
        document.querySelectorAll('.hero-section, .trade-section, .loan-section, .about-section, .yield-section, .trading-section').forEach(section => {
            section.style.display = 'none';
        });

        // Show lending section
        const lendingSection = document.querySelector('.lending-section');
        if (lendingSection) {
            lendingSection.style.display = 'block';
        }

        // Hide navigation
        const nav = document.querySelector('nav');
        if (nav) {
            nav.style.display = 'none';
        }

        // Scroll to top
        window.scrollTo(0, 0);
    }

    showMainSections() {
        console.log('Returning to Main Sections');

        // Show all main sections
        document.querySelectorAll('.hero-section, .trade-section, .loan-section, .about-section').forEach(section => {
            section.style.display = 'flex';
        });

        // Hide all sub-sections
        document.querySelectorAll('.yield-section, .trading-section, .lending-section').forEach(section => {
            section.style.display = 'none';
        });

        // Show navigation
        const nav = document.querySelector('nav');
        if (nav) {
            nav.style.display = 'flex';
        }
    }

    // ==========================================
    // STAKING FUNCTIONS
    // ==========================================

    async handleStaking() {
        console.log('🚀 Processing Real Blockchain Staking Transaction');

        try {
            // 1. Validate input
            const amountInput = document.getElementById('stakeAmount');
            const selectedTokenBtn = document.querySelector('.token-btn.active');

            if (!amountInput || !selectedTokenBtn) {
                throw new Error('Required elements not found');
            }

            const amount = parseFloat(amountInput.value);
            const token = selectedTokenBtn.textContent.trim();

            if (!amount || amount <= 0) {
                throw new Error('Please enter a valid amount to stake');
            }

            // 2. Check wallet connection
            if (!this.walletManager || !this.walletManager.isConnected()) {
                throw new Error('Please connect your wallet first');
            }

            // 3. Check if staking contract is initialized
            if (!this.stakingContract) {
                throw new Error('Staking contract not initialized. Please refresh the page.');
            }

            // 4. Basic validation (let wallet/blockchain handle balance check)
            const userAddress = this.walletManager.walletAddress;
            
            // Only check minimum amount, not balance
            if (amount < 0.01) {
                throw new Error('Minimum stake amount is 0.01 APT');
            }
            
            // Note: We don't check balance here - let Petra wallet show the transaction
            // The wallet will show insufficient funds error if needed
            console.log(`✅ Validation passed, proceeding with transaction for ${amount} APT`);

            // 5. Show loading state
            this.showLoadingState('Preparing staking transaction...');

            // 6. Execute real blockchain staking transaction
            console.log(`💰 Staking ${amount} ${token} on Aptos blockchain...`);
            console.log(`📱 Petra wallet popup should appear now...`);
            const result = await this.stakingContract.stakeAPT(amount);

            console.log('✅ Staking transaction successful:', result);

            // 7. Update staking data with real blockchain data
            await this.updateStakingDataFromBlockchain(amount, token, result);

            // 8. Navigate to trading section
            this.showTradingSection();

            // 9. Show success message with transaction link
            this.showSuccessMessage(
                `Successfully staked ${amount} ${token}!`,
                result.explorerUrl
            );

        } catch (error) {
            console.error('❌ Staking error:', error);
            this.hideLoadingState();
            this.showErrorMessage(`Staking failed: ${error.message}`);
        }
    }

    // Note: submitStakingTransaction is no longer used
    // Real blockchain transactions are handled by stakingContract.stakeAPT()
    // in the handleStaking() method above

    async updateStakingDataFromBlockchain(amount, token, txResult) {
        console.log(`📊 Updating Staking Data from Blockchain: ${amount} ${token}`);

        try {
            const userAddress = this.walletManager.walletAddress;

            // Get real staking stats from blockchain
            const stakingStats = await this.stakingContract.getStakingStats(userAddress);

            // Store staking data with blockchain information
            this.stakingData = {
                amount: amount,
                token: token,
                staptBalance: stakingStats.user.staptBalance,
                staptValue: stakingStats.user.staptValue,
                exchangeRate: stakingStats.protocol.exchangeRate,
                apy: stakingStats.protocol.apy,
                ptTokens: stakingStats.user.staptBalance, // PT tokens = stAPT balance
                ytTokens: stakingStats.user.staptBalance, // YT tokens = stAPT balance
                txHash: txResult.txHash,
                timestamp: Date.now()
            };

            console.log('📊 Updated staking data:', this.stakingData);

            // Update local storage
            localStorage.setItem('tesserapt_staking', JSON.stringify(this.stakingData));

            // Update UI displays
            await this.updateStakingBalanceDisplays();

        } catch (error) {
            console.error('❌ Failed to update staking data from blockchain:', error);
            // Fallback to basic data
            this.stakingData = {
                amount: amount,
                token: token,
                ptTokens: amount,
                ytTokens: amount,
                timestamp: Date.now()
            };
        }
    }

    async updateStakingBalanceDisplays() {
        console.log('🔄 Updating staking balance displays...');

        if (!this.stakingContract || !this.walletManager.isConnected()) {
            return;
        }

        try {
            const userAddress = this.walletManager.walletAddress;
            const stakingStats = await this.stakingContract.getStakingStats(userAddress);

            // Update yield section stats
            const statValues = document.querySelectorAll('.stat-value');
            if (statValues[0]) {
                statValues[0].textContent = `${stakingStats.protocol.apy}%`;
            }

            // Update balance displays if visible
            const balanceElements = document.querySelectorAll('.balance-display');
            if (balanceElements.length > 0) {
                balanceElements.forEach((element, index) => {
                    if (index === 0) {
                        element.textContent = `${stakingStats.user.staptBalance.toFixed(4)} stAPT`;
                    } else if (index === 1) {
                        element.textContent = `≈ ${stakingStats.user.staptValue.toFixed(4)} APT`;
                    }
                });
            }

            console.log('✅ Balance displays updated');

        } catch (error) {
            console.error('❌ Failed to update balance displays:', error);
        }
    }

    showLoadingState(message) {
        console.log(`⏳ Loading: ${message}`);

        // Disable stake button and show loading
        const stakeBtn = document.querySelector('.action-btn');
        if (stakeBtn) {
            stakeBtn.disabled = true;
            stakeBtn.textContent = 'PROCESSING...';
            stakeBtn.style.opacity = '0.6';
        }

        // Show loading message
        this.showInfoMessage(message);
    }

    hideLoadingState() {
        console.log('✅ Hiding loading state');

        // Re-enable stake button
        const stakeBtn = document.querySelector('.action-btn');
        if (stakeBtn) {
            stakeBtn.disabled = false;
            stakeBtn.textContent = 'STAKE NOW';
            stakeBtn.style.opacity = '1';
        }
    }

    showInfoMessage(message) {
        console.log('ℹ️ Info:', message);
        // You can implement a better notification system here
        // For now, we'll just log it
    }

    updateTokenPortfolio() {
        console.log('Updating Token Portfolio Display');

        const { amount, token, ptTokens, ytTokens } = this.stakingData;

        if (amount > 0) {
            // Update PT token display
            const ptAmountEl = document.querySelector('.token-card:first-child .token-amount');
            const ptValueEl = document.querySelector('.token-card:first-child .token-value');

            if (ptAmountEl && ptValueEl) {
                ptAmountEl.textContent = `${ptTokens.toFixed(2)} PT`;
                const ptValue = ptTokens * this.getTokenPrice(token);
                ptValueEl.textContent = `≈ ${ptTokens.toFixed(2)} ${token} ($${ptValue.toLocaleString()})`;
            }

            // Update YT token display
            const ytAmountEl = document.querySelector('.token-card:last-child .token-amount');
            const ytValueEl = document.querySelector('.token-card:last-child .token-value');

            if (ytAmountEl && ytValueEl) {
                const yieldAmount = ytTokens * 0.125; // 12.5% yield
                ytAmountEl.textContent = `${ytTokens.toFixed(2)} YT`;
                const ytValue = yieldAmount * this.getTokenPrice(token);
                ytValueEl.textContent = `≈ ${yieldAmount.toFixed(2)} ${token} ($${ytValue.toLocaleString()})`;
            }
        }
    }

    // ==========================================
    // TRADING FUNCTIONS
    // ==========================================

    openTradingModal() {
        console.log('Opening Trading Modal');
        const modal = document.getElementById('tradingModal');
        if (modal) {
            modal.style.display = 'flex';
        }
    }

    closeTradingModal() {
        console.log('Closing Trading Modal');
        const modal = document.getElementById('tradingModal');
        if (modal) {
            modal.style.display = 'none';
        }
    }

    selectModalToken(tokenType) {
        console.log(`Selecting Token Type: ${tokenType}`);

        this.selectedTokenType = tokenType;

        // Update button states
        document.querySelectorAll('.modal-token-btn').forEach(btn => {
            btn.classList.remove('active');
        });

        // Find and activate the clicked button
        const clickedBtn = event.target;
        if (clickedBtn) {
            clickedBtn.classList.add('active');
        }

        // Update available balance
        const balanceField = document.getElementById('availableBalance');
        if (balanceField) {
            const balance = tokenType === 'PT' ? this.stakingData.ptTokens : this.stakingData.ytTokens;
            balanceField.value = `${balance.toFixed(2)} ${tokenType}`;
        }

        // Reset other fields
        const sellAmountField = document.getElementById('sellAmount');
        const estimatedReceiveField = document.getElementById('estimatedReceive');

        if (sellAmountField) sellAmountField.value = '';
        if (estimatedReceiveField) estimatedReceiveField.value = '0.00 APT';
    }

    async confirmTrade() {
        console.log('Confirming Trade Transaction');

        try {
            // 1. Validate input
            const sellAmountField = document.getElementById('sellAmount');
            if (!sellAmountField) {
                throw new Error('Sell amount field not found');
            }

            const amount = parseFloat(sellAmountField.value);
            if (!amount || amount <= 0) {
                throw new Error('Please enter a valid amount to trade');
            }

            // 2. Check available balance
            const availableBalance = this.selectedTokenType === 'PT' ?
                this.stakingData.ptTokens : this.stakingData.ytTokens;

            if (amount > availableBalance) {
                throw new Error(`Insufficient ${this.selectedTokenType} balance. Available: ${availableBalance}`);
            }

            // 3. Check wallet connection
            if (!this.walletManager || !this.walletManager.isConnected()) {
                throw new Error('Please connect your wallet first');
            }

            // 4. Create trading transaction
            const transaction = {
                type: 'trade',
                sellToken: this.selectedTokenType,
                sellAmount: amount,
                timestamp: Date.now(),
                user: this.walletManager.getConnectedWallet().address
            };

            console.log('Trading Transaction:', transaction);

            // 5. Submit transaction
            const result = await this.submitTradingTransaction(transaction);

            // 6. Update balances and close modal
            if (result.success) {
                this.updateTokenBalances(this.selectedTokenType, amount);
                this.closeTradingModal();
                
                const message = `Successfully traded ${amount} ${this.selectedTokenType} for ${result.receiveAmount.toFixed(4)} ${result.receiveToken}!\n\n${result.message}`;
                this.showSuccessMessage(message, result.explorerUrl);
            } else {
                throw new Error(result.error || 'Transaction failed');
            }

        } catch (error) {
            console.error('Trading error:', error);
            this.showErrorMessage(`Trade failed: ${error.message}`);
        }
    }

    async submitTradingTransaction(transaction) {
        console.log('🔄 Processing Trading Transaction');
        
        try {
            // Check wallet connection
            if (!this.walletManager || !this.walletManager.isConnected()) {
                throw new Error('Please connect your wallet first');
            }

            const { sellToken, sellAmount } = transaction;
            
            console.log(`💱 Trading ${sellAmount} ${sellToken} tokens...`);
            
            // Calculate receive amount based on token type
            let receiveAmount = 0;
            if (sellToken === 'PT') {
                // PT tokens are approximately 1:1 with APT (principal value)
                receiveAmount = sellAmount * 0.98; // 2% trading fee
            } else if (sellToken === 'YT') {
                // YT tokens represent yield, worth less than PT
                receiveAmount = sellAmount * 0.12; // ~12% of principal (yield component)
            }
            
            console.log(`✅ Trade calculated: ${sellAmount} ${sellToken} → ${receiveAmount.toFixed(4)} APT`);
            
            // Note: Full AMM integration requires deployed PT/YT AMM contracts
            // For now, this updates local balances
            // TODO: Integrate with pt_yt_amm_real.move when pools are created
            
            return {
                success: true,
                sellToken: sellToken,
                sellAmount: sellAmount,
                receiveToken: 'APT',
                receiveAmount: receiveAmount,
                message: 'Trade completed! (Note: Full AMM integration coming soon with liquidity pools)'
            };
            
        } catch (error) {
            console.error('❌ Trading transaction failed:', error);
            throw error;
        }
    }

    updateTokenBalances(tokenType, soldAmount) {
        console.log(`Updating Token Balances: Sold ${soldAmount} ${tokenType}`);

        if (tokenType === 'PT') {
            this.stakingData.ptTokens -= soldAmount;
        } else {
            this.stakingData.ytTokens -= soldAmount;
        }

        // Update display
        this.updateTokenPortfolio();

        // Update local storage
        localStorage.setItem('tesserapt_staking', JSON.stringify(this.stakingData));
    }

    // ==========================================
    // LENDING FUNCTIONS
    // ==========================================

    openLendingModal() {
        console.log('Opening Lending Modal');
        const modal = document.getElementById('lendingModal');
        if (modal) {
            modal.style.display = 'flex';
        }
    }

    closeLendingModal() {
        console.log('Closing Lending Modal');
        const modal = document.getElementById('lendingModal');
        if (modal) {
            modal.style.display = 'none';
        }
    }

    selectLoanDuration(months, amount) {
        console.log(`Selecting Loan Duration: ${months} months, $${amount}`);

        this.selectedLoanDuration = months;
        this.selectedLoanAmount = amount;

        // Update button states
        document.querySelectorAll('.time-option').forEach(option => {
            option.classList.remove('active');
        });

        // Activate clicked option
        if (event && event.target) {
            event.target.classList.add('active');
        }

        // Update loan details
        const amountEl = document.getElementById('selectedLoanAmount');
        const durationEl = document.getElementById('selectedDuration');
        const paymentEl = document.getElementById('monthlyPayment');

        if (amountEl) {
            amountEl.textContent = `$${amount.toLocaleString()}`;
        }

        if (durationEl) {
            const durationText = months >= 12 ?
                `${Math.floor(months / 12)} Year${Math.floor(months / 12) > 1 ? 's' : ''}${months % 12 > 0 ? ` ${months % 12} Months` : ''}` :
                `${months} Months`;
            durationEl.textContent = durationText;
        }

        if (paymentEl) {
            const monthlyPayment = this.calculateMonthlyPayment(amount, months);
            paymentEl.textContent = `$${Math.round(monthlyPayment).toLocaleString()}`;
        }
    }

    calculateMonthlyPayment(principal, months) {
        const annualRate = 0.045; // 4.5% APR
        const monthlyRate = annualRate / 12;
        const monthlyPayment = (principal * monthlyRate * Math.pow(1 + monthlyRate, months)) /
            (Math.pow(1 + monthlyRate, months) - 1);
        return monthlyPayment;
    }

    async confirmLoan() {
        console.log('Confirming Loan Application');

        try {
            // 1. Check wallet connection
            if (!this.walletManager || !this.walletManager.isConnected()) {
                throw new Error('Please connect your wallet first');
            }

            // 2. Validate collateral (mock BTC balance check)
            const btcBalance = await this.getBTCBalance();
            if (btcBalance < 2.5) {
                throw new Error('Insufficient BTC collateral. Required: 2.5 BTC');
            }

            // 3. Create loan transaction
            const transaction = {
                type: 'loan',
                amount: this.selectedLoanAmount,
                duration: this.selectedLoanDuration,
                collateral: 2.5, // BTC amount
                interestRate: 0.045, // 4.5% APR
                timestamp: Date.now(),
                user: this.walletManager.getConnectedWallet().address
            };

            console.log('Loan Transaction:', transaction);

            // 4. Submit transaction
            const result = await this.submitLoanTransaction(transaction);

            // 5. Update UI and close modal
            if (result.success) {
                this.updateLoanData(this.selectedLoanAmount, this.selectedLoanDuration);
                this.closeLendingModal();
                this.showSuccessMessage(`Loan approved! $${this.selectedLoanAmount.toLocaleString()} has been transferred to your wallet.`);
            } else {
                throw new Error(result.error || 'Loan application failed');
            }

        } catch (error) {
            console.error('Loan error:', error);
            this.showErrorMessage(`Loan failed: ${error.message}`);
        }
    }

    async submitLoanTransaction(transaction) {
        console.log('⚠️ Lending feature not yet implemented');
        
        // Lending will be implemented in Phase 5 with lending smart contracts
        throw new Error('Lending feature coming soon! This will use real lending smart contracts with PT/YT collateral.');
    }

    updateLoanData(amount, duration) {
        console.log(`Updating Loan Data: $${amount} for ${duration} months`);

        const loanData = {
            amount: amount,
            duration: duration,
            monthlyPayment: this.calculateMonthlyPayment(amount, duration),
            startDate: Date.now(),
            status: 'active'
        };

        // Store loan data
        localStorage.setItem('tesserapt_loan', JSON.stringify(loanData));
    }

    // ==========================================
    // MODAL FUNCTIONS
    // ==========================================

    openAboutModal() {
        console.log('Opening About Modal');
        const modal = document.getElementById('aboutModal');
        if (modal) {
            modal.style.display = 'flex';
        }
    }

    closeAboutModal() {
        console.log('Closing About Modal');
        const modal = document.getElementById('aboutModal');
        if (modal) {
            modal.style.display = 'none';
        }
    }

    // ==========================================
    // UTILITY FUNCTIONS
    // ==========================================

    async getTokenBalance(token) {
        console.log(`Getting ${token} balance from blockchain`);

        if (!this.walletManager || !this.walletManager.isConnected()) {
            console.log('Wallet not connected');
            return 0;
        }

        try {
            const userAddress = this.walletManager.walletAddress;

            if (token === 'APT') {
                // Get real APT balance from blockchain
                if (this.aptosClient && this.aptosClient.isInitialized) {
                    const balance = await this.aptosClient.getAccountBalance(userAddress);
                    console.log(`✅ Real APT balance: ${balance}`);
                    return balance;
                }
            } else if (token === 'stAPT') {
                // Get real stAPT balance from blockchain
                if (this.stakingContract) {
                    const balance = await this.stakingContract.getStAPTBalance(userAddress);
                    console.log(`✅ Real stAPT balance: ${balance}`);
                    return balance;
                }
            } else if (token === 'BTC') {
                // BTC is not on Aptos blockchain - this would need a bridge
                console.log('⚠️ BTC balance not available on Aptos');
                return 0;
            }

            return 0;
        } catch (error) {
            console.error(`❌ Failed to get ${token} balance:`, error);
            return 0;
        }
    }

    async getBTCBalance() {
        // BTC is not on Aptos blockchain
        // This would require a bridge integration in the future
        console.log('⚠️ BTC balance checking not available on Aptos');
        return 0;
    }

    getTokenPrice(token) {
        // Use price oracle if available, otherwise fallback to mock prices
        if (this.priceOracle) {
            const price = this.priceOracle.getPrice(token);
            if (price) return price;
        }

        // Fallback mock prices
        const mockPrices = {
            'APT': 25,
            'BTC': 50000,
            'ETH': 3000,
            'USDC': 1.00,
            'USDT': 1.00
        };
        return mockPrices[token] || 0;
    }

    getMarketData(token) {
        if (this.priceOracle) {
            return this.priceOracle.getMarketData(token);
        }
        return null;
    }

    initializeWalletManager() {
        // Initialize wallet manager when available
        if (typeof walletManager !== 'undefined') {
            this.walletManager = walletManager;
            console.log('✅ Wallet Manager initialized');
        } else {
            console.log('⏳ Wallet Manager not available yet');
        }
    }

    initializePriceOracle() {
        // Initialize price oracle when available
        if (typeof priceOracle !== 'undefined') {
            this.priceOracle = priceOracle;
            console.log('✅ Price Oracle initialized');
        } else {
            console.log('⏳ Price Oracle not available yet');
            // Retry after a short delay
            setTimeout(() => {
                if (typeof priceOracle !== 'undefined') {
                    this.priceOracle = priceOracle;
                    this.setupPriceSubscriptions();
                    console.log('✅ Price Oracle initialized (delayed)');
                }
            }, 1000);
        }
    }

    initializeAptosClient() {
        // Initialize Aptos client and staking contract when available
        if (typeof aptosClient !== 'undefined') {
            this.aptosClient = aptosClient;
            console.log('✅ Aptos Client initialized');
            this.initializeStakingContract();
        } else {
            console.log('⏳ Aptos Client not available yet');
            // Retry after a short delay
            setTimeout(() => {
                if (typeof aptosClient !== 'undefined') {
                    this.aptosClient = aptosClient;
                    this.initializeStakingContract();
                    console.log('✅ Aptos Client initialized (delayed)');
                }
            }, 2000);
        }
    }

    initializeStakingContract() {
        // Wait for both Aptos client and wallet manager to be ready
        if (this.aptosClient && this.aptosClient.isInitialized && this.walletManager) {
            this.stakingContract = new TesseraptStakingContract(this.aptosClient, this.walletManager);
            console.log('✅ Staking Contract initialized');
            
            // Also initialize AMM contract
            this.initializeAMMContract();
        } else {
            console.log('⏳ Waiting for Aptos client and wallet manager...');
            setTimeout(() => {
                this.initializeStakingContract();
            }, 1000);
        }
    }

    initializeAMMContract() {
        if (typeof TesseraptAMMContract !== 'undefined') {
            this.ammContract = new TesseraptAMMContract(this.aptosClient, this.walletManager);
            console.log('✅ AMM Contract initialized');
        } else {
            console.log('⏳ AMM Contract not available yet');
            setTimeout(() => {
                this.initializeAMMContract();
            }, 1000);
        }
    }

    setupPriceSubscriptions() {
        if (!this.priceOracle) return;

        console.log('📡 Setting up price subscriptions');

        // Subscribe to APT price updates
        const aptUnsubscribe = this.priceOracle.subscribe('APT', (token, priceData) => {
            this.updateMarketDisplay('APT', priceData);
        });
        this.priceSubscriptions.set('APT', aptUnsubscribe);

        // Subscribe to BTC price updates
        const btcUnsubscribe = this.priceOracle.subscribe('BTC', (token, priceData) => {
            this.updateMarketDisplay('BTC', priceData);
        });
        this.priceSubscriptions.set('BTC', btcUnsubscribe);

        console.log('✅ Price subscriptions established');
    }

    updateMarketDisplay(token, priceData) {
        console.log(`📊 Updating ${token} market display:`, priceData);

        // Update yield section market data
        this.updateYieldMarketData(token, priceData);

        // Update trading section market data
        this.updateTradingMarketData(token, priceData);

        // Update lending section market data
        this.updateLendingMarketData(token, priceData);

        // Store market data
        this.marketData.set(token, priceData);
    }

    updateYieldMarketData(token, priceData) {
        // Update yield section stats if visible
        const yieldSection = document.querySelector('.yield-section');
        if (!yieldSection || yieldSection.style.display === 'none') return;

        if (token === 'APT') {
            // Update current APY based on market conditions
            const baseAPY = 12.5;
            const volatilityBonus = Math.abs(priceData.change24h) * 0.1; // Add volatility bonus
            const currentAPY = baseAPY + volatilityBonus;

            // Update APY display
            const apyElements = document.querySelectorAll('.stat-value');
            if (apyElements[0]) {
                apyElements[0].textContent = `${currentAPY.toFixed(1)}%`;
            }
        }
    }

    updateTradingMarketData(token, priceData) {
        // Update trading section market data if visible
        const tradingSection = document.querySelector('.trading-section');
        if (!tradingSection || tradingSection.style.display === 'none') return;

        const marketDataElements = document.querySelectorAll('.data-item');

        if (token === 'APT') {
            // Update APT price
            if (marketDataElements[0]) {
                const priceElement = marketDataElements[0].querySelector('.data-value');
                if (priceElement) {
                    priceElement.textContent = `$${priceData.price.toFixed(2)}`;
                }
            }

            // Update 24h change
            if (marketDataElements[1]) {
                const changeElement = marketDataElements[1].querySelector('.data-value');
                if (changeElement) {
                    const isPositive = priceData.change24h >= 0;
                    changeElement.textContent = `${isPositive ? '+' : ''}${priceData.change24h.toFixed(2)}%`;
                    changeElement.className = `data-value ${isPositive ? 'positive' : 'negative'}`;
                }
            }
        }
    }

    updateLendingMarketData(token, priceData) {
        // Update lending section market data if visible
        const lendingSection = document.querySelector('.lending-section');
        if (!lendingSection || lendingSection.style.display === 'none') return;

        if (token === 'BTC') {
            // Update BTC price in lending sidebar
            const btcPriceElement = document.querySelector('.lending-stats .data-item .data-value');
            if (btcPriceElement) {
                btcPriceElement.textContent = `$${priceData.price.toLocaleString()}`;
            }

            // Update 24h change
            const changeElements = document.querySelectorAll('.lending-stats .data-item .data-value');
            if (changeElements[1]) {
                const isPositive = priceData.change24h >= 0;
                changeElements[1].textContent = `${isPositive ? '+' : ''}${priceData.change24h.toFixed(2)}%`;
                changeElements[1].className = `data-value ${isPositive ? 'positive' : 'negative'}`;
            }
        }
    }

    setupEventListeners() {
        console.log('Setting up Event Listeners');

        // Wait for DOM to be ready
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', () => this.bindEvents());
        } else {
            this.bindEvents();
        }
    }

    bindEvents() {
        // Staking button
        const stakeBtn = document.querySelector('.action-btn');
        if (stakeBtn) {
            stakeBtn.addEventListener('click', () => this.handleStaking());
        }

        // Amount input real-time calculation
        const sellAmountField = document.getElementById('sellAmount');
        const estimatedReceiveField = document.getElementById('estimatedReceive');

        if (sellAmountField && estimatedReceiveField) {
            sellAmountField.addEventListener('input', () => {
                const amount = parseFloat(sellAmountField.value) || 0;
                let estimated = 0;

                if (this.selectedTokenType === 'PT') {
                    estimated = amount; // PT tokens are 1:1 with APT
                } else {
                    estimated = amount * 0.125; // YT tokens are worth 12.5% of APT
                }

                estimatedReceiveField.value = `${estimated.toFixed(2)} APT`;
            });
        }

        // Load saved staking data
        this.loadSavedData();
    }

    loadSavedData() {
        // Load staking data from localStorage
        const savedStaking = localStorage.getItem('tesserapt_staking');
        if (savedStaking) {
            try {
                this.stakingData = JSON.parse(savedStaking);
                console.log('Loaded saved staking data:', this.stakingData);
            } catch (error) {
                console.error('Error loading saved staking data:', error);
            }
        }
    }

    showSuccessMessage(message, explorerUrl = null) {
        console.log('✅ Success:', message);

        let fullMessage = message;
        if (explorerUrl) {
            fullMessage += `\n\nView transaction: ${explorerUrl}`;
        }

        alert(fullMessage); // Replace with better notification system

        // Hide loading state
        this.hideLoadingState();
    }

    showErrorMessage(message) {
        console.error('Error:', message);
        alert(message); // Replace with better notification system
    }

    delay(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
}

// Initialize the platform
let tesseraptPlatform;

document.addEventListener('DOMContentLoaded', function () {
    tesseraptPlatform = new TesseraptPlatform();

    // Expose global functions for HTML onclick handlers
    window.showYieldSection = () => tesseraptPlatform.showYieldSection();
    window.showTradingSection = () => tesseraptPlatform.showTradingSection();
    window.showLendingSection = () => tesseraptPlatform.showLendingSection();
    window.showMainSections = () => tesseraptPlatform.showMainSections();

    window.openTradingModal = () => tesseraptPlatform.openTradingModal();
    window.closeTradingModal = () => tesseraptPlatform.closeTradingModal();
    window.selectModalToken = (tokenType) => tesseraptPlatform.selectModalToken(tokenType);
    window.confirmTrade = () => tesseraptPlatform.confirmTrade();

    window.openLendingModal = () => tesseraptPlatform.openLendingModal();
    window.closeLendingModal = () => tesseraptPlatform.closeLendingModal();
    window.selectLoanDuration = (months, amount) => tesseraptPlatform.selectLoanDuration(months, amount);
    window.confirmLoan = () => tesseraptPlatform.confirmLoan();

    window.openAboutModal = () => tesseraptPlatform.openAboutModal();
    window.closeAboutModal = () => tesseraptPlatform.closeAboutModal();

    console.log('TESSERAPT Platform initialized successfully');
});

// Export for module usage
if (typeof module !== 'undefined' && module.exports) {
    module.exports = TesseraptPlatform;
}