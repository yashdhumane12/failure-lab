# Runbook: Database Failure

## Scenario
Postgres container stops unexpectedly.

## Detection
- `/health` returns `503` with `"postgres": "connection refused"`
- Alert: `AppDown` or `HighErrorRate` fires in Alertmanager

## Immediate Steps

```bash
# 1. Confirm DB is down
docker ps | grep postgres
docker logs lab-postgres --tail=50

# 2. Check if disk is full (common cause)
docker exec lab-postgres df -h /

# 3. Check for OOM kill
dmesg | grep -i oom | tail -10

# 4. Restart if safe
docker start lab-postgres

# 5. Verify recovery
sleep 5
curl http://localhost:8080/health
```

## Recovery Verification
```bash
# Check replication if applicable
docker exec lab-postgres psql -U appuser -d appdb \
  -c "SELECT COUNT(*) FROM pg_stat_replication;"

# Check for data corruption
docker exec lab-postgres psql -U appuser -d appdb \
  -c "SELECT schemaname, tablename, n_live_tup FROM pg_stat_user_tables;"
```

## Post-Incident
- Was data lost? Check last backup timestamp
- Update monitoring: add postgres container health alert
- Consider: connection pooling (PgBouncer) to handle brief outages
