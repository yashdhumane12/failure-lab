#!/bin/bash
# ── Scenario 4: Break DNS ─────────────────────────────────────────────
# Goal: rename a service so DNS resolution fails — observe timeout behavior

set -euo pipefail

echo "=== Scenario: Break DNS ==="
echo ""
echo "[1] Normal DNS resolution works:"
docker exec lab-app sh -c "nslookup postgres && echo 'DNS: OK'"

echo ""
echo "[2] Test /dns endpoint:"
curl -s http://localhost:8080/dns | python3 -m json.tool

echo ""
echo "[3] Simulate DNS failure by using wrong hostname:"
docker exec lab-app sh -c "
  echo 'Trying to resolve nonexistent-db...'
  nslookup nonexistent-db 2>&1 | head -5 || true
  echo ''
  echo 'Trying with nc -zv (3s timeout)...'
  nc -zv nonexistent-db 5432 2>&1 || true
"

echo ""
echo "[4] K8s DNS break simulation:"
echo "  # Rename a service — DNS stops working for pods using old name"
echo "  kubectl get svc"
echo "  kubectl patch svc my-db --patch '{\"metadata\":{\"name\":\"my-db-v2\"}}'"
echo "  # Now pods trying to connect to 'my-db' get NXDOMAIN"
echo ""
echo "  # Debug DNS from inside a pod:"
echo "  kubectl run dns-debug --rm -it --image=busybox -- sh"
echo "  > nslookup my-db"
echo "  > nslookup my-db.default.svc.cluster.local"
echo "  > cat /etc/resolv.conf"
echo ""
echo "  # Check CoreDNS:"
echo "  kubectl logs -n kube-system -l k8s-app=kube-dns"
echo ""
echo "  # Common fix: check service name matches what app uses"
echo "  kubectl get svc -A | grep <service-name>"

echo ""
echo "[5] Connection timeout vs DNS failure difference:"
echo "  DNS failure  → immediate NXDOMAIN error (< 1s)"
echo "  Conn refused → immediate TCP RST (< 1s)"
echo "  Firewall drop → timeout after connect_timeout (3-30s)"
