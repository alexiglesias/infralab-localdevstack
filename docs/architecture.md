# Architecture

This document explains *why* the stack is built the way it is, beyond
what the README's diagram shows.

## The application

[VProfile](https://github.com/hkhcoder/vprofile-project) is a Java web
application that simulates a user-management service: signup, login,
account lookup, password updates. It was originally written as a teaching
vehicle for the classic enterprise Java deployment pattern, and it touches
every layer that pattern depends on. That's what makes it useful as an
infrastructure exercise — provisioning a "hello world" web app teaches
you nothing about real fleet operations.

The application does four interesting things:

1. **Authenticates users** against a relational database (MariaDB)
2. **Caches lookups** in Memcached to avoid hammering the DB
3. **Publishes events** (signups, password changes) to a RabbitMQ queue
   that worker processes consume asynchronously
4. **Exposes an HTTP interface** behind a reverse proxy (Nginx) that
   handles HTTPS termination

Each of those four concerns lives on its own VM.

## Why five VMs and not one

You *could* run all of this on a single VM with five `systemd` services.
Many tutorials do. There are two reasons not to:

**Reason 1: It teaches the wrong mental model.** In production, these
services don't share a host. MariaDB runs on RDS; Memcached runs on
ElastiCache; RabbitMQ runs on Amazon MQ; Tomcat runs on Auto Scaling Group
EC2 instances behind an ALB. Each is a separate "machine" with its own
network identity, firewall rules, and failure mode. A one-VM lab doesn't
prepare you to think about cross-service networking, security groups, or
DNS resolution between services. A five-VM lab does.

**Reason 2: It hides the failure modes.** When MariaDB crashes on a
single-VM setup, Tomcat keeps running and "just" hits database errors.
When MariaDB crashes on `db01`, Tomcat on `app01` hits *connection-refused*
errors — a fundamentally different signal that resembles what real outages
look like.

## Why CentOS Stream 9

The course material this project follows uses RHEL-family Linux throughout,
so the entire stack uses CentOS Stream 9 (the upstream development branch
of RHEL 9). Practically, this means:

- **Package manager:** `dnf` (replaced `yum` around RHEL 8)
- **Firewall:** `firewalld` instead of `ufw` (Ubuntu's tool)
- **Mandatory access control:** SELinux is enabled by default and *will*
  block Nginx from reverse-proxying to Tomcat unless you set
  `httpd_can_network_connect`. The `nginx.sh` script handles this; it's
  the kind of CentOS-specific gotcha you only learn the hard way.
- **Init system:** `systemd` (same as modern Ubuntu, but the unit files
  live in slightly different paths)

Knowing your way around RHEL-family Linux is a differentiator on a
resume — most online tutorials default to Ubuntu, so a CentOS portfolio
project signals broader Linux fluency.

## Why the specific service versions

| Component        | Version    | Why                                              |
|------------------|-----------|--------------------------------------------------|
| Java             | 17 (LTS)   | Current Java LTS. Java 8 is EOL.                 |
| Maven            | system     | Whatever CentOS ships — version doesn't matter   |
| Tomcat           | 10.1       | Tomcat 10+ requires `jakarta.*` packages (Jakarta EE 9). The VProfile branch we use has been updated for this. |
| MariaDB          | 10.5       | CentOS Stream 9 default — compatible with MySQL 5.7 wire protocol |
| Memcached        | system     | Tiny binary, version drift doesn't matter        |
| RabbitMQ         | 3.x        | From official PackageCloud repos (CentOS default RMQ is old) |
| Erlang           | 26.x       | Required by RabbitMQ 3.12+                       |
| Nginx            | system     | CentOS default is fine                           |

## Provisioning order matters

Tomcat's startup tries to connect to all three backend services. If `db01`,
`mc01`, or `rmq01` aren't up yet, the application logs errors and may
silently fail to register endpoints. The Vagrantfile defines the VMs in
dependency order:

```
db01 → mc01 → rmq01 → app01 → web01
```

`--no-parallel` (built into `make up`) honors that order. Without it,
Vagrant brings up all five VMs in parallel and Tomcat usually wins the
race against the database, breaking the boot.

In production AWS, this dependency problem is solved differently:
Tomcat's ASG launch template waits for the RDS instance to be `available`
before launching, and Tomcat itself retries connections on startup. The
local lab uses a simpler "start them in order" pattern because it's
sufficient for development.

## Network and security

See [`network-topology.md`](network-topology.md) for the full IP plan,
hostname resolution mechanism, and security group/firewall matrix.

The short version:

- Single `192.168.57.0/24` private network (Vagrant's default
  host-only network)
- `vagrant-hostmanager` plugin maintains `/etc/hosts` on every VM →
  hostnames work everywhere without a real DNS server
- `firewalld` on each backend VM allows the app subnet on the relevant
  port only → all other access is denied at the kernel level

## How this maps to AWS

See [`aws-migration-plan.md`](aws-migration-plan.md) for the full migration
plan with cost estimates.

The headline mapping:

| Local       | AWS                                              |
|-------------|--------------------------------------------------|
| `web01`     | Application Load Balancer + ACM certificate     |
| `app01`     | EC2 Auto Scaling Group (min=2, max=4) in private subnet |
| `db01`      | RDS MySQL Multi-AZ                              |
| `mc01`      | ElastiCache (Memcached engine)                  |
| `rmq01`     | Amazon MQ (RabbitMQ engine)                     |
| `/etc/hosts`| Route 53 Private Hosted Zone                    |
| `firewalld` | VPC Security Groups                             |

The application code is **identical** in both environments. The only
configuration change is the hostnames in `application.properties` (which
in production are pulled from environment variables injected by the ASG
launch template, populated from Terraform outputs).

## What this lab doesn't simulate

Honest limits worth knowing for interviews:

- **No high availability.** One DB, one cache, one queue. AWS would
  Multi-AZ all three. Documented as a "future work" item in the migration
  plan.
- **No autoscaling.** One Tomcat instance. AWS ASG would manage 2-4.
- **No real DNS.** `/etc/hosts` via plugin works locally but doesn't
  exercise the DNS-resolution behaviors (TTL, caching, etc.) that real
  services have.
- **No production secrets management.** Passwords are in scripts and
  config files. AWS would use Secrets Manager or Parameter Store. The
  migration plan covers this.
- **No real load.** Locust or k6 would exercise the cache and message
  broker meaningfully; smoke tests only prove things are listening.

These aren't failures of the lab — they're scope decisions. A local
five-VM lab can't simulate Multi-AZ; that's what real AWS is for. The
lab teaches the architecture; the migration plan documents what
production adds on top.
