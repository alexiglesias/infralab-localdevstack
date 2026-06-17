# GCP Equivalence

The same stack mapped to Google Cloud Platform services. Shorter than the
AWS migration plan because GCP coverage in this portfolio is intentionally
brief — the bulk of the cloud work targets AWS.

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

**Different default model for high availability.** AWS expresses HA as
"Multi-AZ" — explicit second instance in another AZ. GCP often expresses
HA as "regional" — a service that's automatically replicated across zones
in the region. Cloud SQL HA, Memorystore Standard tier, and regional MIGs
all use the regional model.

**Firewall rules are at the VPC level, not per-resource.** On AWS, each EC2
instance has its own Security Group attached. On GCP, firewall rules apply
to the whole VPC and use **network tags** to select which instances they
match. Conceptually the same allow-list pattern, mechanically different.

**Identity model is service accounts, not IAM roles.** AWS has "an IAM
role attached to an instance." GCP has "a Service Account attached to a
VM." The Service Account's permissions define what the VM can do with
GCP APIs. Same idea, different name.

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

For a learning project, the **GCP Free Tier** provides:

- $300 in credits for 90 days for new accounts
- "Always free" tier: 1 × e2-micro per month, 5 GB Cloud Storage,
  Cloud Build minutes, etc.

That's enough to deploy a stripped-down version of this stack (1 e2-micro
VM running both Tomcat and SQLite in place of Cloud SQL) for under
$300 over 90 days — making GCP actually the cheapest "I deployed to a
real cloud" entry in this portfolio.

## What I'd actually do for a portfolio GCP deployment

If I were building this for real on GCP using the $300 free credit:

1. Single `e2-small` Compute Engine VM running Tomcat
2. Cloud SQL `db-f1-micro` instance (the cheapest tier) for MariaDB
3. Skip the cache tier entirely (use in-memory caching in Tomcat instead)
4. Skip the message broker tier (replace with synchronous calls)
5. Cloud Load Balancing with a managed SSL cert for HTTPS
6. **One screenshot of the deployed app at a `*.run.app` URL**

That last item is the deliverable. Costs maybe $30–40 of the $300 credit
over a weekend. Tear it down after taking the screenshot. Now you have an
honest "deployed on GCP" line on your resume.

For the purposes of *this* portfolio project, the documented mapping above
is enough. The actual GCP deployment is a stretch goal for whoever has
time after Project 6.

## Multi-cloud portability — what the lab teaches

Building this on AWS, GCP, *and* locally with the same application code is
the actual signal worth highlighting. Three different infrastructure
models, one Java WAR. The lab proves:

- The application has no cloud-specific code
- All cloud-specific configuration lives in environment variables /
  config files
- Database, cache, and message broker are accessed by hostname, so
  swapping `db.vprofile.internal` from a Route 53 record to a Cloud DNS
  record is a config change, not a code change

That's the portability story. In interviews, the framing is:

> *"The application code is identical across local Vagrant, AWS, and GCP.
> What changes is the surrounding infrastructure config, which lives in
> Terraform. I built it this way intentionally so the lift-and-shift cost
> to a second cloud is minimal."*
