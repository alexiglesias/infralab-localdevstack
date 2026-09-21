# Network Topology

## IP plan

All five VMs sit on a single private network: `192.168.57.0/24` (Vagrant's default host-only network for the VirtualBox provider; VMware Fusion mirrors this).

| Hostname | IP              | Role                                       |
|----------|-----------------|--------------------------------------------|
| `web01`  | 192.168.57.11   | Nginx reverse proxy (Internet-facing)      |
| `app01`  | 192.168.57.12   | Tomcat application server                  |
| `mc01`   | 192.168.57.14   | Memcached cache                            |
| `db01`   | 192.168.57.15   | MariaDB primary                            |
| `rmq01`  | 192.168.57.16   | RabbitMQ broker                            |

`192.168.57.13` is intentionally skipped — reserved for a second Tomcat node if you want to demonstrate horizontal scaling.

The application connects to backends by hostname (`jdbc:mysql://db01:3306/...`),
not by IP. This works because the [vagrant-hostmanager](https://github.com/devopsgroup-io/vagrant-hostmanager). The plugin writes `/etc/hosts` entries on every VM during boot. The plugin also writes these entries to the **host machine's** `/etc/hosts`,
so on your laptop you can also do `curl https://web01/` and `ssh vagrant@db01`.

## Security matrix

Each backend VM runs `firewalld` configured to allow only the app subnet on the relevant port. Everything else is denied at the kernel level.

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

