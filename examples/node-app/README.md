# Node.js Example Application

A production-ready Node.js application demonstrating best practices with Docker base images.

## Features

- ✅ Health check endpoint (`/health`)
- ✅ Readiness check endpoint (`/ready`)
- ✅ Prometheus metrics endpoint (`/metrics`)
- ✅ Graceful shutdown handling
- ✅ Security headers
- ✅ Structured logging
- ✅ Error handling
- ✅ Non-root user execution

## Endpoints

- `GET /` - Main endpoint
- `GET /health` - Health check (returns 200 OK when healthy)
- `GET /ready` - Readiness check (returns 200 when ready to accept traffic)
- `GET /metrics` - Prometheus-compatible metrics

## Running Locally

### Build the image
```bash
docker build -t demo-node:latest .
```

### Run the container
```bash
docker run -p 8080:8080 --name demo-node demo-node:latest
```

### Test the application
```bash
# Main endpoint
curl http://localhost:8080/

# Health check
curl http://localhost:8080/health

# Metrics
curl http://localhost:8080/metrics
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `8080` | Server port |
| `HOST` | `0.0.0.0` | Server host |
| `NODE_ENV` | `development` | Environment (development/production) |
| `SHUTDOWN_TIMEOUT` | `10000` | Graceful shutdown timeout (ms) |

## Production Deployment

```bash
docker run -d \
  -p 8080:8080 \
  -e NODE_ENV=production \
  -e SHUTDOWN_TIMEOUT=30000 \
  --name demo-node \
  --restart unless-stopped \
  demo-node:latest
```

## Kubernetes Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-node
spec:
  replicas: 3
  selector:
    matchLabels:
      app: demo-node
  template:
    metadata:
      labels:
        app: demo-node
    spec:
      containers:
      - name: demo-node
        image: demo-node:latest
        ports:
        - containerPort: 8080
        env:
        - name: NODE_ENV
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

