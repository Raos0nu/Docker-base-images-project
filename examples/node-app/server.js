const http = require('http');

// Configuration
const CONFIG = {
  port: process.env.PORT || 8080,
  host: process.env.HOST || '0.0.0.0',
  nodeEnv: process.env.NODE_ENV || 'development',
  shutdownTimeout: parseInt(process.env.SHUTDOWN_TIMEOUT || '10000', 10),
};

// Logger utility
const logger = {
  info: (msg, meta = {}) => console.log(JSON.stringify({ level: 'info', msg, ...meta, timestamp: new Date().toISOString() })),
  error: (msg, meta = {}) => console.error(JSON.stringify({ level: 'error', msg, ...meta, timestamp: new Date().toISOString() })),
  warn: (msg, meta = {}) => console.warn(JSON.stringify({ level: 'warn', msg, ...meta, timestamp: new Date().toISOString() })),
};

// Application state
let isShuttingDown = false;
const connections = new Set();

// Request handler
const requestHandler = (req, res) => {
  // Track active connections for graceful shutdown
  connections.add(res);
  res.on('finish', () => connections.delete(res));

  // Reject requests during shutdown
  if (isShuttingDown) {
    res.writeHead(503, { 'Content-Type': 'application/json' });
    return res.end(JSON.stringify({ error: 'Service shutting down' }));
  }

  // Security headers
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'DENY');
  res.setHeader('X-XSS-Protection', '1; mode=block');
  res.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');

  // Health check endpoint
  if (req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    return res.end(JSON.stringify({ 
      status: 'healthy',
      uptime: process.uptime(),
      timestamp: new Date().toISOString()
    }));
  }

  // Readiness check endpoint
  if (req.url === '/ready') {
    const ready = !isShuttingDown;
    res.writeHead(ready ? 200 : 503, { 'Content-Type': 'application/json' });
    return res.end(JSON.stringify({ 
      ready,
      timestamp: new Date().toISOString()
    }));
  }

  // Metrics endpoint
  if (req.url === '/metrics') {
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    return res.end(`# HELP process_uptime_seconds Process uptime in seconds
# TYPE process_uptime_seconds gauge
process_uptime_seconds ${process.uptime()}

# HELP process_memory_bytes Process memory usage in bytes
# TYPE process_memory_bytes gauge
process_memory_bytes{type="rss"} ${process.memoryUsage().rss}
process_memory_bytes{type="heapTotal"} ${process.memoryUsage().heapTotal}
process_memory_bytes{type="heapUsed"} ${process.memoryUsage().heapUsed}
process_memory_bytes{type="external"} ${process.memoryUsage().external}
`);
  }

  // Root endpoint
  if (req.url === '/') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    return res.end(JSON.stringify({ 
      message: 'Hello from Docker base image!',
      version: '1.0.0',
      environment: CONFIG.nodeEnv,
      timestamp: new Date().toISOString()
    }));
  }

  // 404 Not Found
  res.writeHead(404, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ error: 'Not Found', path: req.url }));
};

// Create HTTP server
const server = http.createServer(requestHandler);

// Error handling
server.on('error', (err) => {
  logger.error('Server error', { error: err.message, stack: err.stack });
  process.exit(1);
});

// Graceful shutdown handler
const gracefulShutdown = async (signal) => {
  if (isShuttingDown) {
    logger.warn('Shutdown already in progress, forcing exit');
    process.exit(1);
  }

  logger.info(`Received ${signal}, starting graceful shutdown`);
  isShuttingDown = true;

  // Stop accepting new connections
  server.close(() => {
    logger.info('HTTP server closed');
  });

  // Wait for active connections to finish
  const shutdownTimer = setTimeout(() => {
    logger.warn('Shutdown timeout reached, forcing closure of active connections', {
      activeConnections: connections.size
    });
    connections.forEach(res => res.end());
    process.exit(0);
  }, CONFIG.shutdownTimeout);

  // Monitor active connections
  const checkInterval = setInterval(() => {
    if (connections.size === 0) {
      clearInterval(checkInterval);
      clearTimeout(shutdownTimer);
      logger.info('All connections closed, exiting gracefully');
      process.exit(0);
    }
  }, 100);
};

// Handle shutdown signals
process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

// Handle uncaught errors
process.on('uncaughtException', (err) => {
  logger.error('Uncaught exception', { error: err.message, stack: err.stack });
  gracefulShutdown('uncaughtException');
});

process.on('unhandledRejection', (reason, promise) => {
  logger.error('Unhandled promise rejection', { reason, promise });
  gracefulShutdown('unhandledRejection');
});

// Start server
server.listen(CONFIG.port, CONFIG.host, () => {
  logger.info('Server started', {
    port: CONFIG.port,
    host: CONFIG.host,
    nodeEnv: CONFIG.nodeEnv,
    nodeVersion: process.version,
    pid: process.pid
  });
});
