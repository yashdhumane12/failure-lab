#!/bin/bash
# ── Scenario 1: Kill Pods / Containers ───────────────────────────────
# Goal: observe how Nginx/k8s handles a dead upstream and restarts it

set -euo pipefail
APP="lab-app"
WATCH_URL="http://localhost:8080/health"

observe() {
  echo -n "  Health: "
  curl -s -o /dev/null -w "%{http_code}" "$WATCH_URL" 2>/dev/null || echo "FAILED"
  echo ""
}

echo "=== Scenario: Kill App Container ==="
echo ""
echo "[1] Current state:"
observe

echo "[2] Killing $APP..."
docker stop "$APP"

echo "[3] Health during downtime (expect 502/503 from Nginx):"
for i in $(seq 1 5); do observe; sleep 1; done

echo "[4] Restarting $APP..."
docker start "$APP"

echo "[5] Waiting for app to recover..."
sleep 5
for i in $(seq 1 5); do observe; sleep 1; done

echo ""
echo "=== K8s equivalent commands ==="
echo "  # Delete a pod (k8s restarts it automatically)"
echo "  kubectl delete pod <pod-name>"
echo ""
echo "  # Simulate OOMKill"
echo "  kubectl exec <pod-name> -- stress --vm 1 --vm-bytes 500M"
echo ""
echo "  # Watch pods restart"
echo "  kubectl get pods -w"
echo ""
echo "  # Check restart count"
echo "  kubectl get pods -o wide | awk '{print \$1, \$4}'"
