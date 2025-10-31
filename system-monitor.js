// TESSERAPT System Health Monitor
// Comprehensive monitoring and diagnostics for the platform

class TesseraptSystemMonitor {
    constructor() {
        this.healthChecks = new Map();
        this.metrics = new Map();
        this.alerts = [];
        this.monitoringInterval = 60000; // 1 minute
        this.isMonitoring = false;

        this.init();
    }

    init() {
        console.log('🔍 Initializing TESSERAPT System Monitor');

        this.setupHealthChecks();
        this.startMonitoring();

        // Expose debug interface
        window.systemMonitor = this;

        console.log('✅ System Monitor initialized');
    }

    // ==========================================
    // HEALTH CHECK DEFINITIONS
    // ==========================================

    setupHealthChecks() {
        // Price Oracle Health Check
        this.healthChecks.set('priceOracle', {
            name: 'Price Oracle',
            check: () => this.checkPriceOracle(),
            critical: true,
            interval: 30000 // 30 seconds
        });

        // Wallet Manager Health Check
        this.healthChecks.set('walletManager', {
            name: 'Wallet Manager',
            check: () => this.checkWalletManager(),
            critical: false,
            interval: 60000 // 1 minute
        });

        // Platform Functions Health Check
        this.healthChecks.set('platformFunctions', {
            name: 'Platform Functions',
            check: () => this.checkPlatformFunctions(),
            critical: true,
            interval: 60000 // 1 minute
        });

        // API Connectivity Health Check
        this.healthChecks.set('apiConnectivity', {
            name: 'API Connectivity',
            check: () => this.checkAPIConnectivity(),
            critical: true,
            interval: 120000 // 2 minutes
        });

        // UI Responsiveness Health Check
        this.healthChecks.set('uiResponsiveness', {
            name: 'UI Responsiveness',
            check: () => this.checkUIResponsiveness(),
            critical: false,
            interval: 300000 // 5 minutes
        });
    }

    // ==========================================
    // INDIVIDUAL HEALTH CHECKS
    // ==========================================

    async checkPriceOracle() {
        const result = {
            status: 'healthy',
            details: {},
            timestamp: Date.now()
        };

        try {
            if (!window.priceOracle) {
                throw new Error('Price Oracle not initialized');
            }

            const health = window.priceOracle.getSystemHealth();
            result.details = health;

            if (health.status === 'unhealthy') {
                result.status = 'critical';
            } else if (health.status === 'degraded') {
                result.status = 'warning';
            }

            // Check price freshness
            const aptPrice = window.priceOracle.getPriceData('APT');
            if (!aptPrice || Date.now() - aptPrice.timestamp > 120000) {
                result.status = 'warning';
                result.details.stalePrices = true;
            }

        } catch (error) {
            result.status = 'critical';
            result.details.error = error.message;
        }

        return result;
    }

    async checkWalletManager() {
        const result = {
            status: 'healthy',
            details: {},
            timestamp: Date.now()
        };

        try {
            if (!window.walletManager) {
                throw new Error('Wallet Manager not initialized');
            }

            const walletInfo = window.walletManager.getConnectedWallet();
            result.details.connected = !!walletInfo.address;
            result.details.walletType = walletInfo.type;

            // Check wallet detection
            const availableWallets = window.walletManager.supportedWallets.filter(w => w.installed);
            result.details.availableWallets = availableWallets.length;

            if (availableWallets.length === 0) {
                result.status = 'warning';
                result.details.message = 'No wallets detected';
            }

        } catch (error) {
            result.status = 'warning';
            result.details.error = error.message;
        }

        return result;
    }

    async checkPlatformFunctions() {
        const result = {
            status: 'healthy',
            details: {},
            timestamp: Date.now()
        };

        try {
            if (!window.tesseraptPlatform) {
                throw new Error('Platform Functions not initialized');
            }

            // Check critical functions exist
            const criticalFunctions = [
                'showYieldSection',
                'showTradingSection',
                'handleStaking',
                'confirmTrade'
            ];

            const missingFunctions = criticalFunctions.filter(func =>
                typeof window.tesseraptPlatform[func] !== 'function'
            );

            if (missingFunctions.length > 0) {
                result.status = 'critical';
                result.details.missingFunctions = missingFunctions;
            }

            // Check data integrity
            const stakingData = window.tesseraptPlatform.stakingData;
            result.details.stakingDataValid = !!(stakingData && typeof stakingData === 'object');

        } catch (error) {
            result.status = 'critical';
            result.details.error = error.message;
        }

        return result;
    }

    async checkAPIConnectivity() {
        const result = {
            status: 'healthy',
            details: {
                apis: {}
            },
            timestamp: Date.now()
        };

        const apiTests = [
            {
                name: 'CoinGecko',
                url: 'https://api.coingecko.com/api/v3/ping',
                timeout: 5000
            },
            {
                name: 'Binance',
                url: 'https://api.binance.com/api/v3/ping',
                timeout: 5000
            }
        ];

        let failedAPIs = 0;

        for (const api of apiTests) {
            try {
                const startTime = Date.now();
                const response = await this.fetchWithTimeout(api.url, api.timeout);
                const responseTime = Date.now() - startTime;

                result.details.apis[api.name] = {
                    status: response.ok ? 'healthy' : 'error',
                    responseTime,
                    httpStatus: response.status
                };

                if (!response.ok) {
                    failedAPIs++;
                }

            } catch (error) {
                result.details.apis[api.name] = {
                    status: 'error',
                    error: error.message
                };
                failedAPIs++;
            }
        }

        if (failedAPIs === apiTests.length) {
            result.status = 'critical';
        } else if (failedAPIs > 0) {
            result.status = 'warning';
        }

        return result;
    }

    async checkUIResponsiveness() {
        const result = {
            status: 'healthy',
            details: {},
            timestamp: Date.now()
        };

        try {
            // Check DOM elements exist
            const criticalElements = [
                'nav',
                '.hero-section',
                '.yield-section',
                '.trading-section',
                '.lending-section'
            ];

            const missingElements = criticalElements.filter(selector =>
                !document.querySelector(selector)
            );

            if (missingElements.length > 0) {
                result.status = 'warning';
                result.details.missingElements = missingElements;
            }

            // Check performance
            const performanceEntries = performance.getEntriesByType('navigation');
            if (performanceEntries.length > 0) {
                const loadTime = performanceEntries[0].loadEventEnd - performanceEntries[0].loadEventStart;
                result.details.pageLoadTime = loadTime;

                if (loadTime > 5000) {
                    result.status = 'warning';
                    result.details.slowLoad = true;
                }
            }

            // Check memory usage (if available)
            if (performance.memory) {
                const memoryUsage = performance.memory.usedJSHeapSize / performance.memory.totalJSHeapSize;
                result.details.memoryUsage = Math.round(memoryUsage * 100);

                if (memoryUsage > 0.8) {
                    result.status = 'warning';
                    result.details.highMemoryUsage = true;
                }
            }

        } catch (error) {
            result.status = 'warning';
            result.details.error = error.message;
        }

        return result;
    }

    // ==========================================
    // MONITORING SYSTEM
    // ==========================================

    startMonitoring() {
        if (this.isMonitoring) return;

        console.log('🔄 Starting system monitoring');
        this.isMonitoring = true;

        // Run initial health check
        this.runAllHealthChecks();

        // Set up periodic monitoring
        setInterval(() => {
            this.runAllHealthChecks();
        }, this.monitoringInterval);

        // Set up individual check intervals
        for (const [key, check] of this.healthChecks) {
            setInterval(() => {
                this.runHealthCheck(key);
            }, check.interval);
        }
    }

    stopMonitoring() {
        console.log('⏹️ Stopping system monitoring');
        this.isMonitoring = false;
    }

    async runAllHealthChecks() {
        console.log('🔍 Running all health checks');

        const results = {};
        for (const [key, check] of this.healthChecks) {
            results[key] = await this.runHealthCheck(key);
        }

        this.processHealthResults(results);
        return results;
    }

    async runHealthCheck(checkKey) {
        const check = this.healthChecks.get(checkKey);
        if (!check) return null;

        try {
            const result = await check.check();
            this.recordMetric(`healthCheck.${checkKey}`, result.status);

            // Store result
            this.metrics.set(`lastHealthCheck.${checkKey}`, result);

            return result;
        } catch (error) {
            console.error(`Health check ${checkKey} failed:`, error);

            const errorResult = {
                status: 'critical',
                details: { error: error.message },
                timestamp: Date.now()
            };

            this.metrics.set(`lastHealthCheck.${checkKey}`, errorResult);
            return errorResult;
        }
    }

    processHealthResults(results) {
        // Check for critical issues
        const criticalIssues = Object.entries(results)
            .filter(([key, result]) => {
                const check = this.healthChecks.get(key);
                return check.critical && result.status === 'critical';
            });

        if (criticalIssues.length > 0) {
            this.triggerAlert('critical', 'Critical system issues detected', criticalIssues);
        }

        // Check for warnings
        const warnings = Object.entries(results)
            .filter(([key, result]) => result.status === 'warning');

        if (warnings.length > 0) {
            this.triggerAlert('warning', 'System warnings detected', warnings);
        }

        // Update overall system status
        this.updateSystemStatus(results);
    }

    updateSystemStatus(results) {
        let overallStatus = 'healthy';

        const statuses = Object.values(results).map(r => r.status);

        if (statuses.includes('critical')) {
            overallStatus = 'critical';
        } else if (statuses.includes('warning')) {
            overallStatus = 'warning';
        }

        this.recordMetric('system.overallStatus', overallStatus);

        // Update UI indicator if exists
        this.updateStatusIndicator(overallStatus);
    }

    updateStatusIndicator(status) {
        const indicator = document.querySelector('#system-status-indicator');
        if (indicator) {
            indicator.className = `status-indicator ${status}`;
            indicator.title = `System Status: ${status}`;
        }
    }

    // ==========================================
    // ALERTING SYSTEM
    // ==========================================

    triggerAlert(level, message, details = null) {
        const alert = {
            id: Date.now(),
            level,
            message,
            details,
            timestamp: Date.now(),
            acknowledged: false
        };

        this.alerts.push(alert);

        // Keep only last 100 alerts
        if (this.alerts.length > 100) {
            this.alerts.shift();
        }

        console.warn(`🚨 ALERT [${level.toUpperCase()}]: ${message}`, details);

        // In production, send to monitoring service
        this.sendAlert(alert);
    }

    sendAlert(alert) {
        // Mock implementation - replace with actual alerting service
        if (alert.level === 'critical') {
            // Could send to Slack, email, PagerDuty, etc.
            console.error('CRITICAL ALERT:', alert);
        }
    }

    acknowledgeAlert(alertId) {
        const alert = this.alerts.find(a => a.id === alertId);
        if (alert) {
            alert.acknowledged = true;
            console.log(`Alert ${alertId} acknowledged`);
        }
    }

    // ==========================================
    // METRICS COLLECTION
    // ==========================================

    recordMetric(name, value, timestamp = Date.now()) {
        if (!this.metrics.has(name)) {
            this.metrics.set(name, []);
        }

        const metricHistory = this.metrics.get(name);
        metricHistory.push({ value, timestamp });

        // Keep only last 1000 data points per metric
        if (metricHistory.length > 1000) {
            metricHistory.shift();
        }
    }

    getMetric(name, limit = 100) {
        const metricHistory = this.metrics.get(name);
        if (!metricHistory) return [];

        return metricHistory.slice(-limit);
    }

    getAllMetrics() {
        const allMetrics = {};
        for (const [name, history] of this.metrics) {
            allMetrics[name] = history.slice(-10); // Last 10 data points
        }
        return allMetrics;
    }

    // ==========================================
    // UTILITY METHODS
    // ==========================================

    async fetchWithTimeout(url, timeout = 5000) {
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), timeout);

        try {
            const response = await fetch(url, {
                signal: controller.signal,
                method: 'GET',
                headers: {
                    'Accept': 'application/json'
                }
            });

            clearTimeout(timeoutId);
            return response;
        } catch (error) {
            clearTimeout(timeoutId);
            throw error;
        }
    }

    // ==========================================
    // PUBLIC API
    // ==========================================

    getSystemHealth() {
        const healthResults = {};

        for (const [key, check] of this.healthChecks) {
            const lastResult = this.metrics.get(`lastHealthCheck.${key}`);
            healthResults[key] = lastResult || { status: 'unknown', details: {} };
        }

        const overallStatus = this.metrics.get('system.overallStatus');

        return {
            overall: overallStatus ? overallStatus[overallStatus.length - 1]?.value : 'unknown',
            components: healthResults,
            alerts: this.alerts.filter(a => !a.acknowledged),
            lastUpdate: Date.now()
        };
    }

    getPerformanceMetrics() {
        return {
            pageLoad: this.getMetric('performance.pageLoad'),
            apiResponse: this.getMetric('performance.apiResponse'),
            memoryUsage: this.getMetric('performance.memoryUsage'),
            errorRate: this.getMetric('errors.rate')
        };
    }

    exportDiagnostics() {
        return {
            systemHealth: this.getSystemHealth(),
            performanceMetrics: this.getPerformanceMetrics(),
            allMetrics: this.getAllMetrics(),
            alerts: this.alerts,
            timestamp: Date.now(),
            userAgent: navigator.userAgent,
            url: window.location.href
        };
    }

    // ==========================================
    // DEBUG INTERFACE
    // ==========================================

    debugInfo() {
        console.log('🔍 TESSERAPT System Monitor Debug Info:');
        console.log('System Health:', this.getSystemHealth());
        console.log('Performance Metrics:', this.getPerformanceMetrics());
        console.log('Active Alerts:', this.alerts.filter(a => !a.acknowledged));
        console.log('Monitoring Status:', this.isMonitoring ? 'Active' : 'Inactive');

        return this.exportDiagnostics();
    }
}

// Initialize system monitor
let systemMonitor;

document.addEventListener('DOMContentLoaded', function () {
    // Wait a bit for other systems to initialize
    setTimeout(() => {
        systemMonitor = new TesseraptSystemMonitor();
        console.log('🚀 TESSERAPT System Monitor loaded and active');
    }, 2000);
});

// Export for module usage
if (typeof module !== 'undefined' && module.exports) {
    module.exports = TesseraptSystemMonitor;
}