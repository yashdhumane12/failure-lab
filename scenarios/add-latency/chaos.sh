#!/bin/bash
# ── Scenario 5: Add Network Latency (tc / toxiproxy) ─────────────────
# Goal: simulate slow DB / network — observe timeout cascades

set -euo pipefail

echo "=== Scenario: Add Network Latency ==="
echo ""
echo "Method A: tc (traffic control) — adds latency at network level"
echo "Method B: toxiproxy — proxy with configurable delays"
echo ""

# ─── Method A: tc inside container ──────────────────────────────────
echo "=== Method A: tc netem ==="
echo "[1] Baseline DB query latency:"
for i in $(seq 1 3); do
  curl -s http://localhost:8080/db | python3 -c "import sys,json; d=json.load(sys.stdin); print(f'  latency: {d.get(\"latency_ms\",\"err\")}ms')" 2>/dev/null || echo "  error"
done

echo ""
echo "[2] Adding 200ms latency to postgres container network..."
docker exec lab-postgres sh -c "
  apk add --no-cache iproute2 2>/dev/null;
  tc qdisc add dev eth0 root netem delay 200ms 2>/dev/null || \
  tc qdisc change dev eth0 root netem delay 200ms
" 2>&1 | tail -3

echo ""
echo "[3] DB query latency with 200ms added:"
for i in $(seq 1 3); do
  curl -s http://localhost:8080/db | python3 -c "import sys,json; d=json.load(sys.stdin); print(f'  latency: {d.get(\"latency_ms\",\"err\")}ms')" 2>/dev/null || echo "  error"
done

echo ""
echo "[4] Removing latency..."
docker exec lab-postgres sh -c "tc qdisc del dev eth0 root 2>/dev/null || true"

echo ""
echo "=== Method B: toxiproxy (better for production simulation) ==="
echo "  docker run -d --name toxiproxy -p 8474:8474 -p 5435:5435 ghcr.io/shopify/toxiproxy"
echo ""
echo "  # Create proxy: client → toxiproxy:5435 → postgres:5432"
echo "  curl -X POST http://localhost:8474/proxies -d '{\"name\":\"pg\",\"listen\":\"0.0.0.0:5435\",\"upstream\":\"lab-postgres:5432\"}'"
echo ""
echo "  # Add 500ms latency"
echo "  curl -X POST http://localhost:8474/proxies/pg/toxics -d '{\"name\":\"latency\",\"type\":\"latency\",\"attributes\":{\"latency\":500}}'"
echo ""
echo "  # Add packet loss (10%)"
echo "  curl -X POST http://localhost:8474/proxies/pg/toxics -d '{\"name\":\"loss\",\"type\":\"latency\",\"attributes\":{\"latency\":0,\"jitter\":100}}'"
echo ""
echo "  # Remove toxic"
echo "  curl -X DELETE http://localhost:8474/proxies/pg/toxics/latency"
