# Network Topology

## IP plan

All five VMs sit on a single private network: `192.168.57.0/24` (Vagrant's
default host-only network for the VirtualBox provider; VMware Fusion
mirrors this).

| Hostname | IP              | Role                                       |
|----------|-----------------|--------------------------------------------|
| `web01`  | 192.168.57.11   | Nginx reverse proxy (Internet-facing)      |
| `app01`  | 192.168.57.12   | Tomcat application server                  |
| `mc01`   | 192.168.57.14   | Memcached cache                            |
| `db01`   | 192.168.57.15   | MariaDB primary                            |
| `rmq01`  | 192.168.57.16   | RabbitMQ broker                            |

`192.168.57.13` is intentionally skipped — reserved for a second Tomcat
node if you want to demonstrate horizontal scaling.

## Hostname resolution

The application connects to backends by hostname (`jdbc:mysql://db01:3306/...`),
not by IP. This works because the [vagrant-hostmanager](https://github.com/devopsgroup-io/vagrant-hostmanager)
plugin writes `/etc/hosts` entries on every VM during boot:

```
# /etc/hosts on every VM (managed by vagrant-hostmanager)
192.168.57.11   web01
192.168.57.12   app01
192.168.57.14   mc01
192.168.57.15   db01
192.168.57.16   rmq01
```

The plugin also writes these entries to the **host machine's** `/etc/hosts`,
so on your laptop you can also do `curl https://web01/` and `ssh vagrant@db01`.

### Why not just use IPs

Three reasons:

1. **Portability.** If someone clones the repo and their Vagrant subnet
   happens to be `192.168.57.0/24` instead, hostnames keep working.
2. **It matches production.** AWS Route 53 Private Hosted Zones do the same
   thing — services connect to `db.vprofile.internal`, not `10.0.2.47`.
3. **It survives DNS changes.** If you replace `db01` with a Multi-AZ pair
   later, the hostname can point at the new endpoint without the application
   ever knowing.

## Security matrix

Each backend VM runs `firewalld` configured to allow only the app subnet
on the relevant port. Everything else is denied at the kernel level.

| Source           | Destination | Port  | Protocol | Why                              |
|------------------|-------------|-------|----------|----------------------------------|
| Host machine     | web01       | 443   | TCP      | User-facing HTTPS                |
| Host machine     | web01       | 80    | TCP      | Redirects to 443                 |
| web01            | app01       | 8080  | TCP      | Reverse proxy backend            |
| app01            | db01        | 3306  | TCP      | MySQL/MariaDB protocol           |
| app01            | mc01        | 11211 | TCP      | Memcached binary protocol        |
| app01            | rmq01       | 5672  | TCP      | AMQP                             |
| Vagrant host     | any VM      | 22    | TCP      | `vagrant ssh` (open by default)  |
| *anything else*  | backend VMs | -     | -        | DENIED by firewalld              |

### How firewalld implements this

On each backend VM, the provisioning script creates a custom firewalld
**zone** called `appnet`, attaches the application subnet as the source,
and adds the relevant port:

```bash
firewall-cmd --permanent --new-zone=appnet
firewall-cmd --permanent --zone=appnet --add-source=192.168.57.0/24
firewall-cmd --permanent --zone=appnet --add-port=3306/tcp
firewall-cmd --reload
```

Anything matching the source IP (the app subnet) hits the `appnet` zone
and finds 3306 open. Anything else hits the default zone (`public`), which
has no services exposed → connection refused.

### AWS Security Group equivalent

The same restrictions on AWS would be three Security Groups:

```hcl
resource "aws_security_group" "alb" {
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # public
  }
}

resource "aws_security_group" "app" {
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]  # ALB only
  }
}

resource "aws_security_group" "backend" {
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]  # app only
  }
  # ... repeat for 11211, 5672
}
```

Same shape, different mechanism. firewalld matches on source IP; SGs match
on source security-group-ID. The latter is more dynamic (instances can
change IPs without breaking the rule), but conceptually identical.

## Ports exposed by the VMs

A `nmap` from the Vagrant host shows:

```
Host: 192.168.57.11 (web01)
  22/tcp   open  ssh        (Vagrant SSH)
  80/tcp   open  http       (Nginx, redirects to 443)
  443/tcp  open  https      (Nginx)

Host: 192.168.57.12 (app01)
  22/tcp   open  ssh        (Vagrant SSH)
  8080/tcp open  http-proxy (Tomcat — but blocked from non-app01 sources)

Host: 192.168.57.15 (db01)
  22/tcp   open  ssh        (Vagrant SSH)
  3306/tcp open  mysql      (only from app subnet)

# mc01 and rmq01 similar
```

The only port a real user would hit is 443 on web01. Everything else is
internal.

## Why a single `/24` instead of public/private subnets

Vagrant's single host-only network keeps the lab simple. In production AWS,
the equivalent setup uses **two subnets per AZ**:

| AZ-A subnet           | Contents                                  |
|------------------------|-------------------------------------------|
| `10.0.1.0/24` public   | ALB (web01 equivalent)                    |
| `10.0.2.0/24` private  | Tomcat, RDS, ElastiCache, Amazon MQ       |

Routes:
- Public subnet → Internet Gateway (allows inbound from anywhere)
- Private subnet → NAT Gateway in public subnet (outbound only for OS updates)

The backend services have no direct route to the internet — they can be
reached *only* through the ALB. This is the standard "bastion architecture"
and it's documented in the migration plan with Terraform pseudocode.
