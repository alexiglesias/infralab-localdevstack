# GCP Equivalence

The same stack mapped to Google Cloud Platform services. Shorter than the AWS migration plan because GCP coverage in this portfolio is intentionally brief — the bulk of the cloud work targets AWS.

## Service mapping

| Local              | AWS                          | GCP                                          |
|--------------------|------------------------------|----------------------------------------------|
| `web01` (Nginx)    | ALB + ACM                    | Cloud Load Balancing (HTTPS) + managed cert  |
| `app01` (Tomcat)   | EC2 Auto Scaling Group       | Managed Instance Group (MIG) + autoscaler    |
| `db01` (MariaDB)   | RDS MySQL Multi-AZ           | Cloud SQL for MySQL (HA configuration)       |
| `mc01` (Memcached) | ElastiCache                  | Memorystore for Memcached                    |
| `rmq01` (RabbitMQ) | Amazon MQ (RabbitMQ engine)  | No managed RabbitMQ → self-host on a VM, *or* migrate to Pub/Sub |
| `/etc/hosts`       | Route 53 Private Hosted Zone | Cloud DNS private zone                       |
| Self-signed cert   | ACM (free)                   | Google-managed SSL certificate (free)        |
| `firewalld` zones  | VPC Security Groups          | VPC Firewall Rules                           |
| Single 56.0/24     | VPC with 2 AZs               | VPC with 2 zones in a region                 |
| WAR via S3 + IAM   | S3 + EC2 IAM role            | GCS bucket + Service Account                 |

## Key differences from AWS

**No managed RabbitMQ on GCP.** AWS has Amazon MQ; GCP doesn't have an
equivalent. Three options:

1. Self-host RabbitMQ on a Compute Engine VM (closest 1:1 match to the lab)
2. Migrate to Cloud Pub/Sub, which is GCP's native messaging product (better
   integration but requires application code changes)
3. Use a third-party hosted RabbitMQ (CloudAMQP) — works fine but isn't
   "pure GCP"

For a portfolio mapping, option 1 is the simplest to document.

**Different default model for high availability.** AWS expresses HA as "Multi-AZ" — explicit second instance in another AZ. GCP often expresses HA as "regional" — a service that's automatically replicated across zones in the region. Cloud SQL HA, Memorystore Standard tier, and regional MIGs all use the regional model.

**Firewall rules are at the VPC level, not per-resource.** On AWS, each EC2 instance has its own Security Group attached. On GCP, firewall rules apply to the whole VPC and use **network tags** to select which instances they match. Conceptually the same allow-list pattern, mechanically different.

**Identity model is service accounts, not IAM roles.** AWS has "an IAM role attached to an instance." GCP has "a Service Account attached to a VM." The Service Account's permissions define what the VM can do with GCP APIs. Same idea, different name.

## Cost ballpark

A similar deployment on GCP (`us-central1`, mid-2026 prices):

| Service                       | Configuration                | Monthly cost |
|-------------------------------|------------------------------|--------------|
| Cloud Load Balancing          | HTTPS, 1 backend service     | ~$18         |
| Cloud NAT                     | Per AZ, low traffic          | ~$45         |
| Compute Engine (MIG)          | 2 × e2-small (2 GB)          | ~$25         |
| Cloud SQL MySQL HA            | db-f1-micro + replica + 20GB | ~$50         |
| Memorystore Memcached         | 1 GB standard tier           | ~$35         |
| RabbitMQ on Compute Engine    | 1 × e2-small                 | ~$12         |
| Cloud DNS                     | 1 zone, low queries          | ~$0.20       |
| Managed SSL certificate       | Free                         | $0           |
| GCS (artifact bucket)         | Small storage                | ~$0.50       |
| Cloud Monitoring (basic)      | Standard metrics             | ~$0–5        |
| **Total**                     |                              | **~$190/mo** |

Comparable to AWS within ~10%, with the main differences being:

- GCP's Cloud NAT is more expensive than AWS NAT Gateway per AZ
- GCP's Memorystore is more expensive than ElastiCache Memcached
- Self-hosted RabbitMQ is cheaper than Amazon MQ (no managed-service premium)

