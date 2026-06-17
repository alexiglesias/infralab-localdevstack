# Setup

This project supports two free hypervisors. Use whichever matches your OS.

## Linux / Windows / Intel Mac → VirtualBox

```bash
# macOS (Intel)
brew install --cask virtualbox vagrant

# Ubuntu / Debian
sudo apt-get install -y virtualbox vagrant

# Windows: download from virtualbox.org and vagrantup.com
```

## Apple Silicon Mac (M1/M2/M3/M4) → VMware Fusion

VMware Fusion has been free for personal use since November 2024. Sign up
for a free Broadcom account to download.

```bash
# Install Fusion from https://www.vmware.com/products/fusion.html
brew install --cask vagrant
vagrant plugin install vagrant-vmware-desktop
```

## Install the hostmanager plugin (required on every OS)

```bash
vagrant plugin install vagrant-hostmanager
```

This plugin maintains `/etc/hosts` entries on both the host and the guests
so the VMs can resolve each other (and you, on the host) by hostname.

On the **host**, the plugin needs sudo access to edit `/etc/hosts`. On
first run it will prompt for your password. On macOS you can grant
passwordless access by adding this line to `/etc/sudoers.d/vagrant`:

```
%admin ALL=(root) NOPASSWD: /usr/bin/tee -a /etc/hosts
%admin ALL=(root) NOPASSWD: /usr/bin/sed -i -e */etc/hosts
```

## Bring up the stack

```bash
make up
```

(equivalent to `vagrant up --no-parallel`)

The `--no-parallel` flag matters — Tomcat provisioning expects the
backend VMs to be reachable, so they have to come up first in the order
defined in the Vagrantfile.

Total time on a recent laptop: about 15 minutes for the first run
(downloads the CentOS box, Erlang, Java, Maven, Tomcat). Subsequent
`vagrant up` runs after a halt take about 90 seconds.

## Verify

```bash
make smoketest
```

If all checks pass, open `https://192.168.57.11/` in your browser. Accept
the self-signed certificate warning, then log in as `admin` /
`asongoficeandfire`.

## Common operations

```bash
make status       # see which VMs are running
make halt         # stop all VMs (preserves state)
make destroy      # destroy all VMs (full rebuild required)
make ssh-app      # SSH into app01 (also: ssh-web, ssh-db)
```

## Troubleshooting

**Smoketest L1 (ping) fails:** the VM didn't come up. Check `vagrant status`
and `vagrant up <name>` the missing one.

**Smoketest L2 (port) fails but L1 passes:** the service didn't start.
SSH in (`make ssh-db` etc.) and check `systemctl status <service>`.

**Smoketest L3 (HTTPS) fails but L2 passes:** application didn't deploy.
Check `/opt/tomcat/logs/catalina.out` on `app01` for a stack trace.

**"vagrant up" hangs forever on a single VM:** usually a missing
`vagrant-hostmanager` plugin or a sudoers prompt waiting silently on the
host. Run `vagrant plugin list` to verify, and check for stale `sudo`
prompts in the terminal.

**Apple Silicon: VMware Fusion can't find the box:** the box names in the
Vagrantfile target the standard ARM-compatible boxes (`bento/centos-stream-9`).
If `vagrant box add` fails, the box has likely been renamed upstream —
search the Vagrant Cloud for a current `centos-stream-9` ARM box and
update the `VMWARE_ARM_BOX` constant at the top of the Vagrantfile.
