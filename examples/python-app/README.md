# Python Flask Example Application

A production-ready Python Flask application demonstrating best practices with Docker base images.

## Features

- ✅ Health check endpoint (`/health`)
- ✅ Readiness check endpoint (`/ready`)
- ✅ Prometheus metrics endpoint (`/metrics`)
- ✅ Graceful shutdown handling
- ✅ Security headers
- ✅ Structured JSON logging
- ✅ Error handling
- ✅ Non-root user execution
- ✅ Multi-stage Docker build

## Endpoints

- `GET /` - Main endpoint with application info
- `GET /health` - Health check (returns 200 OK when healthy)
- `GET /ready` - Readiness check (returns 200 when ready to accept traffic)
- `GET /metrics` - Prometheus-compatible metrics
- `GET /info` - System and process information

## Running Locally

### Build the image
```bash
docker build -t demo-python:latest .
```

### Run the container
```bash
docker run -p 8080:8080 --name demo-python demo-python:latest
```

### Test the application
```bash
# Main endpoint
curl http://localhost:8080/

# Health check
curl http://localhost:8080/health

# Metrics
curl http://localhost:8080/metrics

# System info
curl http://localhost:8080/info
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `8080` | Server port |
| `HOST` | `0.0.0.0` | Server host |
| `FLASK_ENV` | `production` | Flask environment |
| `DEBUG` | `false` | Enable debug mode |

## Development

### Install dependencies locally
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### Run locally
```bash
python app.py
```

### Run with custom settings
```bash
PORT=3000 FLASK_ENV=development DEBUG=true python app.py
```

## Production Deployment

```bash
docker run -d \
  -p 8080:8080 \
  -e FLASK_ENV=production \
  -e DEBUG=false \
  --name demo-python \
  --restart unless-stopped \
  demo-python:latest
```

## Kubernetes Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-python
spec:
  replicas: 3
  selector:
    matchLabels:
      app: demo-python
  template:
    metadata:
      labels:
        app: demo-python
    spec:
      containers:
      - name: demo-python
        image: demo-python:latest
        ports:
        - containerPort: 8080
        env:
        - name: FLASK_ENV
          value: "production"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 30
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 10
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
```

## Security Features

- Runs as non-root user (UID 10001)
- Security headers enabled
- Multi-stage Docker build
- Minimal attack surface
- No unnecessary packages
- Graceful shutdown handling

## Dependencies

- Flask 3.0.0 - Web framework
- Werkzeug 3.0.1 - WSGI utilities
- psutil 5.9.6 - System and process utilities

## Metrics

The application exposes Prometheus metrics at `/metrics`:

- `process_uptime_seconds` - Application uptime
- `process_cpu_percent` - CPU usage percentage
- `process_memory_bytes` - Memory usage (RSS and VMS)
- `process_open_fds` - Number of open file descriptors
- `process_threads` - Number of threads

## Logging

The application uses structured JSON logging:

```json
{
  "timestamp": "2025-10-22T10:30:00",
  "level": "INFO",
  "message": "Request: GET /health from 172.17.0.1"
}
```

## Testing

```bash
# Run the application
docker run -d -p 8080:8080 --name test-python demo-python:latest

# Test endpoints
curl http://localhost:8080/health
curl http://localhost:8080/metrics

# Check logs
docker logs test-python

# Cleanup
docker stop test-python
docker rm test-python
```

