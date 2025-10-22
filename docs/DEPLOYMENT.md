# Deployment Guide

This guide provides instructions for deploying applications built with these Docker base images to various platforms.

## Table of Contents

1. [Docker](#docker)
2. [Docker Compose](#docker-compose)
3. [Kubernetes](#kubernetes)
4. [AWS ECS](#aws-ecs)
5. [Google Cloud Run](#google-cloud-run)
6. [Azure Container Instances](#azure-container-instances)

## Docker

### Basic Deployment

```bash
# Build the image
docker build -t myapp:1.0.0 .

# Run the container
docker run -d \
  --name myapp \
  -p 8080:8080 \
  -e NODE_ENV=production \
  --restart unless-stopped \
  myapp:1.0.0
```

### Production Deployment

```bash
docker run -d \
  --name myapp \
  -p 8080:8080 \
  -e NODE_ENV=production \
  --memory="512m" \
  --cpus="1.0" \
  --health-cmd="curl -f http://localhost:8080/health || exit 1" \
  --health-interval=30s \
  --health-timeout=3s \
  --health-retries=3 \
  --restart unless-stopped \
  --log-driver=json-file \
  --log-opt max-size=10m \
  --log-opt max-file=3 \
  myapp:1.0.0
```

## Docker Compose

### Basic Configuration

```yaml
version: '3.9'

services:
  app:
    build: .
    image: myapp:latest
    ports:
      - "8080:8080"
    environment:
      - NODE_ENV=production
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 3s
      retries: 3
```

### Production Configuration

```yaml
version: '3.9'

services:
  app:
    build:
      context: .
      args:
        BUILD_DATE: ${BUILD_DATE}
        VERSION: ${VERSION}
    image: myapp:${VERSION:-latest}
    ports:
      - "8080:8080"
    environment:
      - NODE_ENV=production
      - LOG_LEVEL=info
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 3s
      retries: 3
      start_period: 10s
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    networks:
      - app-network

networks:
  app-network:
    driver: bridge
```

## Kubernetes

### Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  labels:
    app: myapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
        prometheus.io/path: "/metrics"
    spec:
      containers:
      - name: myapp
        image: myapp:1.0.0
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 8080
          name: http
          protocol: TCP
        env:
        - name: NODE_ENV
          value: "production"
        - name: PORT
          value: "8080"
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: http
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 3
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /ready
            port: http
          initialDelaySeconds: 10
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
        securityContext:
          runAsNonRoot: true
          runAsUser: 10001
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
            - ALL
---
apiVersion: v1
kind: Service
metadata:
  name: myapp
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: http
    protocol: TCP
    name: http
  selector:
    app: myapp
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
  - hosts:
    - myapp.example.com
    secretName: myapp-tls
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: myapp
            port:
              name: http
```

### Horizontal Pod Autoscaler

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: myapp
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

## AWS ECS

### Task Definition

```json
{
  "family": "myapp",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "containerDefinitions": [
    {
      "name": "myapp",
      "image": "123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp:1.0.0",
      "portMappings": [
        {
          "containerPort": 8080,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "NODE_ENV",
          "value": "production"
        }
      ],
      "healthCheck": {
        "command": ["CMD-SHELL", "curl -f http://localhost:8080/health || exit 1"],
        "interval": 30,
        "timeout": 5,
        "retries": 3,
        "startPeriod": 60
      },
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/myapp",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
```

### Service Definition

```bash
aws ecs create-service \
  --cluster production \
  --service-name myapp \
  --task-definition myapp:1 \
  --desired-count 3 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx],securityGroups=[sg-xxx],assignPublicIp=ENABLED}" \
  --load-balancers targetGroupArn=arn:aws:elasticloadbalancing:us-east-1:xxx:targetgroup/myapp/xxx,containerName=myapp,containerPort=8080
```

## Google Cloud Run

### Deployment

```bash
# Build and push to Google Container Registry
gcloud builds submit --tag gcr.io/PROJECT_ID/myapp:1.0.0

# Deploy to Cloud Run
gcloud run deploy myapp \
  --image gcr.io/PROJECT_ID/myapp:1.0.0 \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --memory 512Mi \
  --cpu 1 \
  --max-instances 10 \
  --set-env-vars NODE_ENV=production \
  --port 8080
```

### Cloud Run YAML

```yaml
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: myapp
spec:
  template:
    metadata:
      annotations:
        autoscaling.knative.dev/maxScale: '10'
        autoscaling.knative.dev/minScale: '1'
    spec:
      containerConcurrency: 80
      containers:
      - image: gcr.io/PROJECT_ID/myapp:1.0.0
        ports:
        - containerPort: 8080
        env:
        - name: NODE_ENV
          value: production
        resources:
          limits:
            memory: 512Mi
            cpu: '1'
        livenessProbe:
          httpGet:
            path: /health
          initialDelaySeconds: 10
          periodSeconds: 10
```

## Azure Container Instances

### Deployment

```bash
az container create \
  --resource-group myResourceGroup \
  --name myapp \
  --image myregistry.azurecr.io/myapp:1.0.0 \
  --cpu 1 \
  --memory 1 \
  --ports 8080 \
  --environment-variables NODE_ENV=production \
  --restart-policy OnFailure
```

### YAML Configuration

```yaml
apiVersion: 2019-12-01
location: eastus
name: myapp
properties:
  containers:
  - name: myapp
    properties:
      image: myregistry.azurecr.io/myapp:1.0.0
      resources:
        requests:
          cpu: 1.0
          memoryInGB: 1.0
      ports:
      - port: 8080
        protocol: TCP
      environmentVariables:
      - name: NODE_ENV
        value: production
      livenessProbe:
        httpGet:
          path: /health
          port: 8080
        initialDelaySeconds: 30
        periodSeconds: 10
  osType: Linux
  restartPolicy: OnFailure
  ipAddress:
    type: Public
    ports:
    - protocol: TCP
      port: 8080
tags: {}
type: Microsoft.ContainerInstance/containerGroups
```

## Best Practices

1. **Use specific image tags** - Never use `latest` in production
2. **Set resource limits** - Always define CPU and memory limits
3. **Implement health checks** - Use both liveness and readiness probes
4. **Enable auto-scaling** - Configure HPA or equivalent
5. **Use secrets management** - Never hardcode secrets
6. **Enable logging** - Configure centralized logging
7. **Monitor metrics** - Set up Prometheus/CloudWatch/Stackdriver
8. **Implement rolling updates** - Zero-downtime deployments
9. **Use multiple replicas** - At least 3 for high availability
10. **Configure HTTPS** - Always use TLS in production

## Troubleshooting

### Check logs
```bash
# Docker
docker logs myapp

# Kubernetes
kubectl logs deployment/myapp

# AWS ECS
aws logs tail /ecs/myapp --follow
```

### Check health
```bash
curl http://localhost:8080/health
kubectl exec -it myapp-pod -- curl localhost:8080/health
```

### Debug container
```bash
# Docker
docker exec -it myapp sh

# Kubernetes
kubectl exec -it myapp-pod -- sh
```

