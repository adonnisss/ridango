# Citus Helm Chart

This Helm chart deploys a Citus cluster on Kubernetes, consisting of one coordinator (master) node and multiple worker nodes.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2+
- PV provisioner support in the underlying infrastructure (for persistent volume claims)

## Deployment Strategy

This chart implements the following architecture:

- **Coordinator Node**: Deployed as a Kubernetes Deployment with a persistent volume for data storage
- **Worker Nodes**: Deployed as a StatefulSet with persistent volumes for each pod
- **Services**: ClusterIP services for coordinator and a headless service for worker nodes
- **Post-Install Jobs**: Automatically configures Citus extension and creates a sharded database

## Installing the Chart

```bash
# Clone this repository or create files locally
git clone <repository-url>
cd citus-helm-chart

# Install the chart
helm install my-citus ./citus
```

## Checking Deployment Status

```bash
# Check if pods are running
kubectl get pods

# Watch for post-installation jobs to complete
kubectl get jobs

# Once all pods are running and jobs completed, port-forward to connect
kubectl port-forward svc/citus-coordinator 5432:5432
```

## Connecting to the Database

```bash
# In a new terminal, connect to the database
PGPASSWORD=postgres psql -h localhost -p 5432 -U postgres postgres

# Connect to the sample database
PGPASSWORD=postgres psql -h localhost -p 5432 -U postgres appdb
```

## Verifying Distributed Setup

```sql
-- Check if Citus extension is installed
SELECT * FROM pg_extension;

-- Check registered worker nodes
SELECT * FROM master_get_active_worker_nodes();

-- Check distributed tables
SELECT logicalrelid, count(*)
FROM pg_dist_shard
GROUP BY logicalrelid;

-- Query distributed data
SELECT * FROM users;
SELECT * FROM orders;
```

## Configuration

The following table lists the configurable parameters of the Citus chart:

| Parameter                      | Description                               | Default           |
|--------------------------------|-------------------------------------------|-------------------|
| `image.repository`             | Citus container image                     | `citusdata/citus` |
| `image.tag`                    | Citus container image tag                 | `13.0.3`          |
| `postgresql.username`          | PostgreSQL username                       | `postgres`        |
| `postgresql.password`          | PostgreSQL password                       | `postgres`        |
| `coordinator.replicas`         | Number of coordinator replicas (always 1) | `1`               |
| `coordinator.persistence.size` | Coordinator storage size                  | `8Gi`             |
| `workers.replicas`             | Number of worker nodes                    | `2`               |
| `workers.persistence.size`     | Worker nodes storage size                 | `8Gi`             |

## Uninstalling the Chart

```bash
helm uninstall my-citus
```

## Notes and Best Practices

- For production use, consider setting up backups for your data
- Use Kubernetes secrets for storing database credentials
- For better performance, adjust resource requests/limits based on workload
- Consider setting up monitoring using Prometheus and Grafana

## Troubleshooting

If you encounter issues:

1. Check pod logs: `kubectl logs <pod-name>`
2. Check job logs: `kubectl logs job/<job-name>`
3. Ensure all services are properly created: `kubectl get svc`
4. Verify PVCs are bound: `kubectl get pvc`
