.PHONY: help up down halt destroy provision status smoketest ssh-web ssh-app ssh-db lint

help:  ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'

up:  ## Bring up all 5 VMs in dependency order
	vagrant up --no-parallel

halt:  ## Stop all VMs (preserves state)
	vagrant halt

destroy:  ## Destroy all VMs (free disk, full rebuild required)
	vagrant destroy -f

status:  ## Show status of all VMs
	vagrant status

provision:  ## Re-run provisioning scripts on existing VMs
	vagrant provision

smoketest:  ## Run the smoke test against the running stack
	@bash scripts/smoketest.sh

ssh-web:  ## SSH into the Nginx VM
	vagrant ssh web01

ssh-app:  ## SSH into the Tomcat VM
	vagrant ssh app01

ssh-db:  ## SSH into the MariaDB VM
	vagrant ssh db01

lint:  ## Lint all provisioning scripts with shellcheck (if installed)
	@command -v shellcheck >/dev/null 2>&1 && shellcheck provisioning/*.sh scripts/*.sh || echo "shellcheck not installed; skipping"
