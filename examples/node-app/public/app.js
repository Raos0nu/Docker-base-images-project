// Configuration
const CONFIG = {
    refreshInterval: 5000, // 5 seconds
    apiBaseUrl: ''
};

// Format bytes to human readable
function formatBytes(bytes) {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
}

// Format seconds to human readable
function formatUptime(seconds) {
    const days = Math.floor(seconds / 86400);
    const hours = Math.floor((seconds % 86400) / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = Math.floor(seconds % 60);
    
    if (days > 0) {
        return `${days}d ${hours}h ${minutes}m`;
    } else if (hours > 0) {
        return `${hours}h ${minutes}m ${secs}s`;
    } else if (minutes > 0) {
        return `${minutes}m ${secs}s`;
    } else {
        return `${secs}s`;
    }
}

// Format timestamp
function formatTimestamp(timestamp) {
    if (!timestamp) return '-';
    const date = new Date(timestamp);
    return date.toLocaleString();
}

// Update welcome card
async function loadWelcome() {
    try {
        const response = await fetch('/api');
        const data = await response.json();
        
        document.getElementById('welcome-message').textContent = data.message;
        document.getElementById('version').textContent = data.version;
        document.getElementById('environment').textContent = data.environment;
        document.getElementById('timestamp').textContent = formatTimestamp(data.timestamp);
    } catch (error) {
        console.error('Error loading welcome data:', error);
        document.getElementById('welcome-message').textContent = 'Error loading data';
    }
}

// Update health status
async function loadHealth() {
    try {
        const healthResponse = await fetch('/health');
        const healthData = await healthResponse.json();
        
        const readyResponse = await fetch('/ready');
        const readyData = await readyResponse.json();
        
        // Update health status
        const statusBadge = document.getElementById('status-badge');
        const healthStatus = document.getElementById('health-status');
        
        if (healthData.status === 'healthy') {
            statusBadge.textContent = 'Healthy';
            statusBadge.className = 'status-badge status-healthy';
            healthStatus.textContent = 'Healthy';
            healthStatus.style.color = 'var(--secondary-color)';
        } else {
            statusBadge.textContent = 'Unhealthy';
            statusBadge.className = 'status-badge status-unhealthy';
            healthStatus.textContent = 'Unhealthy';
            healthStatus.style.color = 'var(--danger-color)';
        }
        
        // Update uptime
        document.getElementById('uptime').textContent = formatUptime(healthData.uptime);
        
        // Update readiness
        const readinessEl = document.getElementById('readiness');
        if (readyData.ready) {
            readinessEl.textContent = 'Ready';
            readinessEl.style.color = 'var(--secondary-color)';
        } else {
            readinessEl.textContent = 'Not Ready';
            readinessEl.style.color = 'var(--danger-color)';
        }
    } catch (error) {
        console.error('Error loading health data:', error);
        document.getElementById('health-status').textContent = 'Error';
        document.getElementById('status-badge').textContent = 'Error';
        document.getElementById('status-badge').className = 'status-badge status-unhealthy';
    }
}

// Update metrics
async function loadMetrics() {
    try {
        const response = await fetch('/metrics');
        const text = await response.text();
        
        // Parse Prometheus metrics
        const metrics = {};
        const lines = text.split('\n');
        
        for (const line of lines) {
            if (line.startsWith('process_memory_bytes{type=')) {
                const match = line.match(/type="(\w+)"}\s+(\d+)/);
                if (match) {
                    metrics[match[1]] = parseInt(match[2]);
                }
            } else if (line.startsWith('process_uptime_seconds')) {
                const match = line.match(/process_uptime_seconds\s+([\d.]+)/);
                if (match) {
                    metrics.uptime = parseFloat(match[1]);
                }
            }
        }
        
        // Update memory metrics
        if (metrics.rss) {
            document.getElementById('memory-rss').textContent = formatBytes(metrics.rss);
            updateMetricBar('memory-rss-bar', metrics.rss, 100 * 1024 * 1024); // 100MB max for visualization
        }
        
        if (metrics.heapTotal) {
            document.getElementById('heap-total').textContent = formatBytes(metrics.heapTotal);
            updateMetricBar('heap-total-bar', metrics.heapTotal, 10 * 1024 * 1024); // 10MB max
        }
        
        if (metrics.heapUsed) {
            document.getElementById('heap-used').textContent = formatBytes(metrics.heapUsed);
            updateMetricBar('heap-used-bar', metrics.heapUsed, 10 * 1024 * 1024); // 10MB max
        }
        
        if (metrics.external) {
            document.getElementById('external-memory').textContent = formatBytes(metrics.external);
            updateMetricBar('external-memory-bar', metrics.external, 5 * 1024 * 1024); // 5MB max
        }
    } catch (error) {
        console.error('Error loading metrics:', error);
    }
}

// Update metric bar
function updateMetricBar(barId, value, max) {
    const bar = document.getElementById(barId);
    const percentage = Math.min((value / max) * 100, 100);
    bar.style.width = percentage + '%';
}

// Load all data
async function loadAllData() {
    await Promise.all([
        loadWelcome(),
        loadHealth(),
        loadMetrics()
    ]);
}

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    // Load data immediately
    loadAllData();
    
    // Set up auto-refresh
    setInterval(loadAllData, CONFIG.refreshInterval);
    
    // Update refresh interval display
    document.getElementById('refresh-interval').textContent = CONFIG.refreshInterval / 1000;
});

