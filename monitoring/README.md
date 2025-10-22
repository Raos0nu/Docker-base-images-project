# Monitoring Stack

Complete monitoring solution for Docker base images using Prometheus, Grafana, cAdvisor, and Node Exporter.

## Components

### Prometheus
- **Port**: 9090
- **Purpose**: Metrics collection and storage
- **URL**: http://localhost:9090

### Grafana
- **Port**: 3000
- **Purpose**: Metrics visualization and dashboards
- **URL**: http://localhost:3000
- **Credentials**: admin / admin

### cAdvisor
- **Port**: 8081
- **Purpose**: Container metrics collection
- **URL**: http://localhost:8081

### Node Exporter
- **Port**: 9100
- **Purpose**: Host system metrics
- **URL**: http://localhost:9100

## Quick Start

### Start Monitoring Stack

```bash
# From project root
make monitoring-up

# Or from monitoring directory
cd monitoring
docker compose up -d
```

### Stop Monitoring Stack

```bash
# From project root
make monitoring-down

# Or from monitoring directory
cd monitoring
docker compose down
```

### View Logs

```bash
# From project root
make monitoring-logs

# Or from monitoring directory
cd monitoring
docker compose logs -f
```

## Accessing Services

After starting the stack, access the following URLs:

- **Grafana**: http://localhost:3000
  - Default login: admin / admin
  - Pre-configured dashboards available
  
- **Prometheus**: http://localhost:9090
  - Query metrics directly
  - View configured targets and alerts
  
- **cAdvisor**: http://localhost:8081
  - Real-time container metrics
  - Per-container resource usage

## Available Dashboards

### Docker Containers Dashboard

Pre-configured dashboard showing:
- Container CPU usage
- Container memory usage
- Running containers count
- Network I/O statistics
- Disk I/O statistics

## Metrics Collection

### Container Metrics (cAdvisor)

- `container_cpu_usage_seconds_total`: CPU usage
- `container_memory_usage_bytes`: Memory usage
- `container_network_receive_bytes_total`: Network RX
- `container_network_transmit_bytes_total`: Network TX
- `container_fs_reads_bytes_total`: Disk reads
- `container_fs_writes_bytes_total`: Disk writes

### Host Metrics (Node Exporter)

- `node_cpu_seconds_total`: CPU time
- `node_memory_MemAvailable_bytes`: Available memory
- `node_filesystem_avail_bytes`: Available disk space
- `node_network_receive_bytes_total`: Network received
- `node_network_transmit_bytes_total`: Network transmitted

### Application Metrics

Applications should expose metrics at `/metrics`:

```
# Example metrics from demo-node app
process_uptime_seconds
process_memory_bytes{type="rss"}
process_memory_bytes{type="heapTotal"}
process_memory_bytes{type="heapUsed"}
```

## Alerts

The stack includes pre-configured alerts for:

### Container Alerts
- Container monitoring down
- High CPU usage (>80% for 5 minutes)
- High memory usage (>90% for 5 minutes)
- Frequent container restarts

### Application Alerts
- Application down
- High response time

### Node Alerts
- Low disk space (<10%)
- High CPU load (>80%)

## Configuration

### Prometheus Configuration

Edit `prometheus.yml` to add new scrape targets:

```yaml
scrape_configs:
  - job_name: 'my-app'
    static_configs:
      - targets: ['my-app:8080']
```

### Adding Grafana Dashboards

1. Create JSON dashboard file in `grafana/dashboards/`
2. Restart Grafana: `docker compose restart grafana`
3. Dashboard will be automatically provisioned

### Custom Alerts

Edit `prometheus/alerts.yml` to add custom alert rules:

```yaml
groups:
  - name: custom_alerts
    rules:
      - alert: MyCustomAlert
        expr: my_metric > 100
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Custom alert triggered"
```

## Data Persistence

The stack uses Docker volumes for data persistence:

- `prometheus_data`: Prometheus metrics data (30 day retention)
- `grafana_data`: Grafana dashboards and settings

### Backup Data

```bash
# Backup Prometheus data
docker run --rm -v monitoring_prometheus_data:/data -v $(pwd):/backup alpine tar czf /backup/prometheus-backup.tar.gz -C /data .

# Backup Grafana data
docker run --rm -v monitoring_grafana_data:/data -v $(pwd):/backup alpine tar czf /backup/grafana-backup.tar.gz -C /data .
```

### Restore Data

```bash
# Restore Prometheus data
docker run --rm -v monitoring_prometheus_data:/data -v $(pwd):/backup alpine tar xzf /backup/prometheus-backup.tar.gz -C /data

# Restore Grafana data
docker run --rm -v monitoring_grafana_data:/data -v $(pwd):/backup alpine tar xzf /backup/grafana-backup.tar.gz -C /data
```

## Troubleshooting

### Services Not Starting

Check logs:
```bash
docker compose logs [service-name]
```

### No Data in Grafana

1. Check Prometheus is scraping targets: http://localhost:9090/targets
2. Verify data source in Grafana: Configuration → Data Sources
3. Check time range in dashboard

### High Resource Usage

Adjust scrape intervals in `prometheus.yml`:
```yaml
global:
  scrape_interval: 30s  # Increase from 15s
```

### Permission Issues (Linux)

Fix permissions for volumes:
```bash
sudo chown -R 472:472 grafana/
```

## Best Practices

1. **Security**
   - Change default Grafana password
   - Use reverse proxy with SSL in production
   - Restrict network access

2. **Performance**
   - Adjust retention time based on needs
   - Use appropriate scrape intervals
   - Monitor disk usage

3. **Maintenance**
   - Regular backups of important data
   - Update container images periodically
   - Monitor alert rules

## Integration with Applications

### Node.js Example

```javascript
// Expose metrics endpoint
app.get('/metrics', (req, res) => {
  res.set('Content-Type', 'text/plain');
  res.send(`
# HELP process_uptime_seconds Process uptime
# TYPE process_uptime_seconds gauge
process_uptime_seconds ${process.uptime()}
  `);
});
```

### Python Example

```python
from prometheus_client import make_wsgi_app, Counter, Gauge
from werkzeug.middleware.dispatcher import DispatcherMiddleware

# Add metrics endpoint
app.wsgi_app = DispatcherMiddleware(app.wsgi_app, {
    '/metrics': make_wsgi_app()
})
```

## Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [cAdvisor Documentation](https://github.com/google/cadvisor)
- [Node Exporter Documentation](https://github.com/prometheus/node_exporter)

