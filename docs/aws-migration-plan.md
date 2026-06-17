# AWS Migration Plan

How the local 5-VM stack maps to a production AWS deployment, with cost
estimates and Terraform pseudocode for each piece.

This is the document that turns the lab from "I followed a Vagrant
tutorial" into "I understand the AWS architecture this represents."

## Headline mapping

| Local              | AWS                                                  | Reason                                       |
|--------------------|------------------------------------------------------|----------------------------------------------|
| `web01` (Nginx)    | Application Load Balancer + ACM cert                 | Managed L7 LB, free TLS, healthchecks        |
| `app01` (Tomcat)   | EC2 Auto Scaling Group in private subnet (min=2, max=4) | Multi-AZ HA, autoscale on CPU             |
| `db01` (MariaDB)   | RDS MySQL Multi-AZ                                   | Managed backups, automatic failover          |
| `mc01` (Memcached) | ElastiCache (Memcached engine)                       | Managed cache, can be Multi-AZ               |
| `rmq01` (RabbitMQ) | Amazon MQ (RabbitMQ engine)                          | Managed broker, can be HA pair               |
| `/etc/hosts`       | Route 53 Private Hosted Zone (`vprofile.internal`)   | DNS for service-to-service lookups           |
| Self-signed cert   | AWS Certificate Manager (free)                       | Real public CA, free auto-renewal            |
| `firewalld` zones  | VPC Security Groups                                  | Source-IP/SG-ID allow-lists, default deny    |
| Single 56.0/24     | VPC with public + private subnets in 2 AZs           | HA, isolated backend, NAT for egress         |
| Tomcat WAR upload  | S3 + EC2 IAM role for download at boot               | Stateless, signed URLs, no SSH needed        |
| Manual provisioning| Terraform + user-data script                         | Reproducible, version-controlled             |

## Target VPC topology

```
VPC 10.0.0.0/16

├── AZ us-east-1a
│   ├── public subnet  10.0.1.0/24   (ALB, NAT GW)
│   └── private subnet 10.0.2.0/24   (Tomcat, RDS primary, ElastiCache, Amazon MQ)
│
└── AZ us-east-1b
    ├── public subnet  10.0.3.0/24   (ALB target)
    └── private subnet 10.0.4.0/24   (Tomcat, RDS standby, ElastiCache replica)
```

Multi-AZ matters because real AWS deployments survive an entire data
center going down. The local lab doesn't simulate this — that's what
real cloud is for.

## Cost estimate

Conservative ballpark for a 24/7 production-quality deployment. Region:
`us-east-1`. As of mid-2026:

| Service                        | Configuration               | Monthly cost |
|--------------------------------|-----------------------------|--------------|
| ALB                            | 1 load balancer             | ~$16         |
| NAT Gateway (1 per AZ)         | 2 × ~$32                    | ~$64         |
| EC2 (Tomcat ASG)               | 2 × t3.small (2 GB, $0.0208/hr) | ~$30   |
| RDS MySQL Multi-AZ             | db.t3.small + standby + 20GB | ~$60        |
| ElastiCache Memcached          | 1 × cache.t3.micro          | ~$13         |
| Amazon MQ RabbitMQ             | 1 × mq.t3.micro             | ~$20         |
| Route 53 Private Hosted Zone   | 1 zone, low query volume    | ~$0.50       |
| ACM certificate                | DNS-validated public cert   | $0 (free)    |
| Data transfer                  | Light internal traffic      | ~$5          |
| S3 (artifact bucket)           | Small WAR storage           | ~$1          |
| CloudWatch (basic)             | Standard metrics, no logs   | ~$5          |
| **Total**                      |                             | **~$215/mo** |

Optimizations that would lower this:

- Single-AZ NAT Gateway (sacrifices HA for egress) → saves $32
- RDS not Multi-AZ → saves ~$30 (sacrifices automatic failover)
- Spot instances for Tomcat ASG → saves ~50% on EC2
- Reserved Instances or Savings Plans (1-year) → saves ~30% across the board

A "demo-style" config (single AZ, no Multi-AZ RDS, smallest instance sizes)
would run around **$80/month**. That's the realistic "I deployed my own
side project to AWS" budget for someone learning.

## Terraform skeleton

A real Terraform implementation lives in the future Project 4
(`terraform-aws-vprofile-stack`). The skeleton below shows the shape:

### VPC

```hcl
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "vprofile-vpc"
  cidr = "10.0.0.0/16"

  azs              = ["us-east-1a", "us-east-1b"]
  public_subnets   = ["10.0.1.0/24", "10.0.3.0/24"]
  private_subnets  = ["10.0.2.0/24", "10.0.4.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = false   # one NAT per AZ for HA
}
```

### Security groups (firewalld replacement)

```hcl
resource "aws_security_group" "alb" {
  vpc_id = module.vpc.vpc_id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "app" {
  vpc_id = module.vpc.vpc_id
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
}

resource "aws_security_group" "backend" {
  vpc_id = module.vpc.vpc_id

  dynamic "ingress" {
    for_each = { db = 3306, cache = 11211, mq = 5672 }
    content {
      from_port       = ingress.value
      to_port         = ingress.value
      protocol        = "tcp"
      security_groups = [aws_security_group.app.id]
    }
  }
}
```

### ALB (Nginx replacement)

```hcl
resource "aws_lb" "alb" {
  name               = "vprofile-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = module.vpc.public_subnets
  security_groups    = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.cert.arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
```

### ASG (Tomcat replacement)

```hcl
resource "aws_launch_template" "app" {
  name_prefix   = "vprofile-app-"
  image_id      = data.aws_ami.amzn_linux.id
  instance_type = "t3.small"

  iam_instance_profile {
    name = aws_iam_instance_profile.app.name   # to fetch WAR from S3
  }

  user_data = base64encode(templatefile("user-data/tomcat.sh", {
    db_host    = aws_route53_record.db.fqdn
    cache_host = aws_route53_record.cache.fqdn
    mq_host    = aws_route53_record.mq.fqdn
  }))

  vpc_security_group_ids = [aws_security_group.app.id]
}

resource "aws_autoscaling_group" "app" {
  name                = "vprofile-app"
  min_size            = 2
  max_size            = 4
  desired_capacity    = 2
  vpc_zone_identifier = module.vpc.private_subnets

  launch_template { id = aws_launch_template.app.id }
  target_group_arns = [aws_lb_target_group.app.arn]
}
```

### RDS (MariaDB replacement)

```hcl
resource "aws_db_instance" "mysql" {
  identifier             = "vprofile-db"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.small"
  allocated_storage      = 20
  username               = "admin"
  password               = var.db_password   # from Secrets Manager
  vpc_security_group_ids = [aws_security_group.backend.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  multi_az               = true
  skip_final_snapshot    = false
}
```

### Route 53 Private Hosted Zone (`/etc/hosts` replacement)

```hcl
resource "aws_route53_zone" "internal" {
  name = "vprofile.internal"
  vpc { vpc_id = module.vpc.vpc_id }
}

resource "aws_route53_record" "db" {
  zone_id = aws_route53_zone.internal.zone_id
  name    = "db.vprofile.internal"
  type    = "CNAME"
  ttl     = 300
  records = [aws_db_instance.mysql.address]
}
# ... same for cache, mq
```

The application's `application.properties` then becomes:

```properties
jdbc.url=jdbc:mysql://db.vprofile.internal:3306/accounts
memcached.active.host=cache.vprofile.internal
rabbitmq.address=mq.vprofile.internal
```

## What changes in the application code

**Almost nothing.**

The application connects to backends by hostname. In the lab, those
hostnames resolve via `/etc/hosts`. In AWS, they resolve via Route 53.
The application is unaware of which mechanism is in play.

The only changes when going to production:

1. `application.properties` reads hostnames from environment variables
   (injected by the launch template's user-data) instead of being hardcoded.
2. Database password comes from AWS Secrets Manager (fetched at startup
   via the instance's IAM role) instead of being in the config file.
3. The WAR is downloaded from S3 at boot instead of being copied during
   provisioning.

That's it. Three changes. The application code itself is identical
between the lab and production. **This is the goal of any good
local-to-production setup** — minimize the "in production this is
different" surface area.

## Things this plan deliberately doesn't cover

- **Cross-region disaster recovery.** Out of scope for a 5-VM lab to model.
  Would add a read-replica RDS in `us-west-2`, an S3 cross-region replica
  bucket, and Route 53 health-check-based failover.
- **WAF / Shield.** Real public services would add AWS WAF in front of the
  ALB. ~$5/month base + per-rule charges.
- **Logging pipeline.** CloudWatch Logs → Kinesis Firehose → S3 for
  long-term retention. Not modeled locally — that's Project 6's territory.
- **CI/CD.** Building the WAR and rolling it out to the ASG is Project 5
  (`vprofile-cicd-pipeline`). The deployment model here assumes a working
  pipeline pushes a new WAR to S3 and triggers an instance refresh.
- **Cost monitoring.** Production would have AWS Budgets alerts at $50,
  $100, $200 thresholds.

These are all reasonable extensions, just not within the scope of this
single project. The portfolio plan builds them up across the six projects.
