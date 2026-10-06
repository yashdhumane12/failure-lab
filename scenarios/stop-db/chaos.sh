#!/bin/bash
# ── Scenario 2: Stop the Database ────────────────────────────────────
# Goal: observe app behavior when DB goes down — graceful degradation?

set -euo pipefail
WATCH_URL="http://localhost:8080"

observe() {
  echo -n "  GET /health → "
  curl -s "$WATCH_URL/health" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['status'], '|', json.dumps(d['checks']))" 2>/dev/null || echo "NO RESPONSE"
  echo -n "  GET /db     → "
  curl -s -o /dev/null -w "HTTP %{http_code}\n" "$WATCH_URL/db"
}

echo "=== Scenario: Stop Database ==="
echo ""
echo "[1] Baseline — everything working:"
observe

echo ""
echo "[2] Stopping postgres..."
docker stop lab-postgres

echo ""
echo "[3] App behavior with no DB (observe degraded vs crashed):"
for i in $(seq 1 6); do
  echo "  --- attempt $i ---"
  observe
  sleep 2
done

echo ""
echo "[4] Restarting postgres..."
docker start lab-postgres
sleep 8

echo ""
echo "[5] Recovery — DB back up:"
observe

echo ""
echo "=== What to look for ==="
echo "  - Does /health return 503 with 'postgres: error' detail?"
echo "  - Does /db return 503 gracefully or 500 with stack trace?"
echo "  - Does the app crash or stay running in degraded state?"
echo "  - How long until recovery after DB restarts?"
