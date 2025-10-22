#!/usr/bin/env python3
"""
Production-ready Python Flask application demonstrating Docker base image usage.
"""

import os
import sys
import signal
import logging
from datetime import datetime
from flask import Flask, jsonify, request
from werkzeug.middleware.proxy_fix import ProxyFix
import psutil

# Configuration
CONFIG = {
    'port': int(os.getenv('PORT', 8080)),
    'host': os.getenv('HOST', '0.0.0.0'),
    'env': os.getenv('FLASK_ENV', 'production'),
    'debug': os.getenv('DEBUG', 'false').lower() == 'true',
}

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='{"timestamp": "%(asctime)s", "level": "%(levelname)s", "message": "%(message)s"}',
    handlers=[logging.StreamHandler(sys.stdout)]
)
logger = logging.getLogger(__name__)

# Create Flask app
app = Flask(__name__)
app.wsgi_app = ProxyFix(app.wsgi_app, x_for=1, x_proto=1, x_host=1)

# Application state
start_time = datetime.now()
is_shutting_down = False


# Security headers middleware
@app.after_request
def add_security_headers(response):
    """Add security headers to all responses."""
    response.headers['X-Content-Type-Options'] = 'nosniff'
    response.headers['X-Frame-Options'] = 'DENY'
    response.headers['X-XSS-Protection'] = '1; mode=block'
    response.headers['Strict-Transport-Security'] = 'max-age=31536000; includeSubDomains'
    return response


# Request logging middleware
@app.before_request
def log_request():
    """Log incoming requests."""
    logger.info(f"Request: {request.method} {request.path} from {request.remote_addr}")


# Routes
@app.route('/')
def index():
    """Main endpoint."""
    if is_shutting_down:
        return jsonify({'error': 'Service shutting down'}), 503
    
    return jsonify({
        'message': 'Hello from Python Docker base image!',
        'version': '1.0.0',
        'environment': CONFIG['env'],
        'timestamp': datetime.now().isoformat(),
        'python_version': sys.version
    })


@app.route('/health')
def health():
    """Health check endpoint."""
    uptime = (datetime.now() - start_time).total_seconds()
    
    return jsonify({
        'status': 'healthy',
        'uptime': uptime,
        'timestamp': datetime.now().isoformat()
    })


@app.route('/ready')
def ready():
    """Readiness check endpoint."""
    ready = not is_shutting_down
    status_code = 200 if ready else 503
    
    return jsonify({
        'ready': ready,
        'timestamp': datetime.now().isoformat()
    }), status_code


@app.route('/metrics')
def metrics():
    """Prometheus metrics endpoint."""
    uptime = (datetime.now() - start_time).total_seconds()
    process = psutil.Process()
    memory_info = process.memory_info()
    cpu_percent = process.cpu_percent(interval=0.1)
    
    metrics_text = f"""# HELP process_uptime_seconds Process uptime in seconds
# TYPE process_uptime_seconds gauge
process_uptime_seconds {uptime}

# HELP process_cpu_percent Process CPU usage percentage
# TYPE process_cpu_percent gauge
process_cpu_percent {cpu_percent}

# HELP process_memory_bytes Process memory usage in bytes
# TYPE process_memory_bytes gauge
process_memory_bytes{{type="rss"}} {memory_info.rss}
process_memory_bytes{{type="vms"}} {memory_info.vms}

# HELP process_open_fds Number of open file descriptors
# TYPE process_open_fds gauge
process_open_fds {process.num_fds()}

# HELP process_threads Number of threads
# TYPE process_threads gauge
process_threads {process.num_threads()}
"""
    
    return metrics_text, 200, {'Content-Type': 'text/plain; charset=utf-8'}


@app.route('/info')
def info():
    """System information endpoint."""
    return jsonify({
        'python': {
            'version': sys.version,
            'executable': sys.executable,
            'platform': sys.platform
        },
        'process': {
            'pid': os.getpid(),
            'user': os.getenv('USER', 'unknown'),
            'cwd': os.getcwd()
        },
        'system': {
            'cpu_count': psutil.cpu_count(),
            'memory_total': psutil.virtual_memory().total,
            'memory_available': psutil.virtual_memory().available
        }
    })


# Error handlers
@app.errorhandler(404)
def not_found(error):
    """Handle 404 errors."""
    return jsonify({
        'error': 'Not Found',
        'path': request.path
    }), 404


@app.errorhandler(500)
def internal_error(error):
    """Handle 500 errors."""
    logger.error(f"Internal server error: {error}")
    return jsonify({
        'error': 'Internal Server Error'
    }), 500


# Graceful shutdown
def graceful_shutdown(signum, frame):
    """Handle graceful shutdown."""
    global is_shutting_down
    
    logger.info(f"Received signal {signum}, starting graceful shutdown...")
    is_shutting_down = True
    
    # Give time for in-flight requests to complete
    logger.info("Waiting for in-flight requests to complete...")
    import time
    time.sleep(2)
    
    logger.info("Shutdown complete")
    sys.exit(0)


# Register signal handlers
signal.signal(signal.SIGTERM, graceful_shutdown)
signal.signal(signal.SIGINT, graceful_shutdown)


if __name__ == '__main__':
    logger.info(f"Starting application on {CONFIG['host']}:{CONFIG['port']}")
    logger.info(f"Environment: {CONFIG['env']}")
    logger.info(f"Debug mode: {CONFIG['debug']}")
    
    try:
        app.run(
            host=CONFIG['host'],
            port=CONFIG['port'],
            debug=CONFIG['debug'],
            use_reloader=False  # Disable reloader for production
        )
    except Exception as e:
        logger.error(f"Failed to start application: {e}")
        sys.exit(1)

