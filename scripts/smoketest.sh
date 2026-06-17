#!/usr/bin/env bash
#
# smoketest.sh — verify the full stack is healthy.
#
# Run from the host AFTER `vagrant up --no-parallel` has completed.

set -euo pipefail

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly NC='\033[0m'

pass_count=0
fail_count=0

check() {
    local label="$1"
    local cmd="$2"
    printf '  %-50s' "$label"
    if eval "$cmd" &>/dev/null; then
        printf "${GREEN}OK${NC}\n"
        pass_count=$((pass_count + 1))
    else
        printf "${RED}FAIL${NC}\n"
        fail_count=$((fail_count + 1))
    fi
}

echo "infralab smoke test"
echo "==================="
echo ""

echo "L1: Network reachability"
check "db01  (192.168.56.25) responds to ping" "ping -c 1 -W 2 192.168.56.25"
check "mc01  (192.168.56.24) responds to ping" "ping -c 1 -W 2 192.168.56.24"
check "rmq01 (192.168.56.23) responds to ping" "ping -c 1 -W 2 192.168.56.23"
check "app01 (192.168.56.22) responds to ping" "ping -c 1 -W 2 192.168.56.22"
check "web01 (192.168.56.21) responds to ping" "ping -c 1 -W 2 192.168.56.21"
echo ""

echo "L2: Service ports open"
check "MariaDB   (db01:3306)    " "nc -zw 2 192.168.56.25 3306"
check "Memcached (mc01:11211)   " "nc -zw 2 192.168.56.24 11211"
check "RabbitMQ  (rmq01:5672)   " "nc -zw 2 192.168.56.23 5672"
check "Tomcat    (app01:8080)   " "nc -zw 2 192.168.56.22 8080"
check "Nginx     (web01:80)     " "nc -zw 2 192.168.56.21 80"
echo ""

echo "L3: Application response"
check "App returns login page" \
    "curl -s http://192.168.56.21/ | grep -qi 'login\|password\|vprofile'"
echo ""

echo "==================="
total=$((pass_count + fail_count))
if [[ $fail_count -eq 0 ]]; then
    printf "${GREEN}All %d checks passed.${NC}\n" "$total"
    echo "Open http://192.168.56.21/ in your browser and log in as admin / admin123."
    exit 0
else
    printf "${YELLOW}%d of %d checks failed.${NC}\n" "$fail_count" "$total"
    echo "Check 'vagrant status' and the per-VM logs to diagnose."
    exit 1
fi
