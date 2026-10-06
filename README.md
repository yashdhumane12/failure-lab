# 💥 Failure Lab — Break Things, Learn to Fix Them

5 chaos engineering scenarios against a live app. Run each one, observe what breaks, debug it, and fill in the incident runbook.

## Philosophy
> "The only way to get good at incidents is to have them intentionally."

## Setup
```bash
docker compose up -d --build
# Verify everything is up
curl http://localhost:8080/health
```

## Scenarios

| # | Scenario | Script | What breaks |
|---|----------|--------|-------------|
| 1 | Kill app container | `scenarios/kill-pods/chaos.sh` | 502 from Nginx |
| 2 | Stop database | `scenarios/stop-db/chaos.sh` | 503 on /db, degraded health |
| 3 | Fill disk | `scenarios/fill-disk/chaos.sh` | DB write failures |
| 4 | Break DNS | `scenarios/break-dns/chaos.sh` | NXDOMAIN → connection timeout |
| 5 | Add latency | `scenarios/add-latency/chaos.sh` | Slow responses, timeout cascades |

## How to run
```bash
# Run a scenario
bash scenarios/stop-db/chaos.sh

# Watch health in another terminal while chaos runs
watch -n1 'curl -s http://localhost:8080/health'

# Watch logs
docker compose logs -f

# After each scenario, fill in the runbook
cp runbooks/incident-template.md runbooks/incident-$(date +%Y%m%d)-stop-db.md
```

## Monitoring during chaos
```bash
# Container stats (CPU, memory, network)
docker stats

# Postgres connections
docker exec lab-postgres psql -U appuser -d appdb \
  -c "SELECT count(*), state FROM pg_stat_activity GROUP BY state;"

# Disk usage
docker exec lab-postgres df -h /
```

## Key things to observe per scenario
- **Kill pods**: How fast does restart happen? How many requests failed?
- **Stop DB**: Does app crash or return graceful 503?
- **Fill disk**: At what % does postgres refuse writes?
- **Break DNS**: Immediate error or timeout? (big operational difference)
- **Add latency**: Does timeout cascade to the API layer? Does circuit breaking help?
