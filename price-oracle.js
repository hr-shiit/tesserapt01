// TESSERAPT Price Oracle System
// Comprehensive price feed management with multiple data sources

class TesseraptPriceOracle {
    constructor() {
        this.prices = new Map();
        this.priceHistory = new Map();
        this.subscribers = new Map();
        this.updateInterval = 30000; // 30 seconds
        this.maxRetries = 3;
        this.fallbackPrices = new Map();

        // Supported tokens
        this.supportedTokens = ['APT', 'BTC', 'ETH', 'USDC', 'USDT'];

        // Price sources configuration
        this.priceSources = {
            primary: 'coingecko',
            fallback: ['coinmarketcap', 'binance', 'mock']
        };

        this.init();
    }

    async init() {
        console.log('🔮 Initializing TESSERAPT Price Oracle System');

        // Initialize fallback prices
        this.initializeFallbackPrices();

        // Start price updates
        await this.updateAllPrices();
        this.startPriceUpdates();

        console.log('✅ Price Oracle System initialized successfully');
    }

    // ==========================================
    // PRICE FETCHING METHODS
    // ==========================================

    async updateAllPrices() {
        console.log('📊 Updating all token prices');

        const updatePromises = this.supportedTokens.map(token =>
            this.updateTokenPrice(token)
        );

        try {
            await Promise.allSettled(updatePromises);
            this.notifySubscribers('all');
        } catch (error) {
            console.error('Error updating prices:', error);
        }
    }

    async updateTokenPrice(token) {
        console.log(`📈 Updating price for ${token}`);

        let price = null;
        let source = null;

        // Try primary source first
        try {
            price = await this.fetchFromCoingecko(token);
            source = 'coingecko';
        } catch (error) {
            console.warn(`Primary source failed for ${token}:`, error.message);
        }

        // Try fallback sources if primary fails
        if (!price) {
            for (const fallbackSource of this.priceSources.fallback) {
                try {
                    switch (fallbackSource) {
                        case 'coinmarketcap':
                            price = await this.fetchFromCoinMarketCap(token);
                            break;
                        case 'binance':
                            price = await this.fetchFromBinance(token);
                            break;
                        case 'mock':
                            price = await this.fetchMockPrice(token);
                            break;
                    }

                    if (price) {
                        source = fallbackSource;
                        break;
                    }
                } catch (error) {
                    console.warn(`Fallback source ${fallbackSource} failed for ${token}:`, error.message);
                }
            }
        }

        // Use cached price if all sources fail
        if (!price) {
            price = this.fallbackPrices.get(token);
            source = 'cached';
            console.warn(`Using cached price for ${token}: $${price}`);
        }

        if (price) {
            this.updatePriceData(token, price, source);
        }

        return price;
    }

    async fetchFromCoingecko(token) {
        const tokenIds = {
            'APT': 'aptos',
            'BTC': 'bitcoin',
            'ETH': 'ethereum',
            'USDC': 'usd-coin',
            'USDT': 'tether'
        };

        const tokenId = tokenIds[token];
        if (!tokenId) {
            throw new Error(`Token ${token} not supported by CoinGecko`);
        }

        const url = `https://api.coingecko.com/api/v3/simple/price?ids=${tokenId}&vs_currencies=usd&include_24hr_change=true`;

        const response = await this.fetchWithTimeout(url, 5000);
        const data = await response.json();

        if (!data[tokenId] || !data[tokenId].usd) {
            throw new Error(`Invalid response from CoinGecko for ${token}`);
        }

        return {
            price: data[tokenId].usd,
            change24h: data[tokenId].usd_24h_change || 0,
            timestamp: Date.now(),
            source: 'coingecko'
        };
    }

    async fetchFromCoinMarketCap(token) {
        // Note: Requires API key for production use
        console.log(`Fetching ${token} from CoinMarketCap (mock implementation)`);

        // Mock implementation - replace with actual CMC API
        const mockPrices = {
            'APT': { price: 25.50, change24h: 2.5 },
            'BTC': { price: 50000, change24h: 1.2 },
            'ETH': { price: 3000, change24h: -0.8 },
            'USDC': { price: 1.00, change24h: 0.01 },
            'USDT': { price: 1.00, change24h: -0.01 }
        };

        const mockData = mockPrices[token];
        if (!mockData) {
            throw new Error(`Token ${token} not found in CoinMarketCap mock data`);
        }

        return {
            price: mockData.price,
            change24h: mockData.change24h,
            timestamp: Date.now(),
            source: 'coinmarketcap'
        };
    }

    async fetchFromBinance(token) {
        const symbolMap = {
            'APT': 'APTUSDT',
            'BTC': 'BTCUSDT',
            'ETH': 'ETHUSDT',
            'USDC': 'USDCUSDT',
            'USDT': 'USDTUSDT'
        };

        const symbol = symbolMap[token];
        if (!symbol) {
            throw new Error(`Token ${token} not supported by Binance`);
        }

        const url = `https://api.binance.com/api/v3/ticker/24hr?symbol=${symbol}`;

        const response = await this.fetchWithTimeout(url, 5000);
        const data = await response.json();

        if (!data.lastPrice) {
            throw new Error(`Invalid response from Binance for ${token}`);
        }

        return {
            price: parseFloat(data.lastPrice),
            change24h: parseFloat(data.priceChangePercent),
            timestamp: Date.now(),
            source: 'binance'
        };
    }

    async fetchMockPrice(token) {
        console.log(`Generating mock price for ${token}`);

        // Generate realistic mock prices with some volatility
        const basePrices = {
            'APT': 25.00,
            'BTC': 50000,
            'ETH': 3000,
            'USDC': 1.00,
            'USDT': 1.00
        };

        const basePrice = basePrices[token];
        if (!basePrice) {
            throw new Error(`No mock price available for ${token}`);
        }

        // Add some random volatility (±5%)
        const volatility = (Math.random() - 0.5) * 0.1; // ±5%
        const price = basePrice * (1 + volatility);
        const change24h = (Math.random() - 0.5) * 10; // ±5% daily change

        return {
            price: parseFloat(price.toFixed(token === 'BTC' ? 0 : 2)),
            change24h: parseFloat(change24h.toFixed(2)),
            timestamp: Date.now(),
            source: 'mock'
        };
    }

    updatePriceData(token, priceData, source) {
        const timestamp = Date.now();

        // Update current price
        this.prices.set(token, {
            ...priceData,
            timestamp,
            source
        });

        // Update price history
        if (!this.priceHistory.has(token)) {
            this.priceHistory.set(token, []);
        }

        const history = this.priceHistory.get(token);
        history.push({
            price: priceData.price,
            timestamp,
            source
        });

        // Keep only last 100 price points
        if (history.length > 100) {
            history.shift();
        }

        // Update fallback price
        this.fallbackPrices.set(token, priceData.price);

        console.log(`💰 ${token}: $${priceData.price} (${source}) ${priceData.change24h > 0 ? '📈' : '📉'} ${priceData.change24h.toFixed(2)}%`);
    }

    // ==========================================
    // PUBLIC API METHODS
    // ==========================================

    getPrice(token) {
        const priceData = this.prices.get(token.toUpperCase());
        return priceData ? priceData.price : null;
    }

    getPriceChange(token) {
        const priceData = this.prices.get(token.toUpperCase());
        return priceData ? priceData.change24h : 0;
    }

    getPriceData(token) {
        return this.prices.get(token.toUpperCase()) || null;
    }

    getAllPrices() {
        const allPrices = {};
        for (const [token, data] of this.prices) {
            allPrices[token] = data;
        }
        return allPrices;
    }

    getPriceHistory(token, limit = 50) {
        const history = this.priceHistory.get(token.toUpperCase());
        if (!history) return [];

        return history.slice(-limit);
    }

    getMarketData(token) {
        const priceData = this.getPriceData(token);
        if (!priceData) return null;

        const history = this.getPriceHistory(token, 24); // Last 24 data points

        let high24h = priceData.price;
        let low24h = priceData.price;

        history.forEach(point => {
            high24h = Math.max(high24h, point.price);
            low24h = Math.min(low24h, point.price);
        });

        return {
            price: priceData.price,
            change24h: priceData.change24h,
            high24h,
            low24h,
            timestamp: priceData.timestamp,
            source: priceData.source
        };
    }

    // ==========================================
    // SUBSCRIPTION SYSTEM
    // ==========================================

    subscribe(token, callback) {
        const tokenKey = token.toUpperCase();

        if (!this.subscribers.has(tokenKey)) {
            this.subscribers.set(tokenKey, new Set());
        }

        this.subscribers.get(tokenKey).add(callback);

        // Send current price immediately
        const currentPrice = this.getPriceData(tokenKey);
        if (currentPrice) {
            callback(tokenKey, currentPrice);
        }

        console.log(`📡 Subscribed to ${tokenKey} price updates`);

        // Return unsubscribe function
        return () => {
            this.unsubscribe(tokenKey, callback);
        };
    }

    unsubscribe(token, callback) {
        const tokenKey = token.toUpperCase();
        const subscribers = this.subscribers.get(tokenKey);

        if (subscribers) {
            subscribers.delete(callback);
            if (subscribers.size === 0) {
                this.subscribers.delete(tokenKey);
            }
        }

        console.log(`📡 Unsubscribed from ${tokenKey} price updates`);
    }

    notifySubscribers(token) {
        if (token === 'all') {
            // Notify all subscribers
            for (const [tokenKey, subscribers] of this.subscribers) {
                const priceData = this.getPriceData(tokenKey);
                if (priceData) {
                    subscribers.forEach(callback => {
                        try {
                            callback(tokenKey, priceData);
                        } catch (error) {
                            console.error(`Error in price callback for ${tokenKey}:`, error);
                        }
                    });
                }
            }
        } else {
            // Notify specific token subscribers
            const tokenKey = token.toUpperCase();
            const subscribers = this.subscribers.get(tokenKey);
            const priceData = this.getPriceData(tokenKey);

            if (subscribers && priceData) {
                subscribers.forEach(callback => {
                    try {
                        callback(tokenKey, priceData);
                    } catch (error) {
                        console.error(`Error in price callback for ${tokenKey}:`, error);
                    }
                });
            }
        }
    }

    // ==========================================
    // UTILITY METHODS
    // ==========================================

    startPriceUpdates() {
        console.log(`🔄 Starting price updates every ${this.updateInterval / 1000} seconds`);

        setInterval(() => {
            this.updateAllPrices();
        }, this.updateInterval);
    }

    initializeFallbackPrices() {
        // Set initial fallback prices
        this.fallbackPrices.set('APT', 25.00);
        this.fallbackPrices.set('BTC', 50000);
        this.fallbackPrices.set('ETH', 3000);
        this.fallbackPrices.set('USDC', 1.00);
        this.fallbackPrices.set('USDT', 1.00);
    }

    async fetchWithTimeout(url, timeout = 5000) {
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), timeout);

        try {
            const response = await fetch(url, {
                signal: controller.signal,
                headers: {
                    'Accept': 'application/json',
                    'User-Agent': 'TESSERAPT/1.0'
                }
            });

            clearTimeout(timeoutId);

            if (!response.ok) {
                throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }

            return response;
        } catch (error) {
            clearTimeout(timeoutId);
            throw error;
        }
    }

    // ==========================================
    // YIELD CALCULATION METHODS
    // ==========================================

    calculateYieldValue(principalAmount, token, yieldRate = 0.125) {
        const tokenPrice = this.getPrice(token);
        if (!tokenPrice) return 0;

        const yieldAmount = principalAmount * yieldRate;
        return yieldAmount * tokenPrice;
    }

    calculatePortfolioValue(portfolio) {
        let totalValue = 0;

        for (const [token, amount] of Object.entries(portfolio)) {
            const price = this.getPrice(token);
            if (price) {
                totalValue += amount * price;
            }
        }

        return totalValue;
    }

    // ==========================================
    // HEALTH CHECK METHODS
    // ==========================================

    getSystemHealth() {
        const now = Date.now();
        const health = {
            status: 'healthy',
            lastUpdate: null,
            stalePrices: [],
            activeSources: new Set(),
            totalSubscribers: 0
        };

        // Check price freshness
        for (const [token, priceData] of this.prices) {
            const age = now - priceData.timestamp;

            if (age > this.updateInterval * 2) {
                health.stalePrices.push({
                    token,
                    age: Math.floor(age / 1000),
                    lastUpdate: new Date(priceData.timestamp).toISOString()
                });
            }

            health.activeSources.add(priceData.source);

            if (!health.lastUpdate || priceData.timestamp > health.lastUpdate) {
                health.lastUpdate = priceData.timestamp;
            }
        }

        // Count subscribers
        for (const subscribers of this.subscribers.values()) {
            health.totalSubscribers += subscribers.size;
        }

        // Determine overall status
        if (health.stalePrices.length > 0) {
            health.status = 'degraded';
        }

        if (health.stalePrices.length >= this.supportedTokens.length / 2) {
            health.status = 'unhealthy';
        }

        health.activeSources = Array.from(health.activeSources);

        return health;
    }

    // ==========================================
    // DEBUGGING METHODS
    // ==========================================

    debugInfo() {
        console.log('🔍 TESSERAPT Price Oracle Debug Info:');
        console.log('Supported Tokens:', this.supportedTokens);
        console.log('Current Prices:', this.getAllPrices());
        console.log('Active Subscribers:', this.subscribers.size);
        console.log('System Health:', this.getSystemHealth());

        return {
            supportedTokens: this.supportedTokens,
            currentPrices: this.getAllPrices(),
            subscribers: this.subscribers.size,
            health: this.getSystemHealth()
        };
    }
}

// Initialize global price oracle
let priceOracle;

document.addEventListener('DOMContentLoaded', function () {
    priceOracle = new TesseraptPriceOracle();

    // Expose global methods
    window.priceOracle = priceOracle;

    console.log('🚀 TESSERAPT Price Oracle loaded and ready');
});

// Export for module usage
if (typeof module !== 'undefined' && module.exports) {
    module.exports = TesseraptPriceOracle;
}