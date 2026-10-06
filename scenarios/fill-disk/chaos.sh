#!/bin/bash
# ── Scenario 3: Fill the Disk ─────────────────────────────────────────
# Goal: observe what breaks when disk is full — DB first? App logs?

set -euo pipefail

CONTAINER="lab-postgres"
FILL_PATH="/tmp/disk-fill"

echo "=== Scenario: Fill Disk ==="
echo ""
echo "[1] Current disk usage inside postgres container:"
docker exec "$CONTAINER" df -h /

echo ""
echo "[2] Filling disk with junk data in /tmp (safe — won't corrupt PG data dir)..."
echo "    Creating 500MB file..."
docker exec "$CONTAINER" sh -c "dd if=/dev/zero of=$FILL_PATH bs=1M count=500 2>&1"

echo ""
echo "[3] Disk after fill:"
docker exec "$CONTAINER" df -h /

echo ""
echo "[4] Try writing to postgres while disk is getting full:"
docker exec lab-postgres psql -U appuser -d appdb -c \
  "CREATE TABLE IF NOT EXISTS disk_test(id serial, data text);
   INSERT INTO disk_test (data) SELECT md5(random()::text) FROM generate_series(1,1000);" \
  2>&1 | head -20

echo ""
echo "[5] Cleaning up the fill file..."
docker exec "$CONTAINER" rm -f "$FILL_PATH"

echo ""
echo "[6] Disk after cleanup:"
docker exec "$CONTAINER" df -h /

echo ""
echo "=== What to observe ==="
echo "  - At what % does Postgres refuse writes? (usually >95%)"
echo "  - Does the app return 503 or 500 for DB errors?"
echo "  - Are there 'no space left on device' errors in logs?"
echo "  docker logs lab-postgres | tail -20"
