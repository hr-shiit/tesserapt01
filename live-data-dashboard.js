// TESSERAPT Live Market Data Dashboard
// Real-time updates from blockchain and price APIs

class LiveDataDashboard {
    constructor(aptosClient, priceOracle, stakingContract, walletManager) {
        this.client = aptosClient;
        this.priceOracle = priceOracle;
        this.stakingContract = stakingContract;
        this.wallet = walletManager;

        this.updateInterval = 10000; // Update every 10 seconds
        this.intervalId = null;

        this.data = {
            aptPrice: 0,
            aptChange24h: 0,
            currentYield: 9.5,
            ptAptRate: 1.00,
            ytAptRate: 0.125,
            totalStaked: 0,
            earnedYield: 0,
            portfolioValue: 0,
            userStaked: 0,
            userStAPT: 0
        };

        console.log('📊 Live Data Dashboard initialized');
    }

    // Start live updates
    start() {
        if (this.intervalId) {
            console.log('⚠️ Dashboard already running');
            return;
        }

        console.log('🚀 Starting live data updates...');

        // Initial update
        this.updateAllData();

        // Set up interval for continuous updates
        this.intervalId = setInterval(() => {
            this.updateAllData();
        }, this.updateInterval);
    }

    // Stop live updates
    stop() {
        if (this.intervalId) {
            clearInterval(this.intervalId);
            this.intervalId = null;
            console.log('🛑 Live data updates stopped');
        }
    }

    // Update all data from various sources
    async updateAllData() {
        console.log('🔄 Updating live data...');

        try {
            // Update in parallel for speed
            await Promise.all([
                this.updatePriceData(),
                this.updateStakingData(),
                this.updateUserData()
            ]);

            // Calculate derived values
            this.calculateDerivedData();

            // Update UI
            this.updateUI();

            console.log('✅ Live data updated:', this.data);

        } catch (error) {
            console.error('❌ Failed to update live data:', error);
        }
    }

    // Update price data from CoinGecko
    async updatePriceData() {
        try {
            if (this.priceOracle) {
                const aptPrice = this.priceOracle.getPrice('APT');
                const aptChange = this.priceOracle.getPriceChange('APT');

                if (aptPrice > 0) {
                    this.data.aptPrice = aptPrice;
                    this.data.aptChange24h = aptChange;
                }
            }
        } catch (error) {
            console.error('❌ Failed to update price data:', error);
        }
    }

    // Update staking data from blockchain
    async updateStakingData() {
        try {
            if (this.stakingContract && this.client && this.client.isInitialized) {
                // Get total staked from contract
                const totalStaked = await this.stakingContract.getTotalStaked();
                if (totalStaked > 0) {
                    this.data.totalStaked = totalStaked;
                }

                // Get current APY
                const apy = await this.stakingContract.getCurrentAPY();
                if (apy > 0) {
                    this.data.currentYield = apy;
                }

                // Get exchange rate
                const exchangeRate = await this.stakingContract.getExchangeRate();
                if (exchangeRate > 0) {
                    this.data.ptAptRate = exchangeRate;
                }
            }
        } catch (error) {
            console.error('❌ Failed to update staking data:', error);
        }
    }

    // Update user-specific data
    async updateUserData() {
        try {
            if (this.wallet && this.wallet.isConnected() && this.stakingContract) {
                const userAddress = this.wallet.walletAddress;

                // Get user's staking stats
                const stats = await this.stakingContract.getStakingStats(userAddress);

                if (stats) {
                    this.data.userStaked = stats.user.aptBalance || 0;
                    this.data.userStAPT = stats.user.staptBalance || 0;

                    // Calculate earned yield (stAPT value - original stake)
                    const staptValue = stats.user.staptValue || 0;
                    this.data.earnedYield = Math.max(0, staptValue - this.data.userStaked);
                }
            }
        } catch (error) {
            console.error('❌ Failed to update user data:', error);
        }
    }

    // Calculate derived data
    calculateDerivedData() {
        // Calculate portfolio value
        if (this.data.userStAPT > 0 && this.data.aptPrice > 0) {
            const staptValue = this.data.userStAPT * this.data.ptAptRate;
            this.data.portfolioValue = staptValue * this.data.aptPrice;
        }

        // YT/APT rate is typically yield component (12.5% of principal)
        this.data.ytAptRate = 0.125;
    }

    // Update UI elements
    updateUI() {
        // APT Price
        this.updateElement('apt-price', `$${this.data.aptPrice.toFixed(2)}`);

        // 24h Change
        const changeClass = this.data.aptChange24h >= 0 ? 'positive' : 'negative';
        const changeSign = this.data.aptChange24h >= 0 ? '+' : '';
        this.updateElement('apt-change', `${changeSign}${this.data.aptChange24h.toFixed(2)}%`, changeClass);

        // Current Yield (match format with main page)
        this.updateElement('current-yield', `~${this.data.currentYield.toFixed(1)}%`);

        // PT/APT Rate
        this.updateElement('pt-apt-rate', this.data.ptAptRate.toFixed(3));

        // YT/APT Rate
        this.updateElement('yt-apt-rate', this.data.ytAptRate.toFixed(3));

        // Total Staked
        this.updateElement('total-staked', `${this.data.totalStaked.toFixed(2)} APT`);

        // Earned Yield
        this.updateElement('earned-yield', `${this.data.earnedYield.toFixed(2)} APT`, 'positive');

        // Portfolio Value
        this.updateElement('portfolio-value', `$${this.data.portfolioValue.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`);

        // Update main page stake section cards
        this.updateElement('stake-apy', `~${this.data.currentYield.toFixed(1)}%`);
        this.updateElement('stake-apt-price', `$${this.data.aptPrice.toFixed(2)}`);
        this.updateElement('stake-apt-change', `${changeSign}${this.data.aptChange24h.toFixed(2)}%`);
        this.updateElement('stake-total-staked', `${this.data.totalStaked.toFixed(2)} APT`);

        // Calculate and update TVL (Total Value Locked)
        const tvl = this.data.totalStaked * this.data.aptPrice;
        this.updateElement('stake-tvl', `$${tvl.toLocaleString('en-US', { minimumFractionDigits: 0, maximumFractionDigits: 0 })}`);

        // Color code the 24h change on main page
        const changeElement = document.getElementById('stake-apt-change');
        if (changeElement) {
            changeElement.style.color = this.data.aptChange24h >= 0 ? '#00ff88' : '#ff4444';
        }

        // Update lending section cards
        this.updateLendingCards();

        // Update market sidebar APT price and change
        this.updateElement('market-apt-price', `$${this.data.aptPrice.toFixed(2)}`);
        const marketChangeClass = this.data.aptChange24h >= 0 ? 'positive' : 'negative';
        const marketChangeSign = this.data.aptChange24h >= 0 ? '+' : '';
        this.updateElement('market-apt-change', `${marketChangeSign}${this.data.aptChange24h.toFixed(2)}%`, marketChangeClass);
        
        // Update market sidebar staking data
        this.updateElement('market-total-staked', `${this.data.totalStaked.toFixed(2)} APT`);
        this.updateElement('market-earned-yield', `${this.data.earnedYield.toFixed(2)} APT`, 'positive');
        this.updateElement('market-portfolio-value', `$${this.data.portfolioValue.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`);
    }

    // Update lending section data cards
    updateLendingCards() {
        // Lending rate (fixed for now, will be dynamic when lending is implemented)
        this.updateElement('lending-rate', '4.5%');

        // Max LTV (Loan-to-Value ratio)
        this.updateElement('lending-ltv', '75%');

        // Calculate available liquidity (based on total staked)
        const availableLiquidity = this.data.totalStaked * this.data.aptPrice * 0.5; // 50% of TVL available
        this.updateElement('lending-available', `$${availableLiquidity.toLocaleString('en-US', { minimumFractionDigits: 0, maximumFractionDigits: 0 })}`);

        // Total borrowed (will be real when lending is implemented)
        const totalBorrowed = availableLiquidity * 0.3; // Assume 30% utilization
        this.updateElement('lending-borrowed', `$${totalBorrowed.toLocaleString('en-US', { minimumFractionDigits: 0, maximumFractionDigits: 0 })}`);

        // Collateral type (static)
        this.updateElement('lending-collateral', 'PT/YT');
    }

    // Helper to update DOM element
    updateElement(id, value, className = '') {
        const element = document.getElementById(id);
        if (element) {
            element.textContent = value;
            if (className) {
                element.className = className;
            }
        }
    }

    // Get current data snapshot
    getData() {
        return { ...this.data };
    }

    // Manual refresh
    async refresh() {
        console.log('🔄 Manual refresh triggered');
        await this.updateAllData();
    }
}

// Initialize dashboard when dependencies are ready
let liveDataDashboard = null;

function initializeLiveDataDashboard() {
    if (typeof aptosClient !== 'undefined' &&
        typeof priceOracle !== 'undefined' &&
        typeof TesseraptStakingContract !== 'undefined' &&
        typeof walletManager !== 'undefined') {

        // Wait for staking contract to be initialized
        if (window.tesseraptPlatform && window.tesseraptPlatform.stakingContract) {
            liveDataDashboard = new LiveDataDashboard(
                aptosClient,
                priceOracle,
                window.tesseraptPlatform.stakingContract,
                walletManager
            );

            // Start live updates
            liveDataDashboard.start();

            console.log('✅ Live Data Dashboard started');

            // Expose globally
            window.liveDataDashboard = liveDataDashboard;
        } else {
            // Retry after delay
            setTimeout(initializeLiveDataDashboard, 2000);
        }
    } else {
        // Retry after delay
        setTimeout(initializeLiveDataDashboard, 2000);
    }
}

// Auto-initialize when page loads
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initializeLiveDataDashboard);
} else {
    initializeLiveDataDashboard();
}

// Export for module usage
if (typeof module !== 'undefined' && module.exports) {
    module.exports = LiveDataDashboard;
}
